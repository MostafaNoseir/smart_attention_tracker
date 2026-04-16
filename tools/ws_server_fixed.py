#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import asyncio
import os
import websockets
import json
import cv2
import numpy as np
import sys
from pathlib import Path
import io
import tempfile
import time
import math

# Ensure UTF-8 output for PyInstaller bundles
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Allow importing local package when bundled
sys.path.insert(0, str(Path(__file__).parent / "src"))

from eyetrax.gaze import GazeEstimator

class OneEuroFilter:
    def __init__(self, freq=30, mincutoff=1.0, beta=0.007, dcutoff=1.0):
        self.freq = freq
        self.mincutoff = mincutoff
        self.beta = beta
        self.dcutoff = dcutoff
        self._x = None
        self._dx = 0.0

    def _alpha(self, cutoff):
        te = 1.0 / self.freq
        tau = 1.0 / (2 * math.pi * cutoff)
        return 1.0 / (1.0 + tau / te)

    def __call__(self, x):
        if self._x is None:
            self._x = x
            return x
        dx = (x - self._x) * self.freq
        edx = self._alpha(self.dcutoff) * dx + (1 - self._alpha(self.dcutoff)) * self._dx
        self._dx = edx
        cutoff = self.mincutoff + self.beta * abs(edx)
        self._x = self._alpha(cutoff) * x + (1 - self._alpha(cutoff)) * self._x
        return self._x


def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(os.path.dirname(__file__))

    return os.path.join(base_path, relative_path)


class EyeTraxServer:
    def __init__(self):
        self.cap = None
        print("Loading EyeTrax model...")
        local_model_path = resource_path("face_landmarker.task")
        self.estimator = GazeEstimator(model_name="ridge", face_landmarker_model=local_model_path)
        self.calibrated = False
        self.is_running = True
        self.temp_video_path = None
        self.filter_x = OneEuroFilter(freq=30, mincutoff=1.5, beta=0.05)
        self.filter_y = OneEuroFilter(freq=30, mincutoff=1.5, beta=0.05)

    MAX_JUMP = 0.40

    def _is_outlier(self, raw_x, raw_y):
        dx = abs(raw_x - self.filter_x._x) if self.filter_x._x is not None else 0
        dy = abs(raw_y - self.filter_y._x) if self.filter_y._x is not None else 0
        return dx > self.MAX_JUMP or dy > self.MAX_JUMP

    def calibrate(self, points):
        print("Training with 9-point calibration data...")
        X, y = [], []
        for p in points:
            sx, sy = p["screen_x"], p["screen_y"]
            for sample in p.get("gaze_samples", []):
                if features := sample.get("features"):
                    X.append(features)
                    y.append([sx, sy])

        if len(X) < 30:
            print("Not enough samples for reliable calibration!")
            return {"success": False, "message": "calibration_failed", "reason": "insufficient_samples"}

        X_arr = np.array(X)
        y_arr = np.array(y)

        # Train the model
        self.estimator.train(X_arr, y_arr)

        # === QUALITY EVALUATION ===
        predictions = self.estimator.predict(X_arr)
        errors = np.abs(predictions - y_arr)
        mean_error_norm = np.mean(np.sqrt(np.sum(errors**2, axis=1)))
        max_error_norm = np.max(np.sqrt(np.sum(errors**2, axis=1)))

        print("\n" + "="*55)
        print(f"{'Target Dot (X, Y)':<18} | {'Model Thinks (X, Y)':<20} | {'Error'}")
        print("-" * 55)

        unique_targets = np.unique(y_arr, axis=0)
        for tgt in unique_targets:
            mask = (y_arr[:, 0] == tgt[0]) & (y_arr[:, 1] == tgt[1])
            point_preds = predictions[mask]
            avg_pred = np.mean(point_preds, axis=0)
            dist = np.sqrt(np.sum((tgt - avg_pred)**2))
            tgt_str = f"({tgt[0]:.2f}, {tgt[1]:.2f})"
            pred_str = f"({avg_pred[0]:.2f}, {avg_pred[1]:.2f})"
            alert = " (Looked away?)" if dist > 0.15 else " "
            print(f"{tgt_str:<18} | {pred_str:<20} | {dist:.4f}{alert}")

        print("="*55)
        print(f"OVERALL QUALITY  -->  Mean Error: {mean_error_norm:.4f} | Max Error: {max_error_norm:.4f}\n")

        is_good = mean_error_norm < 0.015 and max_error_norm < 0.06

        if is_good:
            print("Calibration quality is GOOD. Passing to Live Session.")
            self.calibrated = True
            self.filter_x = OneEuroFilter(freq=30, mincutoff=1.5, beta=0.05)
            self.filter_y = OneEuroFilter(freq=30, mincutoff=1.5, beta=0.05)
            return {
                "success": True,
                "message": "calibration_done",
                "quality": "good",
                "mean_error": float(mean_error_norm)
            }
        else:
            print("Calibration quality is POOR. Rejecting.")
            self.calibrated = False
            return {
                "success": False,
                "message": "calibration_failed",
                "quality": "poor",
                "mean_error": float(mean_error_norm),
                "reason": "high_error"
            }

    async def send_gaze_data(self, websocket):
        """Capture from camera, write video and stream gaze JSON messages.

        Fix strategy:
        - Measure the actual camera FPS over a short warm-up window.
        - Create the VideoWriter with that measured FPS.
        - While recording, write duplicated frames or drop frames so that
          the number of frames in the file matches real elapsed time * writer_fps.
        This ensures playback duration = wall-clock duration (no "sped-up" video).
        """
        print("Flutter connected → camera + video recording starting...")

        self.temp_video_path = None
        self.is_running = True
        writer = None

        try:
            # Open capture using a suitable backend
            if sys.platform.startswith("win"):
                cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
            else:
                cap = cv2.VideoCapture(0)

            self.cap = cap
            cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
            cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

            # small warm-up (auto-exposure / auto-focus)
            warmup_delay = 0.5
            warmup_start = time.perf_counter()
            while time.perf_counter() - warmup_start < warmup_delay:
                ret, _ = cap.read()
                if not ret:
                    await asyncio.sleep(0.01)
                else:
                    await asyncio.sleep(0)

            # Query resolution
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) or 1280)
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT) or 720)

            # Measure delivered FPS for ~1 second
            measure_seconds = 1.0
            count = 0
            meas_start = time.perf_counter()
            while time.perf_counter() - meas_start < measure_seconds:
                ret, _ = cap.read()
                if ret:
                    count += 1
                else:
                    await asyncio.sleep(0.01)

            measured_fps = (count / measure_seconds) if count > 0 else 20.0
            measured_fps = max(1.0, min(measured_fps, 60.0))
            print(f"Measured camera FPS: {measured_fps:.2f}")

            fourcc = cv2.VideoWriter_fourcc(*'MJPG')
            self.temp_video_path = os.path.join(tempfile.gettempdir(), f"eye_focus_session_{int(time.time())}.avi")
            writer = cv2.VideoWriter(self.temp_video_path, fourcc, measured_fps, (width, height))

            print(f"🎥 Recording started (using writer FPS {measured_fps:.2f}) → {self.temp_video_path}")

            recording_start = time.perf_counter()
            frames_written = 0

            while self.is_running:
                ret, frame = cap.read()
                if not ret:
                    await asyncio.sleep(0.01)
                    continue

                # ensure frame size
                if frame.shape[1] != width or frame.shape[0] != height:
                    frame = cv2.resize(frame, (width, height))

                # Determine how many frames should have been written by now
                now = time.perf_counter()
                desired_total = int((now - recording_start) * measured_fps)

                # Write duplicates (or drop frames) so file frame count matches wall-clock
                if desired_total > frames_written:
                    to_write = desired_total - frames_written
                    # Flip horizontally for saved video so it's not mirrored
                    flipped_frame = cv2.flip(frame, 1)
                    for _ in range(to_write):
                        writer.write(flipped_frame)
                        frames_written += 1

                # Gaze estimation (unchanged behaviour)
                features, blink = self.estimator.extract_features(frame)
                x = y = 0.5
                face_detected = False

                if features is not None:
                    face_detected = True
                    if self.calibrated and not blink:
                        raw_pred = self.estimator.predict([features])[0]
                        raw_x, raw_y = map(float, raw_pred)
                        raw_x = max(0.0, min(1.0, raw_x))
                        raw_y = max(0.0, min(1.0, raw_y))

                        if self.filter_x._x is None:
                            x = self.filter_x(raw_x)
                            y = self.filter_y(raw_y)
                        else:
                            if not self._is_outlier(raw_x, raw_y):
                                x = self.filter_x(raw_x)
                                y = self.filter_y(raw_y)
                            else:
                                x = self.filter_x._x
                                y = self.filter_y._x

                data = {
                    "type": "gaze",
                    "x": x,
                    "y": y,
                    "face_detected": face_detected,
                    "is_blinking": bool(blink),
                    "confidence": 0.95,
                    "features": features.tolist() if features is not None else []
                }

                await websocket.send(json.dumps(data))
                await asyncio.sleep(0)

        except Exception as e:
            print(f"Camera loop error: {e}")
        finally:
            if writer is not None:
                writer.release()
            if self.cap is not None:
                self.cap.release()
            print(f"✅ Video saved → {self.temp_video_path}")
            print("Camera + Video closed.")

    async def handle_commands(self, websocket):
        try:
            async for message in websocket:
                data = json.loads(message)
                if data.get("command") == "calibrate":
                    result = self.calibrate(data.get("points", []))
                    await websocket.send(json.dumps({
                        "type": "status",
                        **result
                    }))
                elif data.get("command") == "stop":
                    self.is_running = False

                    if self.temp_video_path and os.path.exists(self.temp_video_path):
                        await websocket.send(json.dumps({
                            "type": "session_end",
                            "temp_video_path": self.temp_video_path,
                            "success": True
                        }))
                        print(f"📤 Sent session_end with video: {self.temp_video_path}")
                    else:
                        await websocket.send(json.dumps({
                            "type": "session_end",
                            "temp_video_path": None,
                            "success": True
                        }))
                        print("⚠️ No video path to send (or file not found)")
        except websockets.exceptions.ConnectionClosed:
            self.is_running = False
        except Exception as e:
            print(f"Command handler error: {e}")

    async def handler(self, websocket):
        task1 = asyncio.create_task(self.send_gaze_data(websocket))
        task2 = asyncio.create_task(self.handle_commands(websocket))
        await asyncio.gather(task1, task2)


async def main():
    server = EyeTraxServer()
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    async with websockets.serve(server.handler, "127.0.0.1", port, max_size=None):
        print(f"Server ready on port {port}")
        await asyncio.Future()


if __name__ == "__main__":
    asyncio.run(main())

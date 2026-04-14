from __future__ import annotations

from contextlib import contextmanager
import os
import tempfile
import time

import cv2


def open_camera(index: int = 0) -> cv2.VideoCapture:
    """Open a camera by index with fallback."""
    cap = cv2.VideoCapture(index)
    if cap.isOpened():
        return cap

    cap.release()
    if index == 0:
        cap = cv2.VideoCapture(1)
        if cap.isOpened():
            return cap
        cap.release()
        raise RuntimeError("cannot open camera 0 (fallback to camera 1 also failed)")

    raise RuntimeError(f"cannot open camera {index}")


@contextmanager
def fullscreen(name: str):
    """Open a window in full-screen mode"""
    cv2.namedWindow(name, cv2.WND_PROP_FULLSCREEN)
    cv2.setWindowProperty(name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
    try:
        yield
    finally:
        cv2.destroyWindow(name)


@contextmanager
def camera(index: int = 0):
    """Context manager returning an opened VideoCapture"""
    cap = open_camera(index)
    try:
        yield cap
    finally:
        cap.release()


def iter_frames(cap: cv2.VideoCapture):
    """Infinite generator yielding successive frames"""
    while True:
        ok, frame = cap.read()
        if not ok:
            continue
        yield frame


# ─── NEW: تسجيل الفيديو أثناء السيشن ─────────────────────────────
@contextmanager
def record_session(output_path: str | None = None):
    """
    Context manager that opens camera + records video to MP4.
    Yields: (cap, writer)
    """
    if output_path is None:
        output_path = os.path.join(
            tempfile.gettempdir(),
            f"eye_focus_session_{int(time.time())}.mp4"
        )

    cap = open_camera(0)

    # خد الـ fps والـ resolution من الكاميرا
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 640
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 480

    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    writer = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    print(f"🎥 Recording started → {output_path}")

    try:
        yield cap, writer          # ← بنرجع الكاميرا + الـ writer
    finally:
        writer.release()
        cap.release()
        print(f"✅ Video saved → {output_path}")
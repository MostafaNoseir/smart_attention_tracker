
// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:ui';
// import 'package:flutter/foundation.dart';

// class GazeData {
//   final double x;
//   final double y;
//   final double confidence;
//   final bool faceDetected;
//   final double headYaw;
//   final double headPitch;
//   final bool isGlare;

//   GazeData({
//     required this.x,
//     required this.y,
//     required this.confidence,
//     required this.faceDetected,
//     required this.headYaw,
//     required this.headPitch,
//     required this.isGlare,
//   });

//   factory GazeData.fromJson(Map<String, dynamic> json) => GazeData(
//     x: (json['gaze_x'] as num).toDouble(),
//     y: (json['gaze_y'] as num).toDouble(),
//     confidence: (json['confidence'] as num).toDouble(),
//     faceDetected: json['face_detected'] as bool,
//     headYaw: (json['head_yaw'] as num? ?? 0).toDouble(),
//     headPitch: (json['head_pitch'] as num? ?? 0).toDouble(),
//     isGlare: json['is_glare'] as bool? ?? false,
//   );

//   bool get isReliable => faceDetected && confidence > 0.5 && !isGlare;
// }

// class CalibrationPoint {
//   final double screenX;
//   final double screenY;
//   final List<Map<String, double>> gazeSamples;

//   CalibrationPoint({
//     required this.screenX,
//     required this.screenY,
//     required this.gazeSamples,
//   });

//   Map<String, dynamic> toJson() => {
//     'screen_x': screenX,
//     'screen_y': screenY,
//     'gaze_samples': gazeSamples,
//   };
// }

// class ModelBridge {
//   Process? _process;
//   StreamController<GazeData>? _ctrl;
//   StreamSubscription? _stdoutSub;
//   StreamSubscription? _stderrSub;
//   bool _isRunning = false;
//   Stream<GazeData>? get gazeStream => _ctrl?.stream;

//   final _statusController = StreamController<String>.broadcast();
//   Stream<String> get statusStream => _statusController.stream;

//   bool get isRunning => _isRunning;

//   // ── الـ path الصح للـ exe جنب الـ Flutter app ──────────────────
//   static String get _modelExe {
//     // الـ exe بيتحط جنب flutter app مباشرةً مش جوا assets
//     final exeDir = File(Platform.resolvedExecutable).parent.path;
//     if (Platform.isWindows) {
//       return '$exeDir\\data\\flutter_assets\\assets\\model\\eye_tracker.exe';
//     }
//     if (Platform.isMacOS) {
//       return '$exeDir/../Resources/flutter_assets/assets/model/eye_tracker_mac';
//     }
//     return '$exeDir/data/flutter_assets/assets/model/eye_tracker_linux';
//   }

//   Future<Stream<GazeData>> start({
//     int cameraIndex = 0,
//     bool wearsGlasses = false,
//     List<CalibrationPoint>? calibrationPoints,
//     Size? screenSize,
//   }) async {
//     if (_isRunning) await stop();
//     _ctrl = StreamController<GazeData>.broadcast();

//     // أبعاد الشاشة
//     final sw = screenSize?.width.toInt() ?? 1920;
//     final sh = screenSize?.height.toInt() ?? 1080;
//     final glasses = wearsGlasses ? '1' : '0';

//     debugPrint('[ModelBridge] Starting exe: $_modelExe');
//     debugPrint('[ModelBridge] Args: $sw $sh $cameraIndex $glasses');

//     try {
//       _process = await Process.start(
//         _modelExe,
//         // positional args: screen_width screen_height camera_index glasses_mode
//         ['$sw', '$sh', '$cameraIndex', glasses],
//         runInShell: false,
//       );
//       _isRunning = true;

//       // ابعت calibration لو موجودة
//       if (calibrationPoints != null && calibrationPoints.isNotEmpty) {
//         _sendRaw(
//           jsonEncode({
//             'command': 'calibrate',
//             'points': calibrationPoints.map((p) => p.toJson()).toList(),
//           }),
//         );
//       }

//       // استمع للـ stdout
//       _stdoutSub = _process!.stdout
//           .transform(utf8.decoder)
//           .transform(const LineSplitter())
//           .listen((line) {
//             if (line.trim().isEmpty) return;
//             try {
//               final data = jsonDecode(line) as Map<String, dynamic>;
//               // if (data.containsKey('gaze_x')) {
//               //   _ctrl?.add(GazeData.fromJson(data));
//               // } else if (data['type'] == 'status') {
//               //   // ── أضف السطر ده ──
//               //   _statusController.add(data['message'] ?? '');
//               //   debugPrint('[Model] ${data['message']}');
//               // }
//               if (data.containsKey('gaze_x')) {
//                 _ctrl?.add(GazeData.fromJson(data));
//               } else if (data['type'] == 'status' || data['type'] == 'error') {
//                 // ضفنا data['type'] == 'error' عشان نسمع لو المعايرة فشلت
//                 _statusController.add(data['message'] ?? '');
//                 debugPrint('[Model] ${data['message']}');
//               }
//             } catch (_) {
//               debugPrint('[ModelBridge] parse error: $line');
//             }
//           });
//       // .listen(
//       //   (line) {
//       //     if (line.trim().isEmpty) return;
//       //     try {
//       //       final data = jsonDecode(line) as Map<String, dynamic>;
//       //       if (data.containsKey('gaze_x')) {
//       //         _ctrl?.add(GazeData.fromJson(data));
//       //       } else {
//       //         debugPrint('[Model] ${data['message'] ?? line}');
//       //       }
//       //     } catch (_) {
//       //       debugPrint('[ModelBridge] parse error: $line');
//       //     }
//       //   },
//       //   onDone: () {
//       //     debugPrint('[ModelBridge] process ended');
//       //     _isRunning = false;
//       //     _ctrl?.close();
//       //   },
//       //   onError: (e) => debugPrint('[ModelBridge] stdout error: $e'),
//       // );

//       // log الـ stderr
//       _stderrSub = _process!.stderr
//           .transform(utf8.decoder)
//           .listen((d) => debugPrint('[Model stderr] $d'));

//       return _ctrl!.stream;
//     } catch (e) {
//       _isRunning = false;
//       debugPrint('[ModelBridge] Failed to start: $e');
//       debugPrint('[ModelBridge] Exe path was: $_modelExe');
//       throw Exception('Failed to start eye tracking model: $e');
//     }
//   }

//   void _sendRaw(String line) {
//     try {
//       _process?.stdin.writeln(line);
//     } catch (e) {
//       debugPrint('[ModelBridge] send error: $e');
//     }
//   }

//   void sendCommand(Map<String, dynamic> cmd) {
//     if (_isRunning) _sendRaw(jsonEncode(cmd));
//   }

//   void pause() => sendCommand({'command': 'pause'});
//   void resume() => sendCommand({'command': 'resume'});

//   Future<void> stop() async {
//     if (!_isRunning) return;
//     sendCommand({'command': 'quit'});
//     await Future.delayed(const Duration(milliseconds: 500));
//     _process?.kill();
//     await _stdoutSub?.cancel();
//     await _stderrSub?.cancel();
//     await _ctrl?.close();
//     _process = null;
//     _isRunning = false;
//   }

//   void dispose() => stop();
// }

// // ── Mock bridge للـ development ──────────────────────────────────
// class MockModelBridge extends ModelBridge {
//   Timer? _timer;
//   double _x = 0.5, _y = 0.5;
//   final _rand = Random();

//   @override
//   Future<Stream<GazeData>> start({
//     int cameraIndex = 0,
//     bool wearsGlasses = false,
//     List<CalibrationPoint>? calibrationPoints,
//     Size? screenSize,
//   }) async {
//     _ctrl = StreamController<GazeData>.broadcast();
//     _isRunning = true;

//     _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
//       _x = (_x + (_rand.nextDouble() - 0.5) * 0.025).clamp(0.05, 0.95);
//       _y = (_y + (_rand.nextDouble() - 0.5) * 0.025).clamp(0.05, 0.95);
//       _ctrl?.add(
//         GazeData(
//           x: _x,
//           y: _y,
//           confidence: 0.82 + _rand.nextDouble() * 0.18,
//           faceDetected: true,
//           headYaw: (_rand.nextDouble() - 0.5) * 12,
//           headPitch: (_rand.nextDouble() - 0.5) * 8,
//           isGlare: false,
//         ),
//       );
//     });

//     return _ctrl!.stream;
//   }

//   @override
//   Future<void> stop() async {
//     _timer?.cancel();
//     await _ctrl?.close();
//     _isRunning = false;CalibrationPoint
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class GazeData {
//   final double x;
//   final double y;
//   final bool faceDetected;
//   final double confidence;
//   final bool isReliable;
//   final bool isGlare;
//   final List<double> features;

//   GazeData({
//     required this.x,
//     required this.y,
//     required this.faceDetected,
//     required this.confidence,
//     this.isReliable = true,
//     this.isGlare = false,
//     required this.features,
//   });

//   factory GazeData.fromJson(Map<String, dynamic> json) {
//     return GazeData(
//       x: (json['x'] ?? 0.5).toDouble(),
//       y: (json['y'] ?? 0.5).toDouble(),
//       faceDetected: json['face_detected'] ?? false,
//       confidence: (json['confidence'] ?? 0.0).toDouble(),
//       isReliable: json['is_reliable'] ?? true,
//       isGlare: json['is_glare'] ?? false,
//       features: json['features'] != null 
//           ? (json['features'] as List).map((e) => (e as num).toDouble()).toList() 
//           : [],
//     );
//   }
// }

// class ModelBridge {
//   WebSocketChannel? _channel;
  
//   final _gazeController = StreamController<GazeData>.broadcast();
//   final _statusController = StreamController<String>.broadcast();

//   Stream<GazeData>? get gazeStream => _gazeController.stream;
//   Stream<String> get statusStream => _statusController.stream;

//   bool _isPaused = false;
  

//   Future<Stream<GazeData>> start({
//     required int cameraIndex,
//     required bool wearsGlasses,
//     required Size screenSize,
//   }) async {
//     try {
//       final wsUrl = Uri.parse('ws://127.0.0.1:8765');
//       _channel = WebSocketChannel.connect(wsUrl);

//       _channel!.stream.listen(
//         (message) {
//           if (_isPaused) return;
//           try {
//             final data = jsonDecode(message);
//             if (data['type'] == 'gaze') {
//               _gazeController.add(GazeData.fromJson(data));
//             } else if (data['type'] == 'status') {
//               _statusController.add(data['message']);
//             }
//           } catch (e) {
//             debugPrint('[ModelBridge] Error parsing JSON: $e');
//           }
//         },
//         onError: (error) => debugPrint('[ModelBridge] WS Error: $error'),
//         onDone: () => debugPrint('[ModelBridge] WS Disconnected'),
//       );

//       debugPrint('[ModelBridge] Connected to WebSocket successfully');
//       return _gazeController.stream;
//     } catch (e) {
//       debugPrint('[ModelBridge] Failed to connect: $e');
//       throw Exception('Could not connect to eye tracking server');
//     }
//   }

//   void sendCommand(Map<String, dynamic> command) {
//     if (_channel != null) {
//       _channel!.sink.add(jsonEncode(command));
//       debugPrint('[ModelBridge] Command sent: ${command['command']}');
//     }
//   }

//   void pause() => _isPaused = true;
//   void resume() => _isPaused = false;

//   Future<void> stop() async {
//     sendCommand({'command': 'stop'});
//     await _channel?.sink.close();
//     _channel = null;
//   }

//   void dispose() {
//     stop();
//     _gazeController.close();
//     _statusController.close();
//   }
// }


// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class GazeData {
//   final double x;
//   final double y;
//   final bool faceDetected;
//   final double confidence;
//   final bool isReliable;
//   final bool isGlare;
//   final bool isBlinking;
//   final List<double> features;

//   GazeData({
//     required this.x,
//     required this.y,
//     required this.faceDetected,
//     required this.confidence,
//     this.isReliable = true,
//     this.isGlare = false,
//     this.isBlinking = false,
//     required this.features,
//   });

//   factory GazeData.fromJson(Map<String, dynamic> json) {
//     return GazeData(
//       x: (json['x'] ?? 0.5).toDouble(),
//       y: (json['y'] ?? 0.5).toDouble(),
//       faceDetected: json['face_detected'] ?? false,
//       confidence: (json['confidence'] ?? 0.0).toDouble(),
//       isReliable: json['is_reliable'] ?? true,
//       isGlare: json['is_glare'] ?? false,
//       isBlinking: json['is_blinking'] ?? false,
//       features: json['features'] != null 
//           ? (json['features'] as List).map((e) => (e as num).toDouble()).toList() 
//           : [],
//     );
//   }
// }

// class ModelBridge {
//   WebSocketChannel? _channel;
  
//   final _gazeController = StreamController<GazeData>.broadcast();
//   // final _statusController = StreamController<String>.broadcast();
//   final _statusController = StreamController<Map<String, dynamic>>.broadcast();

//   Stream<GazeData>? get gazeStream => _gazeController.stream;
//   // Stream<String> get statusStream => _statusController.stream;
//   Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

//   bool _isPaused = false;
//   bool _isDisposed = false; // 🚨 عشان نوقف المحاولات لو اليوزر قفل الشاشة

//   Future<Stream<GazeData>> start({
//     required int cameraIndex,
//     required bool wearsGlasses,
//     required Size screenSize,
//   }) async {
//     _isDisposed = false;
//     _connectWebSocket(); // 🚨 بداية محاولات الاتصال
//     return _gazeController.stream;
//   }

//   // 🚨 دالة الاتصال الذكية اللي مش بتستسلم
//   void _connectWebSocket() {
//     if (_isDisposed) return;
    
//     try {
//       final wsUrl = Uri.parse('ws://127.0.0.1:8765');
//       _channel = WebSocketChannel.connect(wsUrl);

//       _channel!.stream.listen(
//         (message) {
//           if (_isPaused) return;
//           try {
//             final data = jsonDecode(message);
//             if (data['type'] == 'gaze') {
//               _gazeController.add(GazeData.fromJson(data));
//             } else if (data['type'] == 'status') {
//               // _statusController.add(data['message']);
//               _statusController.add(data);
//             }
//           } catch (e) {
//             debugPrint('[ModelBridge] Error parsing JSON: $e');
//           }
//         },
//         onError: (error) {
//           debugPrint('[ModelBridge] WS Error: $error. Retrying in 2 seconds...');
//           _reconnect(); // 🚨 لو حصل إيرور، حاول تاني
//         },
//         onDone: () {
//           debugPrint('[ModelBridge] WS Disconnected. Retrying in 2 seconds...');
//           _reconnect(); // 🚨 لو السيرفر قفل، حاول تاني
//         },
//       );

//       debugPrint('[ModelBridge] Connected to WebSocket successfully');
      
//     } catch (e) {
//       debugPrint('[ModelBridge] Failed to connect: $e. Retrying in 2 seconds...');
//       _reconnect(); // 🚨 لو فشل خالص، حاول تاني
//     }
//   }

//   // 🚨 دالة إعادة المحاولة كل ثانيتين
//   void _reconnect() {
//     if (_isDisposed) return;
//     _channel?.sink.close();
//     Future.delayed(const Duration(seconds: 2), () {
//       if (!_isDisposed) {
//         _connectWebSocket();
//       }
//     });
//   }

//   void sendCommand(Map<String, dynamic> command) {
//     if (_channel != null) {
//       _channel!.sink.add(jsonEncode(command));
//       debugPrint('[ModelBridge] Command sent: ${command['command']}');
//     }
//   }

//   void pause() => _isPaused = true;
//   void resume() => _isPaused = false;

//   Future<void> stop() async {
//     _isDisposed = true; // 🚨 نوقف محاولات الاتصال نهائياً
//     sendCommand({'command': 'stop'});
//     await _channel?.sink.close();
//     _channel = null;
//   }

//   void dispose() {
//     _isDisposed = true;
//     stop();
//     _gazeController.close();
//     _statusController.close();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

class GazeData {
  final double x;
  final double y;
  final bool faceDetected;
  final double confidence;
  final bool isReliable;
  final bool isGlare;
  final bool isBlinking;
  final List<double> features;

  GazeData({
    required this.x,
    required this.y,
    required this.faceDetected,
    required this.confidence,
    this.isReliable = true,
    this.isGlare = false,
    this.isBlinking = false,
    required this.features,
  });

  factory GazeData.fromJson(Map<String, dynamic> json) {
    return GazeData(
      x: (json['x'] ?? 0.5).toDouble(),
      y: (json['y'] ?? 0.5).toDouble(),
      faceDetected: json['face_detected'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      isReliable: json['is_reliable'] ?? true,
      isGlare: json['is_glare'] ?? false,
      isBlinking: json['is_blinking'] ?? false,
      features: json['features'] != null 
          ? (json['features'] as List).map((e) => (e as num).toDouble()).toList() 
          : [],
    );
  }
}
class ModelBridge {
  WebSocketChannel? _channel;
  Process? _serverProcess; 
  int? _activePort;
  
  final _gazeController = StreamController<GazeData>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<GazeData>? get gazeStream => _gazeController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  bool _isPaused = false;
  bool _isDisposed = false;
  
  // 🚨 New safety locks
  bool _isReconnecting = false;
  bool _isConnected = false;

  Future<Stream<GazeData>> start({
    required int cameraIndex,
    required bool wearsGlasses,
    required Size screenSize,
  }) async {
    _isDisposed = false;
    _isConnected = false;
    _isReconnecting = false;
    
    await _startPythonServer(); 
    _connectWebSocket(); 
    return _gazeController.stream;
  }

  Future<void> _startPythonServer() async {
  if (_serverProcess != null) return; 

  try {
    final serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _activePort = serverSocket.port;
    await serverSocket.close();

    // 🚨 Updated Path to look inside the subfolder
    final appDir = Directory.current.path;
    final exePath = p.join(appDir, 'data', 'eyetrax_server', 'eyetrax_server.exe');

    debugPrint('[ModelBridge] Target EXE: $exePath');

    if (!File(exePath).existsSync()) {
       debugPrint('[ModelBridge] ❌ CANNOT FIND EXE at $exePath');
       return;
    }

    _serverProcess = await Process.start(
      exePath,
      [_activePort.toString()],
      workingDirectory: p.dirname(exePath),
    );
    
    // Listen for any immediate startup errors from the console
    _serverProcess!.stderr.transform(utf8.decoder).listen((data) => debugPrint('[Python Error] $data'));
    _serverProcess!.stdout.transform(utf8.decoder).listen((data) => debugPrint('[Python Output] $data'));

    await Future.delayed(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('[ModelBridge] Start error: $e');
  }
}

  void _connectWebSocket() {
    if (_isDisposed || _activePort == null) return;
    
    try {
      debugPrint('[ModelBridge] Attempting connection...');
      final wsUrl = Uri.parse('ws://127.0.0.1:$_activePort');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          // 🚨 We only say we are connected if we actually receive data!
          if (!_isConnected) {
            _isConnected = true;
            debugPrint('[ModelBridge] ✅ Link Established! Receiving camera data.');
          }
          
          if (_isPaused) return;
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'gaze') {
              _gazeController.add(GazeData.fromJson(data));
            } else if (data['type'] == 'status') {
              _statusController.add(data); 
            }
          } catch (e) {
            debugPrint('[ModelBridge] Error parsing JSON: $e');
          }
        },
        onError: (error) {
          _reconnect();
        },
        onDone: () {
          _reconnect();
        },
        cancelOnError: true, // 🚨 Prevents onError and onDone from firing at the same time
      );
      
    } catch (e) {
      _reconnect();
    }
  }

  void _reconnect() {
    // 🚨 The lock prevents the "fork bomb" of multiple retry loops
    if (_isDisposed || _isReconnecting) return;
    
    _isReconnecting = true;
    _isConnected = false;
    
    _channel?.sink.close();
    _channel = null;

    debugPrint('[ModelBridge] Server not ready yet. Retrying in 3 seconds...');
    
    Future.delayed(const Duration(seconds: 3), () {
      _isReconnecting = false;
      if (!_isDisposed) {
        _connectWebSocket();
      }
    });
  }

  void sendCommand(Map<String, dynamic> command) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(command));
      debugPrint('[ModelBridge] Command sent: ${command['command']}');
    }
  }

  void pause() => _isPaused = true;
  void resume() => _isPaused = false;

  Future<void> stop() async {
    // Idempotent shutdown
    if (_isDisposed) {
      debugPrint('[ModelBridge] stop() called but already disposed.');
      return;
    }
    _isDisposed = true;

    // Stop reconnect attempts
    _isReconnecting = false;
    _isConnected = false;

    // Ask the server to stop politely (best-effort)
    try {
      sendCommand({'command': 'stop'});
    } catch (e) {
      debugPrint('[ModelBridge] send stop command failed: $e');
    }

    // Close websocket channel
    try {
      await _channel?.sink.close();
    } catch (e) {
      debugPrint('[ModelBridge] Error closing WS sink: $e');
    }
    _channel = null;

    // If there is a spawned server process, try graceful exit then force-kill
    if (_serverProcess != null) {
      final proc = _serverProcess!;
      int? exitCode;
      try {
        // Try polite termination first
        try {
          proc.kill(ProcessSignal.sigterm);
        } catch (e) {
          debugPrint('[ModelBridge] sigterm failed (platform?): $e');
          try {
            proc.kill();
          } catch (_) {}
        }

        // Wait up to 5s for process to exit
        try {
          exitCode = await proc.exitCode.timeout(const Duration(seconds: 5));
          debugPrint('[ModelBridge] Python server exited with code $exitCode');
        } catch (e) {
          debugPrint('[ModelBridge] Process did not exit in time: $e — attempting force kill');
          try {
            proc.kill(ProcessSignal.sigkill);
          } catch (e2) {
            debugPrint('[ModelBridge] Force-kill failed: $e2');
          }
          try {
            exitCode = await proc.exitCode.timeout(const Duration(seconds: 2));
            debugPrint('[ModelBridge] Python server force-exited with code $exitCode');
          } catch (_) {
            debugPrint('[ModelBridge] Force-exit wait timed out');
          }
        }
      } catch (e) {
        debugPrint('[ModelBridge] Error while stopping server process: $e');
      } finally {
        _serverProcess = null;
      }
    }

    debugPrint('[ModelBridge] Stopped Python server process.');
  }

  void dispose() {
    _isDisposed = true;
    stop();
    _gazeController.close();
    _statusController.close();
  }
}
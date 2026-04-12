// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import '../../theme/app_theme.dart';
// import '../../models/models.dart';
// import '../../services/firestore_service.dart';
// import '../../services/model_bridge.dart';
// import 'package:audioplayers/audioplayers.dart';

// class LiveSessionScreen extends StatefulWidget {
//   final ChildProfile child;
//   final SessionConfig config;
//   final ModelBridge? bridge;

//   const LiveSessionScreen({
//     super.key,
//     required this.child,
//     required this.config,
//     this.bridge,
//   });

//   @override
//   State<LiveSessionScreen> createState() => _LiveSessionScreenState();
// }

// class _LiveSessionScreenState extends State<LiveSessionScreen>
//     with TickerProviderStateMixin {

//   // ── Model bridge ──────────────────────────────────────────────
//   late final ModelBridge _bridge;
//   StreamSubscription<GazeData>? _gazeSub;
//   GazeData? _latestGaze;
//   bool _bridgeStarted = false;
//   // ── Audio Player ──────────────────────────────────────────────
//   final AudioPlayer _audioPlayer = AudioPlayer();

//   // ── Target animation (Python Logic) ──────────────────────────
//   Offset _targetPos = const Offset(0.395, 0.384);
//   final _rand = Random();

//   double _targetX = 0.395;
//   double _targetY = 0.384;
//   String _currentDirection = 'RIGHT';
//   Timer? _changeDirTimer;

//   // حدود الحركة (هوامش صاحبك)
//   // final double _minX = 0.156;
//   // final double _maxX = 0.635;
//   // final double _minY = 0.185;
//   // final double _maxY = 0.583;

//   // حدود الحركة (مطابقة لهوامش صاحبك بالمللي)
//   final double _minX = 0.156;
//   final double _maxX = 0.740;
//   final double _minY = 0.231;
//   final double _maxY = 0.676;

//   // السرعة
//   late final double _speedX;
//   late final double _speedY;

//   // ── Session state ─────────────────────────────────────────────
//   late Timer _sessionTimer;
//   late Timer _loggingTimer;
//   int _elapsedSeconds = 0;
//   int get _totalSeconds => widget.config.duration.seconds;
//   bool _isRunning = true;
//   bool _isPaused = false;

//   // ── Distractor (Python Logic) ─────────────────────────────────
//   bool _distractorActive = false;
//   int _distractorFrames = 0;
//   double _distractorX = 0;
//   double _distractorY = 0;

//   // ── Data collection ───────────────────────────────────────────
//   final List<GazePoint> _gazePoints = [];
//   late DateTime _sessionStart;

//   @override
//   void initState() {
//     super.initState();
//     _bridge = widget.bridge ?? ModelBridge();
//     _sessionStart = DateTime.now();

//     // ضبط السرعة بناءً على اختيار الدكتور في الإعدادات
//     double speedMultiplier = widget.config.speed.pixelsPerSecond / 160.0;
//     _speedX = (12.0 * speedMultiplier) / 1920.0;
//     _speedY = (12.0 * speedMultiplier) / 1080.0;

//     _startTimers();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_bridgeStarted) {
//       _bridgeStarted = true;
//       if (widget.bridge == null) {
//         _startModelBridge();
//       } else {
//         _subscribeToExistingBridge();
//       }
//     }
//   }

//   // Future<void> _subscribeToExistingBridge() async {
//   //   try {
//   //     _gazeSub = _bridge.gazeStream?.listen((gaze) {
//   //       if (!mounted) return;
//   //       setState(() => _latestGaze = gaze);
//   //     });
//   //   } catch (e) {
//   //     debugPrint('[LiveSession] subscribe error: $e');
//   //   }
//   // }

//   Future<void> _subscribeToExistingBridge() async {
//   try {
//     // جرب الـ gazeStream الأول
//     final stream = _bridge.gazeStream;
//     if (stream != null) {
//       _gazeSub = stream.listen((gaze) {
//         if (!mounted) return;
//         setState(() => _latestGaze = gaze);
//         debugPrint('[LiveSession] gaze received: ${gaze.x}, ${gaze.y}'); // ← أضف ده
//       });
//       debugPrint('[LiveSession] subscribed to existing bridge stream');
//     } else {
//       debugPrint('[LiveSession] gazeStream is NULL — starting new bridge');
//       await _startModelBridge();
//     }
//   } catch (e) {
//     debugPrint('[LiveSession] subscribe error: $e');
//   }
// }

//   Future<void> _startModelBridge() async {
//     try {
//       final stream = await _bridge.start(
//         cameraIndex: 0,
//         wearsGlasses: widget.child.wearsGlasses,
//         screenSize: MediaQuery.of(context).size,
//       );
//       _gazeSub = stream.listen((gaze) {
//         if (!mounted) return;
//         setState(() => _latestGaze = gaze);
//       }, onError: (e) {
//         debugPrint('[LiveSession] Model error: $e');
//       });
//     } catch (e) {
//       debugPrint('[LiveSession] Could not start model: $e');
//     }
//   }

//   // ── Timers (Logic) ────────────────────────────────────────────
//   void _startTimers() async {

//     if (widget.config.musicPath != null) {
//       await _audioPlayer.setReleaseMode(ReleaseMode.loop); // عشان الأغنية تعيد نفسها لو خلصت
//       await _audioPlayer.play(DeviceFileSource(widget.config.musicPath!));
//     }
//     // 1. تايمر الثواني
//     _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_isPaused || !_isRunning) return;
//       setState(() => _elapsedSeconds++);
//       if (_elapsedSeconds >= _totalSeconds) _endSession();
//     });

//     // 2. تايمر تغيير الاتجاه كل 7 ثواني
//     _changeDirTimer = Timer.periodic(const Duration(seconds: 7), (_) {
//       if (_isPaused || !_isRunning) return;
//       _currentDirection = ['UP', 'DOWN', 'LEFT', 'RIGHT'][_rand.nextInt(4)];
//     });

//     // 3. تايمر اللعبة السريع (30 فريم في الثانية)
//     _loggingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
//       if (_isPaused || !_isRunning) return;

//       setState(() {
//         // --- حركة الهدف ---
//         if (_currentDirection == 'RIGHT') {
//           _targetX += _speedX;
//           if (_targetX >= _maxX) {
//             _targetX = _maxX;
//             _currentDirection = ['LEFT', 'UP', 'DOWN'][_rand.nextInt(3)];
//           }
//         } else if (_currentDirection == 'LEFT') {
//           _targetX -= _speedX;
//           if (_targetX <= _minX) {
//             _targetX = _minX;
//             _currentDirection = ['RIGHT', 'UP', 'DOWN'][_rand.nextInt(3)];
//           }
//         } else if (_currentDirection == 'DOWN') {
//           _targetY += _speedY;
//           if (_targetY >= _maxY) {
//             _targetY = _maxY;
//             _currentDirection = ['UP', 'LEFT', 'RIGHT'][_rand.nextInt(3)];
//           }
//         } else if (_currentDirection == 'UP') {
//           _targetY -= _speedY;
//           if (_targetY <= _minY) {
//             _targetY = _minY;
//             _currentDirection = ['DOWN', 'LEFT', 'RIGHT'][_rand.nextInt(3)];
//           }
//         }
//         _targetPos = Offset(_targetX, _targetY);

//         // --- المشتتات 1% عشوائي ---
//         if (!_distractorActive && _rand.nextDouble() < 0.01) {
//           _distractorActive = true;
//           _distractorFrames = 0;
//           _distractorX = _minX + _rand.nextDouble() * (_maxX - _minX);
//           _distractorY = _minY + _rand.nextDouble() * (_maxY - _minY);
//         }
//         if (_distractorActive) {
//           _distractorFrames++;
//           if (_distractorFrames > 45) _distractorActive = false; // اختفاء بعد 1.5 ثانية
//         }
//       });

//       _recordGazePoint();
//     });
//   }

//   // void _recordGazePoint() {
//   //   final gaze = _latestGaze;
//   //   final size = MediaQuery.of(context).size;

//   //   final gazeX = (gaze?.isReliable == true) ? gaze!.x * size.width  : -1;
//   //   final gazeY = (gaze?.isReliable == true) ? gaze!.y * size.height : -1;

//   //   final currentMs = DateTime.now().difference(_sessionStart).inMilliseconds;

//   //   _gazePoints.add(GazePoint(
//   //     x: gazeX.toDouble(),
//   //     y: gazeY.toDouble(),
//   //     targetX: _targetPos.dx * size.width,
//   //     targetY: _targetPos.dy * size.height,
//   //     isDistractorActive: _distractorActive,
//   //     timestampMs: currentMs,
//   //   ));
//   // }

// void _recordGazePoint() {
//   final gaze = _latestGaze;
//   final size = MediaQuery.of(context).size;

//   // لو الوش موجود قدام الكاميرا، استخدم الإحداثيات الحقيقية من الـ model
//   final bool isValid = gaze != null && gaze.faceDetected;

//   final gazeX = isValid ? gaze.x * size.width  : -1.0;
//   final gazeY = isValid ? gaze.y * size.height : -1.0;

//   _gazePoints.add(GazePoint(
//     x: gazeX,
//     y: gazeY,
//     targetX: _targetPos.dx * size.width,
//     targetY: _targetPos.dy * size.height,
//     isDistractorActive: _distractorActive,
//     timestampMs: DateTime.now().difference(_sessionStart).inMilliseconds,
//     screenWidth: size.width,
//     screenHeight: size.height,
//   ));
// }

//   // ── End session ───────────────────────────────────────────────
//   Future<void> _endSession() async {
//     if (!_isRunning) return;
//     _isRunning = false;
//     _sessionTimer.cancel();
//     _changeDirTimer?.cancel();
//     _loggingTimer.cancel();
//     await _bridge.stop();
//     await _audioPlayer.stop();
//     await _audioPlayer.dispose();

//     final result = SessionResult(
//       id: '',
//       childId: widget.child.id,
//       childName: widget.child.name,
//       config: widget.config,
//       startTime: _sessionStart,
//       endTime: DateTime.now(),
//       gazePoints: _gazePoints,
//       attentionTimeline: _buildTimeline(),
//     );

//     final service = FirestoreService();
//     final id = await service.saveSession(result);

//     if (mounted) {
//       context.pushReplacement('/results/$id', extra: SessionResult(
//         id: id, childId: result.childId, childName: result.childName,
//         config: result.config, startTime: result.startTime, endTime: result.endTime,
//         gazePoints: result.gazePoints, attentionTimeline: result.attentionTimeline,
//       ));
//     }
//   }

//   // List<AttentionSpan> _buildTimeline() {
//   //   if (_gazePoints.isEmpty) return [];
//   //   final spans = <AttentionSpan>[];
//   //   int spanStart = 0;
//   //   bool lastFocused = _gazePoints.first.isOnTarget;

//   //   for (int i = 1; i < _gazePoints.length; i++) {
//   //     if (_gazePoints[i].isOnTarget != lastFocused) {
//   //       spans.add(AttentionSpan(
//   //         startMs: spanStart * 1000,
//   //         endMs: i * 1000,
//   //         isFocused: lastFocused,
//   //         hasDistractor: _gazePoints.sublist(spanStart, i).any((p) => p.isDistractorActive),
//   //       ));
//   //       spanStart = i;
//   //       lastFocused = _gazePoints[i].isOnTarget;
//   //     }
//   //   }
//   //   spans.add(AttentionSpan(
//   //     startMs: spanStart * 1000,
//   //     endMs: _gazePoints.length * 1000,
//   //     isFocused: lastFocused,
//   //     hasDistractor: _gazePoints.sublist(spanStart).any((p) => p.isDistractorActive),
//   //   ));
//   //   return spans;
//   // }

//  List<AttentionSpan> _buildTimeline() {
//     if (_gazePoints.isEmpty) return [];
//     final spans = <AttentionSpan>[];
//     int spanStart = 0;
//     bool lastFocused = _gazePoints.first.isOnTarget;

//     for (int i = 1; i < _gazePoints.length; i++) {
//       if (_gazePoints[i].isOnTarget != lastFocused) {
//         spans.add(AttentionSpan(
//           // الحسبة بقت بالمللي ثانية الفعلية من نقطة الجاز
//           startMs: _gazePoints[spanStart].timestampMs,
//           endMs: _gazePoints[i].timestampMs,
//           isFocused: lastFocused,
//           hasDistractor: _gazePoints.sublist(spanStart, i).any((p) => p.isDistractorActive),
//         ));
//         spanStart = i;
//         lastFocused = _gazePoints[i].isOnTarget;
//       }
//     }
//     // إضافة آخر Span لحد نهاية الجلسة الفعلية
//     spans.add(AttentionSpan(
//       startMs: _gazePoints[spanStart].timestampMs,
//       endMs: _totalSeconds * 1000, // ← التعديل هنا: استخدمنا _totalSeconds
//       isFocused: lastFocused,
//       hasDistractor: _gazePoints.sublist(spanStart).any((p) => p.isDistractorActive),
//     ));
//     return spans;
//   }

//   // ── Build ─────────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final targetColor = AppColors.targetColors[widget.config.targetColorIndex];
//     final remaining = _totalSeconds - _elapsedSeconds;
//     final progress = _elapsedSeconds / _totalSeconds;

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [

//           // ── Distractor (Red Square) ──────────────────────────────
//           if (_distractorActive)
//             Positioned(
//               left: _distractorX * size.width,
//               top: _distractorY * size.height,
//               child: Container(
//                 width: 60, height: 60,
//                 color: const Color.fromARGB(255, 255, 50, 50),
//               ),
//             ),

//           // ── Moving target ──────────────────────────────────
//           Positioned(
//             left: (_targetPos.dx * size.width - 40).clamp(0, size.width - 80),
//             top: (_targetPos.dy * size.height - 40).clamp(0, size.height - 80),
//             child: _buildTarget(targetColor),
//           ),

//           // ── Gaze cursor (White Dot) ────────────────────────
//           if (_latestGaze != null && _latestGaze!.faceDetected)
//             Positioned(
//               left: (_latestGaze!.x * size.width) - 15,
//               top: (_latestGaze!.y * size.height) - 15,
//               child: Container(
//                 width: 30, height: 30,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: _latestGaze!.isReliable ? Colors.white : Colors.orangeAccent,
//                     width: 3,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.2),
//                       blurRadius: 4, spreadRadius: 1
//                     )
//                   ]
//                 ),
//                 child: Center(
//                   child: Container(
//                     width: 6, height: 6,
//                     decoration: const BoxDecoration(
//                       color: Colors.white,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // ── Webcam overlay ──────────────────────────────────
//           Positioned(
//             bottom: 16,
//             right: 16,
//             child: _WebcamOverlay(gaze: _latestGaze),
//           ),

//           // ── HUD bar ─────────────────────────────────────────
//           Positioned(
//             top: 12,
//             left: 0,
//             right: 0,
//             child: _HUDBar(
//               remaining: remaining,
//               progress: progress,
//               isPaused: _isPaused,
//               onPause: () {
//                 setState(() => _isPaused = !_isPaused);
//                if (_isPaused) {
//                   _bridge.pause();
//                   _audioPlayer.pause(); // نوقف الأغنية
//                 } else {
//                   _bridge.resume();
//                   if (widget.config.musicPath != null) _audioPlayer.resume(); // نكمل الأغنية
//                 }
//               },
//               onStop: _endSession,
//             ),
//           ),

//           // ── Distractor badge (Warning Top Right) ─────────────
//           if (_distractorActive)
//             Positioned(
//               top: 64,
//               right: 16,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: AppColors.warningDim,
//                   borderRadius: BorderRadius.circular(50),
//                   border: Border.all(color: AppColors.warning.withOpacity(0.5)),
//                 ),
//                 child: const Row(mainAxisSize: MainAxisSize.min, children: [
//                   Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 14),
//                   SizedBox(width: 6),
//                   Text('Distractor', style: TextStyle(
//                     color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600)),
//                 ]),
//               ).animate().fadeIn(duration: 80.ms).then(delay: 1600.ms).fadeOut(),
//             ),

//           // ── Paused overlay ─────────────────────────────────
//           if (_isPaused)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black.withOpacity(0.7),
//                 child: const Center(
//                   child: Column(mainAxisSize: MainAxisSize.min, children: [
//                     Icon(Icons.pause_circle_outline_rounded,
//                       color: AppColors.primary, size: 64),
//                     SizedBox(height: 16),
//                     Text('Session paused',
//                       style: TextStyle(color: AppColors.textPrimary,
//                         fontSize: 22, fontWeight: FontWeight.w600)),
//                   ]),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTarget(Color color) {
//     final shape = widget.config.targetShape;

//     return Container(
//       width: 80,
//       height: 80,
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         shape: BoxShape.circle,
//         border: Border.all(color: color.withOpacity(0.5), width: 2),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.4),
//             blurRadius: 20,
//             spreadRadius: 2
//           )
//         ],
//       ),
//       child: Center(
//         child: Text(
//           shape.emoji,
//           style: const TextStyle(fontSize: 46)
//         ),
//       ),
//     ); // شلنا الـ animation عشان بيأثر على نعومة حركة التايمر
//   }

//   @override
//   void dispose() async {
//     _sessionTimer.cancel();
//     _changeDirTimer?.cancel();
//     _loggingTimer.cancel();
//     _gazeSub?.cancel();
//     await _audioPlayer.stop();
//     await _audioPlayer.dispose();
//     _bridge.dispose();
//     super.dispose();

//   }
// }

// // ─── HUD Bar ─────────────────────────────────────────────────────
// class _HUDBar extends StatelessWidget {
//   final int remaining;
//   final double progress;
//   final bool isPaused;
//   final VoidCallback onPause;
//   final VoidCallback onStop;

//   const _HUDBar({
//     required this.remaining,
//     required this.progress,
//     required this.isPaused,
//     required this.onPause,
//     required this.onStop,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final mins = (remaining ~/ 60).toString().padLeft(2, '0');
//     final secs = (remaining % 60).toString().padLeft(2, '0');

//     return Center(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.75),
//           borderRadius: BorderRadius.circular(50),
//           border: Border.all(color: AppColors.surfaceBorder),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('$mins:$secs',
//               style: const TextStyle(
//                 color: AppColors.primary,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w700,
//                 fontFamily: 'monospace',
//               )),
//             const SizedBox(width: 20),
//             SizedBox(
//               width: 140,
//               child: LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: AppColors.surfaceBorder,
//                 valueColor: const AlwaysStoppedAnimation(AppColors.primary),
//                 minHeight: 4,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             const SizedBox(width: 20),
//             // GestureDetector(
//             //   onTap: onPause,
//             //   child: Icon(
//             //     isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
//             //     color: AppColors.textSecondary, size: 22),
//             // ),
//             // const SizedBox(width: 16),
//             GestureDetector(
//               onTap: onStop,
//               child: const Icon(Icons.stop_rounded, color: AppColors.danger, size: 22),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Webcam Overlay ───────────────────────────────────────────────
// class _WebcamOverlay extends StatelessWidget {
//   final GazeData? gaze;
//   const _WebcamOverlay({this.gaze});

//   @override
//   Widget build(BuildContext context) {
//     final faceOk = gaze?.faceDetected ?? false;
//     final statusColor = faceOk ? AppColors.success : AppColors.danger;
//     final statusText  = faceOk
//         ? (gaze?.isGlare == true ? 'Glare detected' : 'Face tracked')
//         : 'Face not found';

//     return Container(
//       width: 172,
//       height: 130,
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: statusColor.withOpacity(0.5), width: 1.2),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 56, height: 56,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: statusColor.withOpacity(0.12),
//             ),
//             child: Icon(
//               faceOk ? Icons.face_retouching_natural_rounded : Icons.face_outlined,
//               color: statusColor, size: 28),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 7, height: 7,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: statusColor,
//                   boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 4)],
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Text(statusText,
//                 style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
//             ],
//           ),
//           if (faceOk && gaze != null) ...[
//             const SizedBox(height: 4),
//             Text('${(gaze!.confidence * 100).toStringAsFixed(0)}% confidence',
//               style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
//           ],
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/model_bridge.dart';
import 'package:audioplayers/audioplayers.dart';

class LiveSessionScreen extends StatefulWidget {
  final ChildProfile child;
  final SessionConfig config;
  final ModelBridge? bridge;

  const LiveSessionScreen({
    super.key,
    required this.child,
    required this.config,
    this.bridge,
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with TickerProviderStateMixin {
  late final ModelBridge _bridge;
  StreamSubscription<GazeData>? _gazeSub;
  GazeData? _latestGaze;
  bool _bridgeStarted = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Offset _targetPos = const Offset(0.395, 0.384);
  final _rand = Random();

  double _targetX = 0.395;
  double _targetY = 0.384;
  String _currentDirection = 'RIGHT';
  Timer? _changeDirTimer;

  final double _minX = 0.156;
  final double _maxX = 0.740;
  final double _minY = 0.231;
  final double _maxY = 0.676;

  late final double _speedX;
  late final double _speedY;

  late Timer _sessionTimer;
  late Timer _loggingTimer;
  int _elapsedSeconds = 0;
  int get _totalSeconds => widget.config.duration.seconds;
  bool _isRunning = true;
  bool _isPaused = false;

  bool _distractorActive = false;
  int _distractorFrames = 0;
  double _distractorX = 0;
  double _distractorY = 0;

  final List<GazePoint> _gazePoints = [];
  late DateTime _sessionStart;

  bool _cursorVisible = true;
  Timer? _cursorTimer;

  void _onMouseMove(PointerEvent event) {
    if (!_cursorVisible) {
      setState(() => _cursorVisible = true);
    }

    // Reset the timer every time the mouse moves
    _cursorTimer?.cancel();
    _cursorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _cursorVisible = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bridge = widget.bridge ?? ModelBridge();
    _sessionStart = DateTime.now();

    double speedMultiplier = widget.config.speed.pixelsPerSecond / 160.0;
    _speedX = (12.0 * speedMultiplier) / 1920.0;
    _speedY = (12.0 * speedMultiplier) / 1080.0;

    _cursorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _cursorVisible = false);
    });

    _startTimers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bridgeStarted) {
      _bridgeStarted = true;
      if (widget.bridge == null) {
        _startModelBridge();
      } else {
        _subscribeToExistingBridge();
      }
    }
  }

  Future<void> _subscribeToExistingBridge() async {
    try {
      final stream = _bridge.gazeStream;
      if (stream != null) {
        _gazeSub = stream.listen((gaze) {
          if (!mounted) return;
          setState(() => _latestGaze = gaze);
        });
      } else {
        await _startModelBridge();
      }
    } catch (e) {
      debugPrint('[LiveSession] subscribe error: $e');
    }
  }

  Future<void> _startModelBridge() async {
    try {
      final stream = await _bridge.start(
        cameraIndex: 0,
        wearsGlasses: widget.child.wearsGlasses,
        screenSize: MediaQuery.of(context).size,
      );
      _gazeSub = stream.listen(
        (gaze) {
          if (!mounted) return;
          setState(() => _latestGaze = gaze);
        },
        onError: (e) {
          debugPrint('[LiveSession] Model error: $e');
        },
      );
    } catch (e) {
      debugPrint('[LiveSession] Could not start model: $e');
    }
  }

  void _startTimers() async {
    if (widget.config.musicPath != null) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(DeviceFileSource(widget.config.musicPath!));
    }

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !_isRunning) return;
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _totalSeconds) _endSession();
    });

    _changeDirTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (_isPaused || !_isRunning) return;
      _currentDirection = ['UP', 'DOWN', 'LEFT', 'RIGHT'][_rand.nextInt(4)];
    });

    _loggingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_isPaused || !_isRunning) return;

      setState(() {
        if (_currentDirection == 'RIGHT') {
          _targetX += _speedX;
          if (_targetX >= _maxX) {
            _targetX = _maxX;
            _currentDirection = ['LEFT', 'UP', 'DOWN'][_rand.nextInt(3)];
          }
        } else if (_currentDirection == 'LEFT') {
          _targetX -= _speedX;
          if (_targetX <= _minX) {
            _targetX = _minX;
            _currentDirection = ['RIGHT', 'UP', 'DOWN'][_rand.nextInt(3)];
          }
        } else if (_currentDirection == 'DOWN') {
          _targetY += _speedY;
          if (_targetY >= _maxY) {
            _targetY = _maxY;
            _currentDirection = ['UP', 'LEFT', 'RIGHT'][_rand.nextInt(3)];
          }
        } else if (_currentDirection == 'UP') {
          _targetY -= _speedY;
          if (_targetY <= _minY) {
            _targetY = _minY;
            _currentDirection = ['DOWN', 'LEFT', 'RIGHT'][_rand.nextInt(3)];
          }
        }
        _targetPos = Offset(_targetX, _targetY);

        if (!_distractorActive && _rand.nextDouble() < 0.01) {
          _distractorActive = true;
          _distractorFrames = 0;

          double distSizeNormY = 120 / 1080;
          double distSizeNormX =
              (120 / 1080) *
              (MediaQuery.of(context).size.height /
                  MediaQuery.of(context).size.width);

          double safeMaxX = max(_minX + 0.01, _maxX - distSizeNormX);
          double safeMaxY = max(_minY + 0.01, _maxY - distSizeNormY);

          _distractorX = _minX + _rand.nextDouble() * (safeMaxX - _minX);
          _distractorY = _minY + _rand.nextDouble() * (safeMaxY - _minY);
        }
        if (_distractorActive) {
          _distractorFrames++;
          if (_distractorFrames > 45) _distractorActive = false;
        }
      });

      _recordGazePoint();
    });
  }

  void _recordGazePoint() {
    final gaze = _latestGaze;
    final size = MediaQuery.of(context).size;

    final bool isValid = gaze != null && gaze.faceDetected;

    final gazeX = isValid ? gaze.x * size.width : -1.0;
    final gazeY = isValid ? gaze.y * size.height : -1.0;

    _gazePoints.add(
      GazePoint(
        x: gazeX,
        y: gazeY,
        targetX: _targetPos.dx * size.width,
        targetY: _targetPos.dy * size.height,
        isDistractorActive: _distractorActive,
        timestampMs: DateTime.now().difference(_sessionStart).inMilliseconds,
        screenWidth: size.width,
        screenHeight: size.height,
      ),
    );
  }

  // Future<void> _endSession() async {
  //   if (!_isRunning) return;
  //   _isRunning = false;
  //   _sessionTimer.cancel();
  //   _changeDirTimer?.cancel();
  //   _loggingTimer.cancel();
  //   await _bridge.stop();
  //   await _audioPlayer.stop();
  //   await _audioPlayer.dispose();

  //   final result = SessionResult(
  //     id: '',
  //     childId: widget.child.id,
  //     childName: widget.child.name,
  //     config: widget.config,
  //     startTime: _sessionStart,
  //     endTime: DateTime.now(),
  //     gazePoints: _gazePoints,
  //     attentionTimeline: _buildTimeline(),
  //   );

  //   final service = FirestoreService();
  //   final id = await service.saveSession(result);

  //   if (mounted) {
  //     context.pushReplacement(
  //       '/results/$id',
  //       extra: SessionResult(
  //         id: id,
  //         childId: result.childId,
  //         childName: result.childName,
  //         config: result.config,
  //         startTime: result.startTime,
  //         endTime: result.endTime,
  //         gazePoints: result.gazePoints,
  //         attentionTimeline: result.attentionTimeline,
  //       ),
  //     );
  //   }
  // }

  // Future<void> _endSession() async {
  //   if (!_isRunning) return;
  //   _isRunning = false;
  //   _sessionTimer.cancel();
  //   _changeDirTimer?.cancel();
  //   _loggingTimer.cancel();
  //   await _bridge.stop();

  //   try {
  //     await _audioPlayer.stop();
  //   } catch (_) {}
  //   try {
  //     await _audioPlayer.dispose();
  //   } catch (_) {}

  //   final result = SessionResult(
  //     id: '', // Temporary, will be replaced below
  //     childId: widget.child.id,
  //     childName: widget.child.name,
  //     config: widget.config,
  //     startTime: _sessionStart,
  //     endTime: DateTime.now(),
  //     gazePoints: _gazePoints,
  //     attentionTimeline: _buildTimeline(),
  //   );

  //   // Fallback ID in case we are offline
  //   String sessionId = 'local_${DateTime.now().millisecondsSinceEpoch}';

  //   try {
  //     final service = FirestoreService();
  //     // 🚨 Give Firebase exactly 3 seconds to save. If it fails or hangs, it throws an error.
  //     sessionId = await service
  //         .saveSession(result)
  //         .timeout(const Duration(seconds: 3));
  //   } catch (e) {
  //     debugPrint('[LiveSession] Offline or Firestore error: $e');
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text(
  //             '⚠️ No internet connection. Displaying local results.',
  //           ),
  //           backgroundColor: AppColors.warning,
  //           duration: Duration(seconds: 4),
  //         ),
  //       );
  //     }
  //   }

  //   if (mounted) {
  //     // 🚨 Now it will ALWAYS navigate, even if offline!
  //     context.pushReplacement(
  //       '/results/$sessionId',
  //       extra: SessionResult(
  //         id: sessionId,
  //         childId: result.childId,
  //         childName: result.childName,
  //         config: result.config,
  //         startTime: result.startTime,
  //         endTime: result.endTime,
  //         gazePoints: result.gazePoints,
  //         attentionTimeline: result.attentionTimeline,
  //       ),
  //     );
  //   }
  // }

  Future<void> _endSession() async {
    if (!_isRunning) return;
    _isRunning = false;
    _sessionTimer.cancel();
    _changeDirTimer?.cancel();
    _loggingTimer.cancel();
    await _bridge.stop();
    
    try { await _audioPlayer.stop(); } catch (_) {}
    try { await _audioPlayer.dispose(); } catch (_) {}

    // 1. Generate a permanent, unique ID right now
    final String sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    final result = SessionResult(
      id: sessionId, // 🚨 Use the permanent ID
      childId: widget.child.id,
      childName: widget.child.name,
      config: widget.config,
      startTime: _sessionStart,
      endTime: DateTime.now(),
      gazePoints: _gazePoints,
      attentionTimeline: _buildTimeline(),
    );

    // 2. "Fire and Forget"
    // We do NOT use 'await'. We just tell Firestore to save it. 
    // If offline, Firestore instantly saves it to the local device cache and will 
    // automatically push it to the cloud when the internet comes back.
    final service = FirestoreService();
    service.saveSession(result).catchError((e) {
      debugPrint('[LiveSession] Background sync error: $e');
      return result.id; // 🚨 Satisfies Dart by returning a String
    });

    // 3. Navigate instantly (No 3-second freezing!)
    if (mounted) {
      context.pushReplacement(
        '/results/$sessionId',
        extra: SessionResult(
          id: sessionId,
          childId: result.childId,
          childName: result.childName,
          config: result.config,
          startTime: result.startTime,
          endTime: result.endTime,
          gazePoints: result.gazePoints,
          attentionTimeline: result.attentionTimeline,
        ),
      );
    }
  }

  Future<void> _abortSession() async {
    _isRunning = false;
    _sessionTimer.cancel();
    _changeDirTimer?.cancel();
    _loggingTimer.cancel();
    _gazeSub?.cancel();
    await _bridge.stop();
    await _audioPlayer.stop();
    await _audioPlayer.dispose();

    if (mounted) {
      context.pop(); // Returns to the previous screen without pushing results
    }
  }

  Future<bool> _confirmExit() async {
    // Pause the session while the dialog is open
    final wasPaused = _isPaused;
    setState(() => _isPaused = true);
    _bridge.pause();
    _audioPlayer.pause();

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // Match your app theme
        title: const Text(
          'Exit Session?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to exit? Session data will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Exit',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _abortSession();
      return true;
    } else {
      // Resume if they canceled the exit and the session wasn't already paused
      if (!wasPaused) {
        setState(() => _isPaused = false);
        _bridge.resume();
        if (widget.config.musicPath != null) _audioPlayer.resume();
      }
      return false;
    }
  }

  List<AttentionSpan> _buildTimeline() {
    if (_gazePoints.isEmpty) return [];
    final spans = <AttentionSpan>[];
    int spanStart = 0;
    bool lastFocused = _gazePoints.first.isOnTarget;

    for (int i = 1; i < _gazePoints.length; i++) {
      if (_gazePoints[i].isOnTarget != lastFocused) {
        spans.add(
          AttentionSpan(
            startMs: _gazePoints[spanStart].timestampMs,
            endMs: _gazePoints[i].timestampMs,
            isFocused: lastFocused,
            hasDistractor: _gazePoints
                .sublist(spanStart, i)
                .any((p) => p.isDistractorActive),
          ),
        );
        spanStart = i;
        lastFocused = _gazePoints[i].isOnTarget;
      }
    }
    spans.add(
      AttentionSpan(
        startMs: _gazePoints[spanStart].timestampMs,
        endMs: _totalSeconds * 1000,
        isFocused: lastFocused,
        hasDistractor: _gazePoints
            .sublist(spanStart)
            .any((p) => p.isDistractorActive),
      ),
    );
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final targetColor = AppColors.targetColors[widget.config.targetColorIndex];
    final remaining = _totalSeconds - _elapsedSeconds;
    final progress = _elapsedSeconds / _totalSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // 2. Listen for the Escape key being pressed down
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            _endSession(); 
            
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: MouseRegion(
            opaque: true,
            cursor: _cursorVisible
                ? SystemMouseCursors.basic
                : SystemMouseCursors.none,
            onHover: _onMouseMove,
            child: Stack(
              children: [
                if (_distractorActive)
                  Positioned(
                    left: _distractorX * size.width,
                    top: _distractorY * size.height,
                    child: Container(
                      width: max(20.0, size.height * (80 / 1080)),
                      height: max(20.0, size.height * (80 / 1080)),
                      color: const Color.fromARGB(255, 255, 50, 50),
                    ),
                  ),
        
                Positioned(
                  left: (_targetPos.dx * size.width - (size.width * (40 / 1920)))
                      .clamp(0, size.width),
                  top: (_targetPos.dy * size.height - (size.width * (40 / 1920)))
                      .clamp(0, size.height),
                  child: _buildTarget(targetColor, size),
                ),
        
                // if (_latestGaze != null && _latestGaze!.faceDetected)
                //   Positioned(
                //     left: (_latestGaze!.x * size.width) - 15,
                //     top: (_latestGaze!.y * size.height) - 15,
                //     child: Container(
                //       width: 30, height: 30,
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         border: Border.all(
                //           color: _latestGaze!.isReliable ? Colors.white : Colors.orangeAccent,
                //           width: 3,
                //         ),
                //         boxShadow: [
                //           BoxShadow(
                //             color: Colors.black.withOpacity(0.2),
                //             blurRadius: 4, spreadRadius: 1
                //           )
                //         ]
                //       ),
                //       child: Center(
                //         child: Container(
                //           width: 6, height: 6,
                //           decoration: const BoxDecoration(
                //             color: Colors.white,
                //             shape: BoxShape.circle,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
        
                // ... inside the Stack in build() ...
                // if (_latestGaze != null && _latestGaze!.faceDetected)
                //   Builder(
                //     builder: (context) {
                //       // 1. Convert normalized coordinates to actual screen pixels
                //       final double gazePixelX = _latestGaze!.x * size.width;
                //       final double gazePixelY = _latestGaze!.y * size.height;
                //       final double targetPixelX = _targetPos.dx * size.width;
                //       final double targetPixelY = _targetPos.dy * size.height;
        
                //       // 2. Calculate the distance in actual pixels
                //       final double distance = sqrt(
                //         pow(gazePixelX - targetPixelX, 2) +
                //             pow(gazePixelY - targetPixelY, 2),
                //       );
        
                //       // 3. Use the exact same threshold logic from your GazePoint model
                //       final diagonal = sqrt(
                //         size.width * size.width +
                //             (size.width * 0.593) * (size.width * 0.593),
                //       );
                //       final originalDiagonal = sqrt(1920 * 1920 + 1080 * 1080.0);
                //       final allowedDist = diagonal * (350 / originalDiagonal);
        
                //       // 4. Check if focused
                //       final bool isFocused = distance <= allowedDist;
        
                //       return Positioned(
                //         left:
                //             gazePixelX -
                //             15, // Using the pixel coordinates we just calculated
                //         top: gazePixelY - 15,
                //         child: Container(
                //           width: 30,
                //           height: 30,
                //           decoration: BoxDecoration(
                //             shape: BoxShape.circle,
                //             border: Border.all(
                //               color: isFocused ? Colors.white : Colors.red,
                //               width: 3,
                //             ),
                //             boxShadow: [
                //               BoxShadow(
                //                 color: (isFocused ? Colors.white : Colors.red)
                //                     .withOpacity(0.3),
                //                 blurRadius: 10,
                //                 spreadRadius: 2,
                //               ),
                //             ],
                //           ),
                //           child: Center(
                //             child: Container(
                //               width: 6,
                //               height: 6,
                //               decoration: BoxDecoration(
                //                 color: isFocused ? Colors.white : Colors.red,
                //                 shape: BoxShape.circle,
                //               ),
                //             ),
                //           ),
                //         ),
                //       );
                //     },
                //   ),
        
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _WebcamOverlay(gaze: _latestGaze),
                ),
        
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                    onPressed: _confirmExit,
                  ),
                ),
        
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: _HUDBar(
                    remaining: remaining,
                    progress: progress,
                    isPaused: _isPaused,
                    onPause: () {
                      setState(() => _isPaused = !_isPaused);
                      if (_isPaused) {
                        _bridge.pause();
                        _audioPlayer.pause();
                      } else {
                        _bridge.resume();
                        if (widget.config.musicPath != null)
                          _audioPlayer.resume();
                      }
                    },
                    onStop: _endSession,
                  ),
                ),
        
                if (_distractorActive)
                  Positioned(
                    top: 64,
                    right: 16,
                    child:
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningDim,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.warning,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Distractor',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 80.ms)
                            .then(delay: 1600.ms)
                            .fadeOut(),
                  ),
        
                if (_isPaused)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pause_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Session paused',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarget(Color color, Size size) {
    final shape = widget.config.targetShape;
    final double diameter = (size.width * (40 / 1920)) * 2;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(shape.emoji, style: TextStyle(fontSize: diameter * 0.55)),
      ),
    );
  }

  @override
  void dispose() async {
    _sessionTimer.cancel();
    _changeDirTimer?.cancel();
    _loggingTimer.cancel();
    _gazeSub?.cancel();
    try {
      _audioPlayer.dispose();
    } catch (_) {}
    // await _audioPlayer.stop();
    // await _audioPlayer.dispose();
    _bridge.dispose();
    super.dispose();
  }
}

class _HUDBar extends StatelessWidget {
  final int remaining;
  final double progress;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const _HUDBar({
    required this.remaining,
    required this.progress,
    required this.isPaused,
    required this.onPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final mins = (remaining ~/ 60).toString().padLeft(2, '0');
    final secs = (remaining % 60).toString().padLeft(2, '0');

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$mins:$secs',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: onStop,
              child: const Icon(
                Icons.stop_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebcamOverlay extends StatelessWidget {
  final GazeData? gaze;
  const _WebcamOverlay({this.gaze});

  @override
  Widget build(BuildContext context) {
    final faceOk = gaze?.faceDetected ?? false;
    final statusColor = faceOk ? AppColors.success : AppColors.danger;
    final statusText = faceOk
        ? (gaze?.isGlare == true ? 'Glare detected' : 'Face tracked')
        : 'Face not found';

    return Container(
      width: 172,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.12),
            ),
            child: Icon(
              faceOk
                  ? Icons.face_retouching_natural_rounded
                  : Icons.face_outlined,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (faceOk && gaze != null) ...[
            const SizedBox(height: 4),
            Text(
              '${(gaze!.confidence * 100).toStringAsFixed(0)}% confidence',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

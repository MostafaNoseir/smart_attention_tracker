

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // مهم جداً عشان الكيبورد
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:go_router/go_router.dart';
// import '../../theme/app_theme.dart';
// import '../../widgets/shared_widgets.dart';
// import '../../models/models.dart';
// import '../../services/model_bridge.dart';

// class CalibrationScreen extends StatefulWidget {
//   final ChildProfile child;
//   final SessionConfig config;

//   const CalibrationScreen({
//     super.key,
//     required this.child,
//     required this.config,
//   });

//   @override
//   State<CalibrationScreen> createState() => _CalibrationScreenState();
// }

// class _CalibrationScreenState extends State<CalibrationScreen> {
//   // static const _gridPositions = [
//   //   Alignment.topLeft,
//   //   Alignment.topRight,
//   //   Alignment.center,
//   //   Alignment.bottomLeft,
//   //   Alignment.bottomRight,
//   // ];

//   // static const _gridNormalized = [
//   //   (0.1, 0.1), (0.9, 0.1),
//   //   (0.5, 0.5),
//   //   (0.1, 0.9), (0.9, 0.9),
//   // ];

//   // static const _gridNormalized = [
//   //   (0.2, 0.2),
//   //   (0.8, 0.2),
//   //   (0.5, 0.5),
//   //   (0.2, 0.8),
//   //   (0.8, 0.8),
//   // ];

//   // 🚨 شبكة المعايرة الكاملة (9 نقط) لأعلى دقة ممكنة
//   static const _gridNormalized = [
//     (0.2, 0.2), (0.5, 0.2), (0.8, 0.2), // الصف اللي فوق (شمال، نص، يمين)
//     (0.2, 0.5), (0.5, 0.5), (0.8, 0.5), // الصف اللي في النص
//     (0.2, 0.8), (0.5, 0.8), (0.8, 0.8), // الصف اللي تحت
//   ];

//   int _currentPoint = 0;
//   bool _isDone = false;
//   bool _bridgeStarted = false;
//   bool _isCameraReady = false; // ← المتغير الجديد

//   bool _isCollecting = false;

//   late ModelBridge _bridge;
//   StreamSubscription<GazeData>? _gazeSub;
//   final List<CalibrationPoint> _collectedPoints = [];

//   // 1. تعريف المتغير اللي كان ناقص
//   GazeData? _latestGaze;

//   // 2. تعريف الـ FocusNode عشان الكيبورد
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _bridge = ModelBridge();
//   }

//   // @override
//   // void didChangeDependencies() {
//   //   super.didChangeDependencies();
//   //   if (!_bridgeStarted) {
//   //     _bridgeStarted = true;
//   //     _startBridge();
//   //   }
//   // }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!_bridgeStarted) {
//       _bridgeStarted = true;
//       _startBridge();

//       // التعديل الجديد: الاستماع لرد بايثون بعد المعايرة
//       _bridge.statusStream.listen((msg) {
//         if (!mounted) return;
//         if (msg == 'calibration_done') {
//           setState(() => _isDone = true);
//         } else if (msg.contains('calibration_failed')) {
//           // لو بايثون رفضها عشان Error > 150
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 '⚠️ المعايرة غير دقيقة (يبدو أن الطفل لم يركز). يرجى الإعادة!',
//               ),
//               backgroundColor: AppColors.danger,
//               duration: Duration(seconds: 4),
//             ),
//           );
//           // تصفير النقط وإجبار المستخدم على الإعادة
//           setState(() {
//             _currentPoint = 0;
//             _collectedPoints.clear();
//             _isDone = false;
//           });
//           _focusNode.requestFocus();
//         }
//       });
//     }
//   }

//   // Future<void> _startBridge() async {
//   //   final size = MediaQuery.of(context).size;
//   //   try {
//   //     final stream = await _bridge.start(
//   //       cameraIndex: 0,
//   //       wearsGlasses: widget.child.wearsGlasses,
//   //       screenSize: size,
//   //     );
//   //     _gazeSub = stream.listen((gaze) {
//   //       if (!mounted) return;
//   //       // تحديث مكان العين دايماً عشان لما ندوس مسطرة نلاقي الداتا جاهزة
//   //       setState(() {
//   //         _latestGaze = gaze;
//   //       });
//   //     });
//   //   } catch (e) {
//   //     debugPrint('[Calibration] bridge error: $e');
//   //   }
//   // }

//   Future<void> _startBridge() async {
//     final size = MediaQuery.of(context).size;
//     try {
//       final stream = await _bridge.start(
//         cameraIndex: 0,
//         wearsGlasses: widget.child.wearsGlasses,
//         screenSize: size,
//       );
//       _gazeSub = stream.listen((gaze) {
//         if (!mounted) return;
//         setState(() {
//           _latestGaze = gaze;
//           // أول ما نستقبل داتا حقيقية (حتى لو الوش مش ظاهر، المهم الكاميرا فتحت)
//           // نقفل الـ Loading فوراً
//           if (!_isCameraReady && gaze != null) {
//             _isCameraReady = true;
//           }
//         });
//       });
//     } catch (e) {
//       debugPrint('[Calibration] bridge error: $e');
//       // لو حصل إيرور برضه نقفل اللودينج عشان التطبيق ميهنجش
//       if (mounted) setState(() => _isCameraReady = true);
//     }
//   }

//   // // الدالة دي هتشتغل لما ندوس Space
//   // void _capturePoint() {
//   //   if (_isDone || !_isCameraReady) return; // لو خلصنا متعملش حاجة

//   //   // لو الموديل مش لاقط وش الطفل أصلاً، متعملش حاجة عشان الداتا متضربش
//   //   if (_latestGaze == null || !_latestGaze!.faceDetected) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('الرجاء النظر إلى الكاميرا أولاً!'),
//   //         backgroundColor: Colors.orange
//   //       ),
//   //     );
//   //     return;
//   //   }

//   //   // بناخد لقطة فورية سريعة جداً زي زرار الـ Space بتاع صاحبك
//   //   final (sx, sy) = _gridNormalized[_currentPoint];
//   //   _collectedPoints.add(CalibrationPoint(
//   //     screenX: sx,
//   //     screenY: sy,
//   //     gazeSamples: [{'raw_x': _latestGaze!.x, 'raw_y': _latestGaze!.y}],
//   //   ));

//   //   // ننقل للنقطة اللي بعدها فوراً
//   //   if (_currentPoint < _gridPositions.length - 1) {
//   //     setState(() {
//   //       _currentPoint++;
//   //     });
//   //   // } else {
//   //   //   // لو خلصنا الـ 5 نقط، نبعتهم للبايثون
//   //   //   _bridge.sendCommand({
//   //   //     'command': 'calibrate',
//   //   //     'points': _collectedPoints.map((p) => p.toJson()).toList(),
//   //   //   });
//   //   //   setState(() {
//   //   //     _isDone = true;
//   //   //   });
//   //   // }
//   //   } else {
//   //     // لو خلصنا الـ 5 نقط، نبعتهم للبايثون
//   //     _bridge.sendCommand({
//   //       'command': 'calibrate',
//   //       'points': _collectedPoints.map((p) => p.toJson()).toList(),
//   //     });
//   //     // شلنا setState(() => _isDone = true) من هنا.. هنستنى رد بايثون الأول!
//   //   }
//   // }

//   void _capturePoint() {
//     if (_isDone || !_isCameraReady || _isCollecting) return;

//     if (_latestGaze == null || !_latestGaze!.faceDetected) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('الرجاء النظر إلى الكاميرا أولاً!'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() => _isCollecting = true);

//     // ابدأ تجمع samples لمدة ثانية واحدة
//     final samples = <Map<String, double>>[];

//     Timer.periodic(const Duration(milliseconds: 50), (timer) {
//       if (_latestGaze != null && _latestGaze!.faceDetected) {
//         samples.add({'raw_x': _latestGaze!.x, 'raw_y': _latestGaze!.y});
//       }

//       // لما نجمع 20 sample (ثانية واحدة على 20fps)
//       if (samples.length >= 20) {
//         timer.cancel();

//         final (sx, sy) = _gridNormalized[_currentPoint];
//         _collectedPoints.add(
//           CalibrationPoint(screenX: sx, screenY: sy, gazeSamples: samples),
//         );

//         if (mounted) {
//           setState(() {
//             _isCollecting = false;
//             if (_currentPoint < _gridNormalized.length - 1) {
//               _currentPoint++;
//             } else {
//               _bridge.sendCommand({
//                 'command': 'calibrate',
//                 'points': _collectedPoints.map((p) => p.toJson()).toList(),
//               });
//             }
//           });
//         }
//       }
//     });
//   }

//   // void _capturePoint() {
//   //   if (_isDone || !_isCameraReady) return;

//   //   if (_latestGaze == null || !_latestGaze!.faceDetected) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(
//   //         content: Text('الرجاء النظر إلى الكاميرا أولاً!'),
//   //         backgroundColor: Colors.orange
//   //       ),
//   //     );
//   //     return;
//   //   }

//   //   final (sx, sy) = _gridNormalized[_currentPoint];
//   //   _collectedPoints.add(CalibrationPoint(
//   //     screenX: sx,
//   //     screenY: sy,
//   //     gazeSamples: [{'raw_x': _latestGaze!.x, 'raw_y': _latestGaze!.y}],
//   //   ));

//   //   if (_currentPoint < _gridNormalized.length - 1) {
//   //     setState(() => _currentPoint++);
//   //   } else {
//   //     _bridge.sendCommand({
//   //       'command': 'calibrate',
//   //       'points': _collectedPoints.map((p) => p.toJson()).toList(),
//   //     });
//   //   }
//   // }

//   void _startSession() {
//     context.pushReplacement(
//       '/session/live',
//       extra: {
//         'child': widget.child,
//         'config': widget.config,
//         'bridge': _bridge,
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.black,
//       // 3. تغليف الشاشة بالـ Focus عشان نسمع الكيبورد
//       body: Focus(
//         autofocus: true,
//         focusNode: _focusNode,
//         onKeyEvent: (node, event) {
//           // لو الزرار اللي انداس هو المسطرة (Space)
//           if (event is KeyDownEvent &&
//               event.logicalKey == LogicalKeyboardKey.space) {
//             _capturePoint();
//             return KeyEventResult.handled;
//           }
//           return KeyEventResult.ignored;
//         },
//         child: Stack(
//           children: [
//             Positioned(
//               top: 20,
//               left: 20,
//               child: Material(
//                 color: Colors.transparent,
//                 child: IconButton(
//                   icon: const Icon(
//                     Icons.arrow_back_ios_new_rounded,
//                     color: Colors.white,
//                     size: 28,
//                   ),
//                   onPressed: () {
//                     _bridge.stop(); // Stop the bridge before leaving
//                     context.pop();
//                   },
//                 ),
//               ),
//             ).animate().fadeIn(delay: 200.ms),

//             if (!_isCameraReady)
//               Positioned.fill(
//                 child: Container(
//                   color: Colors.black.withOpacity(0.8), // لون معتم
//                   child: const Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(color: AppColors.primary),
//                         SizedBox(height: 24),
//                         Text(
//                           'Starting camera...',
//                           style: TextStyle(
//                             color: AppColors.textPrimary,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Please wait while the model initializes.',
//                           style: TextStyle(
//                             color: AppColors.textMuted,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             // ── Camera hint ───────────────────────────────────────
//             Positioned(
//               top: 20,
//               right: 20,
//               child: Container(
//                 width: 200,
//                 height: 150,
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors.surfaceBorder),
//                 ),
//                 child: const Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.videocam_outlined,
//                       color: AppColors.primary,
//                       size: 32,
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'Camera feed',
//                       style: TextStyle(
//                         color: AppColors.textSecondary,
//                         fontSize: 12,
//                       ),
//                     ),
//                     Text(
//                       '(model connected)',
//                       style: TextStyle(
//                         color: AppColors.textMuted,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn(delay: 300.ms),
//             ),

//             // ── Instructions ──────────────────────────────────────
//             if (!_isDone)
//               Positioned(
//                 top: 20,
//                 left: 20,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 14,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.surface.withOpacity(0.9),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: AppColors.surfaceBorder),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           GlowDot(color: AppColors.primary),
//                           const SizedBox(width: 10),
//                           const Text(
//                             'Eye calibration',
//                             style: TextStyle(
//                               color: AppColors.textPrimary,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Point ${_currentPoint + 1} of ${_gridNormalized.length}',
//                         style: const TextStyle(
//                           color: AppColors.primary,
//                           fontSize: 13,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       // 4. تعديل النص ليناسب المسطرة
//                       const Text(
//                         'Look at the dot, then press SPACE',
//                         style: TextStyle(
//                           color: AppColors.textMuted,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ).animate().fadeIn(),
//               ),

//             // ── Dots ──────────────────────────────────────────────
//             if (!_isDone)
//               Padding(
//                 padding: const EdgeInsets.all(80),
//                 child: Stack(
//                   children: _gridNormalized.asMap().entries.map((e) {
//                     final isActive = e.key == _currentPoint;
//                     final isDoneDot = e.key < _currentPoint;
//                     return Align(
//                       alignment: e.value,
//                       // سبنا الكليك شغال كـ Backup بس الأساس بقى المسطرة
//                       child: GestureDetector(
//                         onTap: isActive ? _capturePoint : null,
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           width: isActive ? 32 : 14,
//                           height: isActive ? 32 : 14,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: isDoneDot
//                                 ? AppColors.success
//                                 : isActive
//                                 ? (_isCollecting
//                                       ? AppColors.warning
//                                       : AppColors.primary)
//                                 : AppColors.textMuted.withOpacity(0.3),
//                             boxShadow: isActive
//                                 ? [
//                                     BoxShadow(
//                                       color: AppColors.primary.withOpacity(0.6),
//                                       blurRadius: 20,
//                                       spreadRadius: 4,
//                                     ),
//                                   ]
//                                 : null,
//                           ),
//                           child: isDoneDot
//                               ? const Icon(
//                                   Icons.check,
//                                   size: 10,
//                                   color: Colors.white,
//                                 )
//                               : null,
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),

//             // // ── Dots ──────────────────────────────────────────────
//             // if (!_isDone)
//             //   Stack(
//             //     children: _gridNormalized.asMap().entries.map((e) {
//             //       final isActive  = e.key == _currentPoint;
//             //       final isDoneDot = e.key < _currentPoint;
//             //       final (nx, ny) = e.value;

//             //       // بنحدد حجم النقطة عشان نطرح نصه من الإحداثيات فتبقى النقطة في السنتر بالظبط
//             //       final double dotSize = isActive ? 32.0 : 14.0;

//             //       return Positioned(
//             //         // 🚨 هنا السحر: النقطة بتترسم في مكانها الحقيقي بالبكسل 🚨
//             //         left: (nx * size.width) - (dotSize / 2),
//             //         top: (ny * size.height) - (dotSize / 2),
//             //         child: GestureDetector(
//             //           onTap: isActive ? _capturePoint : null,
//             //           child: AnimatedContainer(
//             //             duration: const Duration(milliseconds: 300),
//             //             width: dotSize,
//             //             height: dotSize,
//             //             decoration: BoxDecoration(
//             //               shape: BoxShape.circle,
//             //               color: isDoneDot
//             //                   ? AppColors.success
//             //                   : isActive
//             //                       ? AppColors.primary
//             //                       : AppColors.textMuted.withOpacity(0.3),
//             //               boxShadow: isActive ? [BoxShadow(
//             //                 color: AppColors.primary.withOpacity(0.6),
//             //                 blurRadius: 20, spreadRadius: 4)] : null,
//             //             ),
//             //             child: isDoneDot
//             //                 ? const Icon(Icons.check, size: 10, color: Colors.white)
//             //                 : null,
//             //           ),
//             //         ),
//             //       );
//             //     }).toList(),
//             //   ),

//             // ── Progress ──────────────────────────────────────────
//             if (!_isDone)
//               Positioned(
//                 bottom: 30,
//                 left: 0,
//                 right: 0,
//                 child: Column(
//                   children: [
//                     Text(
//                       'Calibrating ${_currentPoint}/${_gridNormalized.length} points',
//                       style: const TextStyle(
//                         color: AppColors.textMuted,
//                         fontSize: 12,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: 300,
//                       child: LinearProgressIndicator(
//                         value: _currentPoint / _gridNormalized.length,
//                         backgroundColor: AppColors.surfaceBorder,
//                         valueColor: const AlwaysStoppedAnimation(
//                           AppColors.primary,
//                         ),
//                         minHeight: 4,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             // ── Done ──────────────────────────────────────────────
//             if (_isDone)
//               Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(48),
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(color: AppColors.primary, width: 1.5),
//                     boxShadow: [
//                       BoxShadow(color: AppColors.primaryGlow, blurRadius: 30),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: 72,
//                         height: 72,
//                         decoration: const BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: AppColors.primaryDim,
//                         ),
//                         child: const Icon(
//                           Icons.check_rounded,
//                           color: AppColors.primary,
//                           size: 40,
//                         ),
//                       ).animate().scale(delay: 100.ms),
//                       const SizedBox(height: 24),
//                       Text(
//                         'Calibration complete!',
//                         style: Theme.of(context).textTheme.headlineMedium,
//                         textAlign: TextAlign.center,
//                       ).animate().fadeIn(delay: 200.ms),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Eye tracking is ready for ${widget.child.name}.\n'
//                         'The session will begin when you click start.',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodyLarge,
//                       ).animate().fadeIn(delay: 300.ms),
//                       const SizedBox(height: 32),
//                       Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           OutlinedButton.icon(
//                             onPressed: () => setState(() {
//                               _currentPoint = 0;
//                               _isDone = false;
//                               _collectedPoints.clear();
//                               // نطلب Focus للكيبورد تاني لو قررنا نعيد
//                               _focusNode.requestFocus();
//                             }),
//                             icon: const Icon(Icons.refresh_rounded, size: 18),
//                             label: const Text('Recalibrate'),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: AppColors.textPrimary,
//                               side: const BorderSide(
//                                 color: AppColors.surfaceBorder,
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 14,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 16),
//                           ElevatedButton.icon(
//                             onPressed: _startSession,
//                             icon: const Icon(Icons.play_arrow_rounded),
//                             label: const Text('Start session'),
//                             style: ElevatedButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 28,
//                                 vertical: 16,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ).animate().fadeIn(delay: 400.ms),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _gazeSub?.cancel();
//     _focusNode.dispose();
//     super.dispose();
//   }
// }



import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/model_bridge.dart';

class CalibrationScreen extends StatefulWidget {
  final ChildProfile child;
  final SessionConfig config;

  const CalibrationScreen({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  // 🚨 9 نقط عشان نغطي الشاشة كلها للموديل الجديد
  static const _gridNormalized = [
    (0.2, 0.2), (0.5, 0.2), (0.8, 0.2),
    (0.2, 0.5), (0.5, 0.5), (0.8, 0.5),
    (0.2, 0.8), (0.5, 0.8), (0.8, 0.8),
  ];

  int _currentPoint = 0;
  bool _isDone = false;
  bool _bridgeStarted = false;
  bool _isCameraReady = false;
  bool _isCollecting = false;
  bool _waitingForCalibrateResponse = false;

  late ModelBridge _bridge;
  StreamSubscription<GazeData>? _gazeSub;
  final List<CalibrationPoint> _collectedPoints = [];
  GazeData? _latestGaze;
  int _calibrationRetries = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bridge = ModelBridge();
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (!_bridgeStarted) {
  //     _bridgeStarted = true;
  //     _startBridge();

  //     _bridge.statusStream.listen((msg) {
  //       if (!mounted) return;
  //       if (msg == 'calibration_done') {
  //         setState(() => _isDone = true);
  //       } else if (msg.contains('calibration_failed')) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('⚠️ المعايرة غير دقيقة (الرجاء التركيز). يرجى الإعادة!'),
  //             backgroundColor: AppColors.danger,
  //             duration: Duration(seconds: 4),
  //           ),
  //         );
  //         setState(() {
  //           _currentPoint = 0;
  //           _collectedPoints.clear();
  //           _isDone = false;
  //         });
  //         _focusNode.requestFocus();
  //       }
  //     });
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_bridgeStarted) {
      _bridgeStarted = true;
      _startBridge();

      _bridge.statusStream.listen((data) {
        if (!mounted) return;
        
        final msg = data['message'];
        final success = data['success'] ?? false;

        if (msg == 'calibration_done' && success) {
          setState(() {
            _isDone = true;
            _waitingForCalibrateResponse = false;
          });
        } else if (msg == 'calibration_failed' || !success) {
          // increment retry counter so we can store this metric later
          _calibrationRetries++;
          
          // Determine reason for failure
          final reason = data['reason'] ?? 'unknown';
          // String errorText = '⚠️ المعايرة غير دقيقة (الرجاء التركيز على النقاط). يرجى الإعادة!';
          String errorText = '⚠️ Inaccurate calibration (please focus on the dots). Please try again!';
          
          if (reason == 'insufficient_samples') {
            //  errorText = '⚠️ لم يتم جمع بيانات كافية! تأكد من فتح عينيك والنظر للكاميرا.';
             errorText = '⚠️ Insufficient data collected! Make sure to keep your eyes open and look at the camera.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorText),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 4),
            ),
          );
          
          setState(() {
            _currentPoint = 0;
            _collectedPoints.clear();
            _isDone = false;
            _waitingForCalibrateResponse = false;
          });
          _focusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _startBridge() async {
    final size = MediaQuery.of(context).size;
    try {
      final stream = await _bridge.start(
        cameraIndex: 0,
        wearsGlasses: widget.child.wearsGlasses,
        screenSize: size,
      );
      _gazeSub = stream.listen((gaze) {
        if (!mounted) return;
        setState(() {
          _latestGaze = gaze;
          if (!_isCameraReady && gaze != null) {
            _isCameraReady = true;
          }
        });
      });
    } catch (e) {
      debugPrint('[Calibration] bridge error: $e');
      if (mounted) setState(() => _isCameraReady = true);
    }
  }

  // void _capturePoint() {
  //   if (_isDone || !_isCameraReady || _isCollecting) return;

  //   if (_latestGaze == null || !_latestGaze!.faceDetected) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('الرجاء النظر إلى الكاميرا أولاً!'),
  //         backgroundColor: Colors.orange,
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() => _isCollecting = true);

  //   final samples = <Map<String, dynamic>>[];

  //   Timer.periodic(const Duration(milliseconds: 50), (timer) {
  //     if (_latestGaze != null && _latestGaze!.faceDetected && _latestGaze!.features.isNotEmpty) {
  //       samples.add({'features': _latestGaze!.features});
  //     }

  //     if (samples.length >= 26) {
  //       timer.cancel();
  //       final usableSamples = samples.sublist(6); // ← drop first 300ms

  //       final (sx, sy) = _gridNormalized[_currentPoint];
  //       _collectedPoints.add(
  //         CalibrationPoint(screenX: sx, screenY: sy, gazeSamples: usableSamples),
  //       );

  //       // final (sx, sy) = _gridNormalized[_currentPoint];
  //       // _collectedPoints.add(
  //       //   CalibrationPoint(screenX: sx, screenY: sy, gazeSamples: samples),
  //       // );

  //       if (mounted) {
  //         setState(() {
  //           _isCollecting = false;
  //           if (_currentPoint < _gridNormalized.length - 1) {
  //             _currentPoint++;
  //           } else {
  //             _bridge.sendCommand({
  //               'command': 'calibrate',
  //               'points': _collectedPoints.map((p) => p.toJson()).toList(),
  //             });
  //           }
  //         });
  //       }
  //     }
  //   });
  // }

  void _capturePoint() {
    if (_isDone || !_isCameraReady || _isCollecting || _waitingForCalibrateResponse) return;

    if (_latestGaze == null || !_latestGaze!.faceDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // content: Text('الرجاء النظر إلى الكاميرا أولاً!'),
          content: Text('Please look at the camera first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🚨 The Bouncer: Refuse to start if eyes are closed
    if (_latestGaze!.isBlinking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // content: Text('الرجاء فتح عينيك أثناء المعايرة!'), 
          content: Text('Please keep your eyes open during calibration!'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 1500),
        ),
      );
      return;
    }

    setState(() => _isCollecting = true);

    final samples = <Map<String, dynamic>>[];

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // 🚨 ONLY collect frame if face is visible AND eyes are open
      if (_latestGaze != null && 
          _latestGaze!.faceDetected && 
          !_latestGaze!.isBlinking && 
          _latestGaze!.features.isNotEmpty) {
        samples.add({'features': _latestGaze!.features});
      }

      // Keep waiting until we successfully gather 26 completely open-eye frames
        if (samples.length >= 26) {
        timer.cancel();
        final usableSamples = samples.sublist(6); // Drop first 300ms

        final (sx, sy) = _gridNormalized[_currentPoint];
        _collectedPoints.add(
          CalibrationPoint(screenX: sx, screenY: sy, gazeSamples: usableSamples),
        );

        if (mounted) {
          setState(() {
            _isCollecting = false;
            if (_currentPoint < _gridNormalized.length - 1) {
              _currentPoint++;
            } else {
                // Sent final calibration payload — mark waiting so space doesn't trigger another capture
                _waitingForCalibrateResponse = true;
                _bridge.sendCommand({
                  'command': 'calibrate',
                  'points': _collectedPoints.map((p) => p.toJson()).toList(),
                });
            }
          });
        }
      }
    });
  }

  void _startSession() {
    context.pushReplacement(
      '/session/live',
      extra: {
        'child': widget.child,
        'config': widget.config,
        'bridge': _bridge,
        'calibrationRetries': _calibrationRetries,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        focusNode: _focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
            // Check if calibration is finished
            if (_isDone) {
              _startSession();
            } else {
              _capturePoint();
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            

            if (!_isCameraReady)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 24),
                        Text('Starting camera...',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                        SizedBox(height: 8),
                        Text('Please wait while the model initializes.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 200, height: 150,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_outlined, color: AppColors.primary, size: 32),
                    SizedBox(height: 8),
                    Text('Camera feed', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('(model connected)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),

            if (!_isDone)
              Positioned(
                top: 90,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GlowDot(color: AppColors.primary),
                          const SizedBox(width: 10),
                          const Text('Eye calibration',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Point ${_currentPoint + 1} of ${_gridNormalized.length}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Look at the dot, then press SPACE',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ).animate().fadeIn(),
              ),

            if (!_isDone)
              Stack(
                children: _gridNormalized.asMap().entries.map((e) {
                  final isActive  = e.key == _currentPoint;
                  final isDoneDot = e.key < _currentPoint;
                  final (nx, ny) = e.value; 
                  final double dotSize = isActive ? 40.0 : 16.0; 

                  return Positioned(
                    left: (nx * size.width) - (dotSize / 2),
                    top: (ny * size.height) - (dotSize / 2),
                    child: GestureDetector(
                      onTap: isActive ? _capturePoint : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDoneDot 
                              ? AppColors.success 
                              : isActive 
                                  ? (_isCollecting ? AppColors.warning : AppColors.primary) 
                                  : AppColors.textMuted.withOpacity(0.3),
                          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 20, spreadRadius: 4)] : null,
                        ),
                        child: isDoneDot ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),

            if (!_isDone)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text('Calibrating ${_currentPoint}/${_gridNormalized.length} points',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 300,
                      child: LinearProgressIndicator(
                        value: _currentPoint / _gridNormalized.length,
                        backgroundColor: AppColors.surfaceBorder,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

            if (_isDone)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [BoxShadow(color: AppColors.primaryGlow, blurRadius: 30)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryDim),
                        child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 40),
                      ).animate().scale(delay: 100.ms),
                      const SizedBox(height: 24),
                      Text('Calibration complete!',
                        style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      Text('Eye tracking is ready for ${widget.child.name}.\nThe session will begin when you click start.',
                        textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _currentPoint = 0;
                              _isDone = false;
                              _collectedPoints.clear();
                              _focusNode.requestFocus();
                            }),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Recalibrate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.surfaceBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _startSession,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start session'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),

              Positioned(
          top: 20,
          left: 20,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
              onPressed: () {
                _bridge.stop();
                context.pop();
              },
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gazeSub?.cancel();
    _focusNode.dispose();
    super.dispose();
  }
}


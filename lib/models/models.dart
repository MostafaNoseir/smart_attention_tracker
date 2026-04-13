import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// ─── Organization ──────────────────────────────────────────────
class Organization {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── Child Profile ──────────────────────────────────────────────
class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String? notes;
  final bool wearsGlasses;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.notes,
    this.wearsGlasses = false,
    required this.createdAt,
  });

  factory ChildProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChildProfile(
      id: doc.id,
      name: d['name'] ?? '',
      age: d['age'] ?? 6,
      notes: d['notes'],
      wearsGlasses: d['wearsGlasses'] ?? false,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'age': age,
    'notes': notes,
    'wearsGlasses': wearsGlasses,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// ─── Session Config ─────────────────────────────────────────────
enum TargetShape { rocket, car, dinosaur, robot, star }
enum DistractorType { none, colorFlash, sideMotion, shapeAppear, soundPulse }
enum SessionDuration { half, one, oneAndHalf, two }
enum MovementSpeed { slow, medium, fast }

extension TargetShapeExt on TargetShape {
  String get label => switch (this) {
    TargetShape.rocket   => 'Rocket',
    TargetShape.car      => 'Race Car',
    TargetShape.dinosaur => 'Dinosaur',
    TargetShape.robot    => 'Robot',
    TargetShape.star     => 'Star',
  };
  String get emoji => switch (this) {
    TargetShape.rocket   => '🚀',
    TargetShape.car      => '🏎️',
    TargetShape.dinosaur => '🦖',
    TargetShape.robot    => '🤖',
    TargetShape.star     => '⭐',
  };
}

extension DistractorTypeExt on DistractorType {
  String get label => switch (this) {
    DistractorType.none        => 'No distractors',
    DistractorType.colorFlash  => 'Color flash',
    DistractorType.sideMotion  => 'Side motion',
    DistractorType.shapeAppear => 'Shape pop-up',
    DistractorType.soundPulse  => 'Sound pulse',
  };
  String get description => switch (this) {
    DistractorType.none        => 'Pure focus session',
    DistractorType.colorFlash  => 'Bright colors flash on screen edges',
    DistractorType.sideMotion  => 'Objects move at the screen sides',
    DistractorType.shapeAppear => 'Random shapes appear briefly',
    DistractorType.soundPulse  => 'Short sounds play at intervals',
  };
}


extension SessionDurationExt on SessionDuration {
  // بنحسبها بالثواني عشان الكسور
  int get seconds {
    switch (this) {
      case SessionDuration.half: return 30;
      case SessionDuration.one: return 60;
      case SessionDuration.oneAndHalf: return 90;
      case SessionDuration.two: return 120;
    }
  }

  String get label {
    switch (this) {
      case SessionDuration.half: return '30 sec';
      case SessionDuration.one: return '1 min';
      case SessionDuration.oneAndHalf: return '1.5 min';
      case SessionDuration.two: return '2 min';
    }
  }

  // دول عشان نعرضهم بشكل شيك في الزراير
  String get shortValue {
    switch (this) {
      case SessionDuration.half: return '30';
      case SessionDuration.one: return '1';
      case SessionDuration.oneAndHalf: return '1.5';
      case SessionDuration.two: return '2';
    }
  }

  String get shortUnit {
    switch (this) {
      case SessionDuration.half: return 'sec';
      default: return 'min';
    }
  }
}

extension MovementSpeedExt on MovementSpeed {
  String get label => switch (this) {
    MovementSpeed.slow   => 'Slow',
    MovementSpeed.medium => 'Medium',
    MovementSpeed.fast   => 'Fast',
  };
  double get pixelsPerSecond => switch (this) {
    MovementSpeed.slow   => 80,
    MovementSpeed.medium => 160,
    MovementSpeed.fast   => 280,
  };
}

class SessionConfig {
  final TargetShape targetShape;
  final int targetColorIndex;      // index into AppColors.targetColors
  final MovementSpeed speed;
  final DistractorType distractorType;
  final int distractorIntervalSeconds;  // how often distractors appear
  final SessionDuration duration;
  final bool enableSound;

  final String? musicPath; // مسار الملف في الجهاز (C:\Music\song.mp3)
  final String? musicName; // اسم الأغنية (song.mp3)

  SessionConfig({
    this.targetShape = TargetShape.rocket,
    this.targetColorIndex = 0,
    this.speed = MovementSpeed.medium,
    this.distractorType = DistractorType.colorFlash,
    this.distractorIntervalSeconds = 15,
    this.duration = SessionDuration.two,
    this.enableSound = false,
    this.musicPath,
    this.musicName,
  });

  SessionConfig copyWith({
    TargetShape? targetShape,
    int? targetColorIndex,
    MovementSpeed? speed,
    DistractorType? distractorType,
    int? distractorIntervalSeconds,
    SessionDuration? duration,
    bool? enableSound,
    String? musicPath,
    String? musicName,
    bool clearMusic = false,
  }) {
    return SessionConfig(
      targetShape: targetShape ?? this.targetShape,
      targetColorIndex: targetColorIndex ?? this.targetColorIndex,
      speed: speed ?? this.speed,
      distractorType: distractorType ?? this.distractorType,
      distractorIntervalSeconds: distractorIntervalSeconds ?? this.distractorIntervalSeconds,
      duration: duration ?? this.duration,
      enableSound: enableSound ?? this.enableSound,
      musicPath: clearMusic ? null : (musicPath ?? this.musicPath),
      musicName: clearMusic ? null : (musicName ?? this.musicName),
    );
  }

  Map<String, dynamic> toMap() => {
    'targetShape': targetShape.name,
    'targetColorIndex': targetColorIndex,
    'speed': speed.name,
    'distractorType': distractorType.name,
    'distractorIntervalSeconds': distractorIntervalSeconds,
    'durationMinutes': duration.seconds,
    'enableSound': enableSound,
    'musicName': musicName,
  };
}

// ─── Session Result ─────────────────────────────────────────────
class GazePoint {
  final double x;
  final double y;
  final double targetX;
  final double targetY;
  final bool isDistractorActive;
  final int timestampMs;
  final double screenWidth;
  final double screenHeight;

  GazePoint({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.isDistractorActive,
    required this.timestampMs,
    required this.screenWidth,
    required this.screenHeight,
  });

  double get distance {
    final dx = x - targetX;
    final dy = y - targetY;
    return sqrt(dx * dx + dy * dy);
  }

  // صاحبك كان حاطط ALLOWED_DIST = 250
  // bool get isOnTarget => distance <= 250;
// bool get isOnTarget {
//     if (x < 0 || y < 0) return false;

//     final originalDiagonal = math.sqrt(1920 * 1920 + 1080 * 1080);
//     final currentDiagonal = math.sqrt(
//       screenWidth * screenWidth + screenHeight * screenHeight,
//     );

//     final allowedDist = currentDiagonal * (250 / originalDiagonal);

//     return distance <= allowedDist;
//   }

bool get isOnTarget {
  if (x < 0 || y < 0) return false;
  
  final diagonal = sqrt(screenWidth * screenWidth + (screenWidth * 0.593) * (screenWidth * 0.593));
  final originalDiagonal = sqrt(1920 * 1920 + 1080 * 1080.0);
  final allowedDist = diagonal * (400 / originalDiagonal);
  
  return distance <= allowedDist;
}

// bool get isOnTarget {
//   if (x < 0 || y < 0) return false;
  
//   // Use ACTUAL screen dimensions instead of the 0.593 multiplier
//   final currentDiagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);
//   final originalDiagonal = sqrt(1920 * 1920 + 1080 * 1080.0);
//   final allowedDist = currentDiagonal * (350 / originalDiagonal);
  
//   return distance <= allowedDist;
// }

  // bool get isOnTarget {
  //   final dx = x - targetX;
  //   final dy = y - targetY;
  //   return (dx * dx + dy * dy) < (80 * 80); // 80px radius tolerance
  // }

  // List<dynamic> toCsvRow() => [
  //   timestampMs, x.toStringAsFixed(2), y.toStringAsFixed(2),
  //   targetX.toStringAsFixed(2), targetY.toStringAsFixed(2),
  //   isOnTarget ? 1 : 0, isDistractorActive ? 1 : 0,
  // ];
  List<dynamic> toCsvRow() {
    final timeSec = timestampMs / 1000.0;
    return [
      timeSec.toStringAsFixed(3),      // Time_Sec
      targetX.toInt(),                 // Target_X
      targetY.toInt(),                 // Target_Y
      x.toInt(),                       // Gaze_X
      y.toInt(),                       // Gaze_Y
      isDistractorActive ? 1 : 0,      // Distractor_Active
      distance.toStringAsFixed(2),     // Distance
      isOnTarget ? 1 : 0,              // Focus_Status
    ];
  }
}

class AttentionSpan {
  final int startMs;
  final int endMs;
  final bool isFocused;
  final bool hasDistractor;

  AttentionSpan({
    required this.startMs,
    required this.endMs,
    required this.isFocused,
    required this.hasDistractor,
  });

  int get durationMs => endMs - startMs;
  double get durationSeconds => durationMs / 1000.0;
}

class SessionResult {
  final String id;
  final String childId;
  final String childName;
  final SessionConfig config;
  final DateTime startTime;
  final DateTime endTime;
  final List<GazePoint> gazePoints;
  final List<AttentionSpan> attentionTimeline;
  final double? storedFocusPercentage;
  final double? storedDistractorResistance;
  final double? storedAvgRecoveryTime;
  final SessionMetrics? metrics;
  final String? tempVideoPath;

  SessionResult({
    required this.id,
    required this.childId,
    required this.childName,
    required this.config,
    required this.startTime,
    required this.endTime,
    required this.gazePoints,
    required this.attentionTimeline,
    this.storedFocusPercentage,
    this.storedDistractorResistance,
    this.storedAvgRecoveryTime,
    this.metrics,
    this.tempVideoPath,
  });

  int get durationSeconds => endTime.difference(startTime).inSeconds;

  double get focusPercentage {
    if (storedFocusPercentage != null) return storedFocusPercentage!;
    if (gazePoints.isEmpty) return 0;
    final focused = gazePoints.where((p) => p.isOnTarget).length;
    return (focused / gazePoints.length) * 100;
  }

  double get distractorResistance {
    if (storedDistractorResistance != null) return storedDistractorResistance!;
    final duringDistractor = gazePoints.where((p) => p.isDistractorActive).toList();
    if (duringDistractor.isEmpty) return 100;
    final stayed = duringDistractor.where((p) => p.isOnTarget).length;
    return (stayed / duringDistractor.length) * 100;
  }

  double get avgRecoveryTime {
    if (storedAvgRecoveryTime != null) return storedAvgRecoveryTime!;
    if (gazePoints.isEmpty) return 0.0;

    List<double> recoveryTimes = [];
    bool isRecovering = false;
    int recoveryStartMs = 0;

    for (var p in gazePoints) {
      if (p.isDistractorActive && !p.isOnTarget && !isRecovering) {
        isRecovering = true;
        recoveryStartMs = p.timestampMs;
      }
      if (isRecovering && p.isOnTarget) {
        double timeTaken = (p.timestampMs - recoveryStartMs) / 1000.0;
        recoveryTimes.add(timeTaken);
        isRecovering = false;
      }
    }

    if (recoveryTimes.isEmpty) return 0.0;
    return recoveryTimes.reduce((a, b) => a + b) / recoveryTimes.length;
  }

  int get distractorCount => gazePoints.where((p) => p.isDistractorActive).length;

  Map<String, dynamic> toFirestore() {
    final map = {
      'childId': childId,
      'childName': childName,
      'config': config.toMap(),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'focusPercentage': focusPercentage,
      'distractorResistance': distractorResistance,
      'avgRecoveryTime': avgRecoveryTime,
      'totalGazePoints': gazePoints.length,
    };
    if (metrics != null) {
      map['maxFocusStreak'] = metrics!.maxFocusStreak;
      map['fatigueIndex'] = metrics!.fatigueIndex;
      map['microDistractions'] = metrics!.microDistractions;
    }
    return map;
  }
}

class SessionMetrics {
  final double maxFocusStreak;
  final double fatigueIndex;
  final int microDistractions;

  SessionMetrics({
    required this.maxFocusStreak,
    required this.fatigueIndex,
    required this.microDistractions,
  });

  Map<String, dynamic> toMap() => {
    'maxFocusStreak': maxFocusStreak,
    'fatigueIndex': fatigueIndex,
    'microDistractions': microDistractions,
  };

  factory SessionMetrics.fromFirestore(Map<String, dynamic> data) {
    return SessionMetrics(
      maxFocusStreak: (data['maxFocusStreak'] as num?)?.toDouble() ?? 0.0,
      fatigueIndex: (data['fatigueIndex'] as num?)?.toDouble() ?? 0.0,
      microDistractions: (data['microDistractions'] as num?)?.toInt() ?? 0,
    );
  }
}

 
// ─── Calibration Data ─────────────────────────────────────────────
class CalibrationPoint {
  final double screenX;
  final double screenY;
  final List<Map<String, dynamic>> gazeSamples;

  CalibrationPoint({
    required this.screenX,
    required this.screenY,
    required this.gazeSamples,
  });

  Map<String, dynamic> toJson() => {
    'screen_x': screenX,
    'screen_y': screenY,
    'gaze_samples': gazeSamples,
  };
}

// ─── تعديل SessionResult (أضف الحقول الجديدة) ───────────────────────────── // new

SessionMetrics calculateSessionMetrics(List<GazePoint> points) {
  if (points.isEmpty) {
    return SessionMetrics(maxFocusStreak: 0, fatigueIndex: 0, microDistractions: 0);
  }

  points.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

  final startTime = points.first.timestampMs / 1000.0;
  final endTime = points.last.timestampMs / 1000.0;
  final totalDuration = endTime - startTime;
  if (totalDuration <= 0) return SessionMetrics(maxFocusStreak: 0, fatigueIndex: 0, microDistractions: 0);

  double maxStreak = 0;
  double currentStreak = 0;
  double lastFocusTime = 0;

  final halfTime = startTime + totalDuration / 2;
  double focusFirstHalf = 0;
  double focusSecondHalf = 0;

  int microCount = 0;
  bool wasFocused = points.first.isOnTarget;
  double distractionStart = 0;

  for (int i = 0; i < points.length; i++) {
    final p = points[i];
    final isFocused = p.isOnTarget;
    final timeSec = p.timestampMs / 1000.0;

    // 1. Max Focus Streak
    if (isFocused) {
      if (currentStreak == 0) lastFocusTime = timeSec;
      currentStreak = timeSec - lastFocusTime;
      if (currentStreak > maxStreak) maxStreak = currentStreak;
    } else {
      currentStreak = 0;
    }

    // 2. Fatigue Index
    final durationThisFrame = i == 0 ? 0 : (timeSec - (points[i-1].timestampMs / 1000.0));
    if (isFocused) {
      if (timeSec <= halfTime) focusFirstHalf += durationThisFrame;
      else focusSecondHalf += durationThisFrame;
    }

    // 3. Micro Distractions
    if (wasFocused && !isFocused) {
      distractionStart = timeSec;
    } else if (!wasFocused && isFocused && distractionStart > 0) {
      final distractionDuration = timeSec - distractionStart;
      if (distractionDuration > 0 && distractionDuration < 1.0) microCount++;
    }
    wasFocused = isFocused;
  }

  final firstRatio = focusFirstHalf / (totalDuration / 2);
  final secondRatio = focusSecondHalf / (totalDuration / 2);
  final fatigueIndex = firstRatio - secondRatio;   // > 0 = إرهاق

  return SessionMetrics(
    maxFocusStreak: maxStreak,
    fatigueIndex: fatigueIndex,
    microDistractions: microCount,
  );
}
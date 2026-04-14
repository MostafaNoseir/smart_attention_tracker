import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _orgId => FirebaseAuth.instance.currentUser!.uid;

  // ─── Children ───────────────────────────────────────────────
  CollectionReference get _children =>
      _db.collection('organizations').doc(_orgId).collection('children');

  Stream<List<ChildProfile>> watchChildren() {
    return _children
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChildProfile.fromFirestore).toList());
  }

  Future<ChildProfile> addChild(ChildProfile child) async {
    final doc = await _children.add(child.toFirestore());
    return ChildProfile(
      id: doc.id, name: child.name, age: child.age,
      notes: child.notes, wearsGlasses: child.wearsGlasses,
      createdAt: child.createdAt,
    );
  }

  Future<void> updateChild(ChildProfile child) async {
    await _children.doc(child.id).update(child.toFirestore());
  }

  Future<void> deleteChild(String childId) async {
    await _children.doc(childId).delete();
  }

  // ─── Sessions ────────────────────────────────────────────────
  CollectionReference get _sessions =>
      _db.collection('organizations').doc(_orgId).collection('sessions');

  Stream<List<SessionResult>> watchSessions({String? childId}) {
    Query q = _sessions.orderBy('startTime', descending: true);
    if (childId != null) q = q.where('childId', isEqualTo: childId);
    return q.snapshots().map((s) => s.docs.map(_sessionFromDoc).toList());
  }

  // Future<String> saveSession(SessionResult result) async {
  //   final doc = await _sessions.add(result.toFirestore());
  //   return doc.id;
  // }

  Future<String> saveSession(SessionResult result) async {
    // 🚨 Use .doc(result.id).set() so Firebase uses your pre-generated ID!
    await _sessions.doc(result.id).set(result.toFirestore());
    return result.id;
  }

  SessionResult _sessionFromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SessionResult(
      id: doc.id,
      childId: d['childId'] ?? '',
      childName: d['childName'] ?? '',
      config: SessionConfig(),
      startTime: (d['startTime'] as Timestamp).toDate(),
      endTime: (d['endTime'] as Timestamp).toDate(),
      gazePoints: [],
      attentionTimeline: [],
      storedFocusPercentage: (d['focusPercentage'] as num?)?.toDouble() ?? 0.0,
      storedDistractorResistance: (d['distractorResistance'] as num?)?.toDouble() ?? 0.0,
      storedAvgRecoveryTime: (d['avgRecoveryTime'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─── CSV Export ──────────────────────────────────────────────
  // Future<File> exportCsv(SessionResult result) async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final timestamp = result.startTime.millisecondsSinceEpoch;
  //   final file = File('${dir.path}/session_${result.childName}_$timestamp.csv');

  //   final rows = [
  //     ['timestamp_ms', 'gaze_x', 'gaze_y', 'target_x', 'target_y', 'on_target', 'distractor_active'],
  //     ...result.gazePoints.map((p) => p.toCsvRow()),
  //   ];

  //   final csvContent = rows.map((r) => r.join(',')).join('\n');
  //   await file.writeAsString(csvContent);
  //   return file;
  // }

  // ─── CSV Export ──────────────────────────────────────────────
  // ─── CSV Export ──────────────────────────────────────────────
  // Future<File> exportCsv(SessionResult result) async {
  //   final dir = await getApplicationDocumentsDirectory();
    
  //   // تنسيق اسم الملف
  //   final sessionTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(result.startTime);
  //   final file = File('${dir.path}/Session_${result.childName}_$sessionTime.csv');

  //   // تحديد حالة الجلسة (ممكن تطورها بعدين لو الجلسة فشلت)
  //   final statusText = "Completed";

  //   final avgRec = result.avgRecoveryTime;
  //   final recoveryText = avgRec > 0 ? "${avgRec.toStringAsFixed(2)}s" : "Perfect (No Distractions)";

  //   // الهيدر + الداتا + الخاتمة (تطابق 100% مع كود صاحبك)
  //   final rows = [
  //     // 1. الهيدر
  //     ["Time_Sec", "Target_X", "Target_Y", "Gaze_X", "Gaze_Y", "Distractor_Active", "Distance", "Focus_Status"],
      
  //     // 2. الداتا الخام (آلاف السطور)
  //     ...result.gazePoints.map((p) => p.toCsvRow()),
      
  //     // 3. الخاتمة
  //     [], // سطر فاضي
  //     ["---", "---", "---", "---", "---", "---", "---", "---"],
  //     [
  //       "SESSION_SUMMARY", 
  //       "Status: $statusText", 
  //       "Final_Focus: ${result.focusPercentage.toStringAsFixed(1)}%", 
  //       "Avg_Recovery: $recoveryText",
  //       "", "", "", ""
  //     ]
  //   ];

  //   final csvContent = rows.map((r) => r.join(',')).join('\n');
  //   await file.writeAsString(csvContent);
  //   return file;
  // }

  // Future<void> exportCsv(SessionResult result) async {
  //   // 1. Prepare the CSV content (Logic remains the same)
  //   final sessionTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(result.startTime);
  //   final fileName = 'Session_${result.childName}_$sessionTime.csv';

  //   final avgRec = result.avgRecoveryTime;
  //   final recoveryText = avgRec > 0 ? "${avgRec.toStringAsFixed(2)}s" : "Perfect (No Distractions)";

  //   final rows = [
  //     ["Time_Sec", "Target_X", "Target_Y", "Gaze_X", "Gaze_Y", "Distractor_Active", "Distance", "Focus_Status"],
  //     ...result.gazePoints.map((p) => p.toCsvRow()),
  //     [], 
  //     ["---", "---", "---", "---", "---", "---", "---", "---"],
  //     [
  //       "SESSION_SUMMARY", 
  //       "Status: Completed", 
  //       "Final_Focus: ${result.focusPercentage.toStringAsFixed(1)}%", 
  //       "Avg_Recovery: $recoveryText",
  //     ]
  //   ];

  //   final csvContent = rows.map((r) => r.join(',')).join('\n');

  //   // 2. Open Save File Dialog
  //   String? outputFile = await FilePicker.platform.saveFile(
  //     dialogTitle: 'Please select where to save your report:',
  //     fileName: fileName,
  //     type: FileType.custom,
  //     allowedExtensions: ['csv'],
  //     bytes: Stream.fromIterable(csvContent.codeUnits).toList() as dynamic, // Optional for web
  //   );

  //   // 3. Write the file if the user didn't cancel
  //   if (outputFile != null) {
  //     final file = File(outputFile);
  //     await file.writeAsString(csvContent);
  //   } else {
  //     // User canceled the picker
  //     throw Exception("Export cancelled");
  //   }
  // }

  Future<void> exportCsv(SessionResult result) async {
    final sessionTime = DateFormat('yyyy-MM-dd_HH-mm-ss').format(result.startTime);
    final fileName = 'Session_${result.childName}_$sessionTime.csv';

    final avgRec = result.avgRecoveryTime;
    final recoveryText = avgRec > 0 ? "${avgRec.toStringAsFixed(2)}s" : "Perfect (No Distractions)";

    final rows = [
      ["Time_Sec", "Target_X", "Target_Y", "Gaze_X", "Gaze_Y", "Distractor_Active", "Distance", "Focus_Status"],
      ...result.gazePoints.map((p) => p.toCsvRow()),
      [], 
      ["---", "---", "---", "---", "---", "---", "---", "---"],
      [
        "SESSION_SUMMARY", 
        "Status: Completed", 
        "Final_Focus: ${result.focusPercentage.toStringAsFixed(1)}%", 
        "Avg_Recovery: $recoveryText",
      ]
    ];

    // Append advanced metrics to the summary (always include - calculate if missing)
    final m = result.metrics ?? calculateSessionMetrics(result.gazePoints);
    rows.add(['', '', '', '']); // فاصل
    rows.add(['Max Focus Streak (s)', m.maxFocusStreak.toStringAsFixed(2), '', '']);
    rows.add(['Fatigue Index', m.fatigueIndex.toStringAsFixed(3), '', '']);
    rows.add(['Micro Distractions', m.microDistractions.toString(), '', '']);

    final csvContent = rows.map((r) => r.join(',')).join('\n');
    
    // Convert the string to a Uint8List synchronously
    final Uint8List fileBytes = Uint8List.fromList(utf8.encode(csvContent));

    // Open Save File Dialog
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select where to save your report:',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: fileBytes, // This is now a clean Uint8List
    );

    // Write the file if the user didn't cancel
    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(csvContent);
    } else {
      throw Exception("Export cancelled");
    }
  }
<<<<<<< Updated upstream
=======

  // Note: temporary session videos are kept local only and are not uploaded
  // to Firebase Storage. The app will not write video file paths into Firestore.
>>>>>>> Stashed changes
}
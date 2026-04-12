import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class MusicTrack {
  final String name;
  final String path;

  MusicTrack({required this.name, required this.path});

  Map<String, dynamic> toJson() => {'name': name, 'path': path};
  factory MusicTrack.fromJson(Map<String, dynamic> json) => 
      MusicTrack(name: json['name'], path: json['path']);
}

class MusicNotifier extends StateNotifier<List<MusicTrack>> {
  MusicNotifier() : super([]) {
    _loadMusic();
  }

  // تحميل الأغاني المحفوظة
  Future<void> _loadMusic() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('saved_music') ?? [];
    state = data.map((e) => MusicTrack.fromJson(jsonDecode(e))).toList();
  }

  // اختيار وإضافة أغنية جديدة من الجهاز
  Future<void> addMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final newTrack = MusicTrack(
        name: result.files.single.name,
        path: result.files.single.path!,
      );
      
      // نتأكد إنها مش متضافة قبل كده
      if (!state.any((track) => track.path == newTrack.path)) {
        state = [...state, newTrack];
        _saveMusic();
      }
    }
  }

  // مسح أغنية من المكتبة
  Future<void> removeMusic(String path) async {
    state = state.where((track) => track.path != path).toList();
    _saveMusic();
  }

  // حفظ التعديلات في الهارد
  Future<void> _saveMusic() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((e) => jsonEncode(e.toJson())).toList();
    prefs.setStringList('saved_music', data);
  }
}

final musicProvider = StateNotifierProvider<MusicNotifier, List<MusicTrack>>((ref) {
  return MusicNotifier();
});
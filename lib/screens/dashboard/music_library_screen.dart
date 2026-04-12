import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eye_focus/services/music_provider.dart';
import '../../theme/app_theme.dart';

class MusicLibraryScreen extends ConsumerWidget {
  const MusicLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicList = ref.watch(musicProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Music Library'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saved Audio Files', style: Theme.of(context).textTheme.headlineMedium),
                ElevatedButton.icon(
                  onPressed: () => ref.read(musicProvider.notifier).addMusic(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Music'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Add relaxing music or kids songs to use during sessions.',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            
            Expanded(
              child: musicList.isEmpty
                  ? const Center(
                      child: Text('No music added yet. Click "Add Music" to browse files.',
                          style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.separated(
                      itemCount: musicList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final track = musicList[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.music_note_rounded, color: AppColors.primary),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(track.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text(track.path, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                onPressed: () => ref.read(musicProvider.notifier).removeMusic(track.path),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
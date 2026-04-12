import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eye_focus/services/music_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';


class SessionSetupScreen extends ConsumerStatefulWidget {
  final ChildProfile? preselectedChild;
  const SessionSetupScreen({super.key, this.preselectedChild});

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  final _service = FirestoreService();

  ChildProfile? _selectedChild;
  SessionConfig _config = SessionConfig();

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.preselectedChild;
  }

  void _proceed() {
    if (_selectedChild == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a child first'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    context.push('/session/calibration', extra: {
      'child': _selectedChild!,
      'config': _config,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Session setup'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: ElevatedButton.icon(
              onPressed: _proceed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Start calibration'),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Child selector ─────────────────────────────
          SizedBox(
            width: 280,
            child: Container(
              height: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select child', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Who is this session for?',
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<ChildProfile>>(
                      stream: _service.watchChildren(),
                      builder: (context, snapshot) {
                        final children = snapshot.data ?? [];
                        if (children.isEmpty) {
                          return EmptyState(
                            title: 'No children',
                            message: 'Add a child profile first',
                            icon: Icons.child_care_rounded,
                            action: TextButton(
                              onPressed: () => context.push('/children'),
                              child: const Text('Add child',
                                style: TextStyle(color: AppColors.primary)),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: children.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final child = children[i];
                            final isSelected = _selectedChild?.id == child.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedChild = child),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primaryDim : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                    width: isSelected ? 1.5 : 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                      ),
                                      child: Center(
                                        child: Text(
                                          child.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: isSelected ? AppColors.background : AppColors.textSecondary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(child.name,
                                            style: TextStyle(
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            )),
                                          Text('Age ${child.age}${child.wearsGlasses ? ' · 👓' : ''}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right: Config panels ─────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Session configuration',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(),
                  const SizedBox(height: 6),
                  Text('Customize the session parameters',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fadeIn(delay: 80.ms),

                  const SizedBox(height: 32),

                  // ── Target shape ─────────────────────────────
                  _ConfigSection(
                    title: 'Target shape',
                    subtitle: 'The object the child should follow',
                    icon: Icons.category_outlined,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: TargetShape.values.map((shape) {
                        final selected = _config.targetShape == shape;
                        return GestureDetector(
                          onTap: () => setState(() =>
                            _config = _config.copyWith(targetShape: shape)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 90,
                            height: 80,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryDim : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AppColors.primary : AppColors.surfaceBorder,
                                width: selected ? 1.5 : 0.8,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(shape.emoji,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: selected ? AppColors.primary : AppColors.textSecondary,
                                  )),
                                const SizedBox(height: 6),
                                Text(shape.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: selected ? AppColors.primary : AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 120.ms),

                  const SizedBox(height: 20),

                  // ── Target color ─────────────────────────────
                  // _ConfigSection(
                  //   title: 'Target color',
                  //   subtitle: 'Color of the moving target',
                  //   icon: Icons.palette_outlined,
                  //   child: Wrap(
                  //     spacing: 10,
                  //     runSpacing: 10,
                  //     children: AppColors.targetColors.asMap().entries.map((e) {
                  //       final selected = _config.targetColorIndex == e.key;
                  //       return GestureDetector(
                  //         onTap: () => setState(() =>
                  //           _config = _config.copyWith(targetColorIndex: e.key)),
                  //         child: AnimatedContainer(
                  //           duration: const Duration(milliseconds: 150),
                  //           width: 44,
                  //           height: 44,
                  //           decoration: BoxDecoration(
                  //             color: e.value,
                  //             shape: BoxShape.circle,
                  //             border: Border.all(
                  //               color: selected ? Colors.white : Colors.transparent,
                  //               width: 2.5,
                  //             ),
                  //             boxShadow: selected
                  //                 ? [BoxShadow(color: e.value.withOpacity(0.5), blurRadius: 8)]
                  //                 : null,
                  //           ),
                  //           child: selected
                  //               ? const Icon(Icons.check, color: Colors.white, size: 20)
                  //               : null,
                  //         ),
                  //       );
                  //     }).toList(),
                  //   ),
                  // ).animate().fadeIn(delay: 160.ms),

                  const SizedBox(height: 20),

                  // ── Movement speed ───────────────────────────
                  _ConfigSection(
                    title: 'Movement speed',
                    subtitle: 'How fast the target moves around the screen',
                    icon: Icons.speed_rounded,
                    child: Row(
                      children: MovementSpeed.values.map((speed) {
                        final selected = _config.speed == speed;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: speed != MovementSpeed.fast ? 12 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                _config = _config.copyWith(speed: speed)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryDim : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.surfaceBorder,
                                    width: selected ? 1.5 : 0.8,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      speed == MovementSpeed.slow
                                        ? Icons.directions_walk_rounded
                                        : speed == MovementSpeed.medium
                                          ? Icons.directions_run_rounded
                                          : Icons.flash_on_rounded,
                                      color: selected ? AppColors.primary : AppColors.textMuted,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(speed.label,
                                      style: TextStyle(
                                        color: selected ? AppColors.primary : AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 20),

                  // ── Session duration ─────────────────────────
                  // _ConfigSection(
                  //   title: 'Session duration',
                  //   subtitle: 'How long the tracking session lasts',
                  //   icon: Icons.timer_outlined,
                  //   child: Row(
                  //     children: SessionDuration.values.map((dur) {
                  //       final selected = _config.duration == dur;
                  //       return Expanded(
                  //         child: Padding(
                  //           padding: EdgeInsets.only(
                  //             right: dur != SessionDuration.twenty ? 12 : 0),
                  //           child: GestureDetector(
                  //             onTap: () => setState(() =>
                  //               _config = _config.copyWith(duration: dur)),
                  //             child: AnimatedContainer(
                  //               duration: const Duration(milliseconds: 150),
                  //               padding: const EdgeInsets.symmetric(vertical: 16),
                  //               decoration: BoxDecoration(
                  //                 color: selected ? AppColors.primaryDim : AppColors.surfaceElevated,
                  //                 borderRadius: BorderRadius.circular(12),
                  //                 border: Border.all(
                  //                   color: selected ? AppColors.primary : AppColors.surfaceBorder,
                  //                   width: selected ? 1.5 : 0.8,
                  //                 ),
                  //               ),
                  //               child: Column(
                  //                 children: [
                  //                   Text('${dur.minutes}',
                  //                     style: TextStyle(
                  //                       fontSize: 28,
                  //                       fontWeight: FontWeight.w700,
                  //                       color: selected ? AppColors.primary : AppColors.textSecondary,
                  //                     )),
                  //                   Text('min',
                  //                     style: TextStyle(
                  //                       fontSize: 12,
                  //                       color: selected ? AppColors.primary.withOpacity(0.7) : AppColors.textMuted,
                  //                     )),
                  //                 ],
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       );
                  //     }).toList(),
                  //   ),
                  // ).animate().fadeIn(delay: 240.ms),

                  // ── Session duration (Fixed to 2 min for now) ─────────
                  // ── Session duration ─────────────────────────
                  _ConfigSection(
                    title: 'Session duration',
                    subtitle: 'How long the tracking session lasts',
                    icon: Icons.timer_outlined,
                    child: Row(
                      children: SessionDuration.values.map((dur) {
                        final selected = _config.duration == dur;
                        return Expanded(
                          child: Padding(
                            // قللنا المسافة شوية عشان الـ 4 زراير يكفوا الشاشة
                            padding: EdgeInsets.only(
                              right: dur != SessionDuration.two ? 8 : 0), 
                            child: GestureDetector(
                              onTap: () => setState(() =>
                                _config = _config.copyWith(duration: dur)),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primaryDim : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.surfaceBorder,
                                    width: selected ? 1.5 : 0.8,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(dur.shortValue, 
                                      style: TextStyle(
                                        fontSize: 22, 
                                        fontWeight: FontWeight.w700,
                                        color: selected ? AppColors.primary : AppColors.textSecondary,
                                      )),
                                    const SizedBox(height: 2),
                                    Text(dur.shortUnit, 
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: selected ? AppColors.primary.withOpacity(0.7) : AppColors.textMuted,
                                      )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate().fadeIn(delay: 240.ms),

                  const SizedBox(height: 20),

                  // ── Background Music ─────────────────────────
                  _ConfigSection(
                    title: 'Background music',
                    subtitle: 'Select from your music library',
                    icon: Icons.library_music_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            // استخدام الـ Provider لقراءة الأغاني المحفوظة
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _config.musicPath,
                                hint: const Text('None (Silent)', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                                isExpanded: true,
                                dropdownColor: AppColors.surfaceElevated,
                                icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMuted),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('None (Silent)', style: TextStyle(color: AppColors.textPrimary)),
                                  ),
                                  // بناء عناصر القائمة من الأغاني المحفوظة
                                  ...ref.watch(musicProvider).map((track) {
                                    return DropdownMenuItem(
                                      value: track.path,
                                      child: Text(track.name, style: const TextStyle(color: AppColors.textPrimary)),
                                    );
                                  }),
                                ],
                                onChanged: (path) {
                                  if (path == null) {
                                    setState(() => _config = _config.copyWith(clearMusic: true));
                                  } else {
                                    final name = ref.read(musicProvider).firstWhere((m) => m.path == path).name;
                                    setState(() => _config = _config.copyWith(musicPath: path, musicName: name));
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // زرار يودي شاشة إضافة الأغاني لو عايز يضيف حاجة جديدة
                        IconButton(
                          onPressed: () => context.push('/music-library'),
                          icon: const Icon(Icons.settings_rounded, color: AppColors.textMuted),
                          tooltip: 'Manage Music Library',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 260.ms),

                  const SizedBox(height: 20),

                  

                  // ── Distractors ──────────────────────────────
                  // _ConfigSection(
                  //   title: 'Distractor type',
                  //   subtitle: 'Visual stimuli used to test attention resistance',
                  //   icon: Icons.warning_amber_rounded,
                  //   child: Column(
                  //     children: DistractorType.values.map((type) {
                  //       final selected = _config.distractorType == type;
                  //       return Padding(
                  //         padding: const EdgeInsets.only(bottom: 8),
                  //         child: GestureDetector(
                  //           onTap: () => setState(() =>
                  //             _config = _config.copyWith(distractorType: type)),
                  //           child: AnimatedContainer(
                  //             duration: const Duration(milliseconds: 150),
                  //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  //             decoration: BoxDecoration(
                  //               color: selected ? AppColors.warningDim : AppColors.surfaceElevated,
                  //               borderRadius: BorderRadius.circular(12),
                  //               border: Border.all(
                  //                 color: selected ? AppColors.warning : AppColors.surfaceBorder,
                  //                 width: selected ? 1.5 : 0.8,
                  //               ),
                  //             ),
                  //             child: Row(
                  //               children: [
                  //                 Icon(
                  //                   type == DistractorType.none ? Icons.do_not_disturb_alt_rounded :
                  //                   type == DistractorType.colorFlash ? Icons.flash_on_rounded :
                  //                   type == DistractorType.sideMotion ? Icons.swap_horiz_rounded :
                  //                   type == DistractorType.shapeAppear ? Icons.add_circle_outline_rounded :
                  //                   Icons.volume_up_rounded,
                  //                   color: selected ? AppColors.warning : AppColors.textMuted,
                  //                   size: 20,
                  //                 ),
                  //                 const SizedBox(width: 14),
                  //                 Expanded(
                  //                   child: Column(
                  //                     crossAxisAlignment: CrossAxisAlignment.start,
                  //                     children: [
                  //                       Text(type.label,
                  //                         style: TextStyle(
                  //                           color: selected ? AppColors.warning : AppColors.textPrimary,
                  //                           fontWeight: FontWeight.w600,
                  //                           fontSize: 14,
                  //                         )),
                  //                       const SizedBox(height: 2),
                  //                       Text(type.description,
                  //                         style: const TextStyle(
                  //                           color: AppColors.textMuted, fontSize: 12)),
                  //                     ],
                  //                   ),
                  //                 ),
                  //                 if (selected)
                  //                   const Icon(Icons.check_circle_rounded,
                  //                     color: AppColors.warning, size: 20),
                  //               ],
                  //             ),
                  //           ),
                  //         ),
                  //       );
                  //     }).toList(),
                  //   ),
                  // ).animate().fadeIn(delay: 280.ms),

                  // ── Distractor interval ──────────────────────
                  // if (_config.distractorType != DistractorType.none) ...[
                  //   const SizedBox(height: 20),
                  //   _ConfigSection(
                  //     title: 'Distractor frequency',
                  //     subtitle: 'How often distractors appear (every X seconds)',
                  //     icon: Icons.schedule_rounded,
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Slider(
                  //           value: _config.distractorIntervalSeconds.toDouble(),
                  //           min: 5,
                  //           max: 60,
                  //           divisions: 11,
                  //           activeColor: AppColors.warning,
                  //           inactiveColor: AppColors.surfaceBorder,
                  //           label: 'Every ${_config.distractorIntervalSeconds}s',
                  //           onChanged: (v) => setState(() =>
                  //             _config = _config.copyWith(distractorIntervalSeconds: v.round())),
                  //         ),
                  //         Padding(
                  //           padding: const EdgeInsets.symmetric(horizontal: 12),
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //             children: [
                  //               const Text('Every 5s', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  //               Text('Every ${_config.distractorIntervalSeconds}s',
                  //                 style: const TextStyle(color: AppColors.warning,
                  //                   fontWeight: FontWeight.w600, fontSize: 13)),
                  //               const Text('Every 60s', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  //             ],
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ).animate().fadeIn(delay: 300.ms),
                  // ],

                  const SizedBox(height: 40),

                  // ── Summary card ─────────────────────────────
                  _SessionSummaryCard(
                    child: _selectedChild,
                    config: _config,
                    onStart: _proceed,
                  ).animate().fadeIn(delay: 320.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Config Section Wrapper ──────────────────────────────────────
class _ConfigSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ConfigSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryDim,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Session Summary Card ────────────────────────────────────────
class _SessionSummaryCard extends StatelessWidget {
  final ChildProfile? child;
  final SessionConfig config;
  final VoidCallback onStart;

  const _SessionSummaryCard({
    required this.child,
    required this.config,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceElevated,
      highlighted: child != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('Session summary', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _SummaryRow('Child', child?.name ?? 'Not selected', child == null ? AppColors.danger : null),
          _SummaryRow('Target', '${config.targetShape.emoji} ${config.targetShape.label}', null),
          // _SummaryRow('Speed', config.speed.label, null),
          _SummaryRow('Duration', config.duration.label, null),
          // _SummaryRow(
          //   'Distractors',
          //   config.distractorType == DistractorType.none
          //       ? 'None'
          //       : '${config.distractorType.label} every ${config.distractorIntervalSeconds}s',
          //   null,
          // ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: child != null ? onStart : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start calibration →'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (child == null) ...[
            const SizedBox(height: 10),
            const Center(
              child: Text('Select a child from the left panel to continue',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          Text(value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }
}
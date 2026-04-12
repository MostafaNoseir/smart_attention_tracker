import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   final _firestoreService = FirestoreService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Row(
//         children: [
//           // ── Sidebar ──────────────────────────────────────────
//           _Sidebar(),
//           // ── Main content ─────────────────────────────────────
//           Expanded(
//             child: Column(
//               children: [
//                 _TopBar(),
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(32),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // _StatsRow(),
//                         const SizedBox(height: 32),
//                         _RecentSessions(service: _firestoreService),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ─── New Statistics and Charts ───
                        _DashboardAnalytics(service: _firestoreService),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Analytics Widget ─────────────────────────────────────────────
class _DashboardAnalytics extends StatelessWidget {
  final FirestoreService service;
  const _DashboardAnalytics({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChildProfile>>(
      stream: service.watchChildren(),
      builder: (context, childrenSnapshot) {
        return StreamBuilder<List<SessionResult>>(
          stream: service.watchSessions(),
          builder: (context, sessionsSnapshot) {
            if (childrenSnapshot.connectionState == ConnectionState.waiting ||
                sessionsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            final children = childrenSnapshot.data ?? [];
            final sessions = sessionsSnapshot.data ?? [];

            // 1. Total number of children
            final totalChildren = children.length;

            // 2. Calculate the percentage of children needing attention (average focus < 60%)
            int problemCount = 0;
            for (var child in children) {
              final childSessions = sessions
                  .where((s) => s.childId == child.id)
                  .toList();
              if (childSessions.isNotEmpty) {
                final maxFocus = childSessions.fold(
                  0.0,
                  (max, s) => s.focusPercentage > max ? s.focusPercentage : max,
                );
                if (maxFocus < 60.0) problemCount++;
              }
            }
            final problemPercentage = totalChildren == 0
                ? 0.0
                : (problemCount / totalChildren) * 100;

            // 3. Prepare data for the age chart
            final ageCounts = <int, int>{};
            for (var child in children) {
              ageCounts[child.age] = (ageCounts[child.age] ?? 0) + 1;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Cards
                Row(
                  children: [
                    _StatCard(
                      title: 'Total Children',
                      value: '$totalChildren',
                      icon: Icons.child_care_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 16),
                    _StatCard(
                      title: 'Needs Attention',
                      subtitle: 'Avg Focus < 60%',
                      value: '${problemPercentage.toStringAsFixed(1)}%',
                      icon: Icons.warning_amber_rounded,
                      color: problemPercentage > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Chart
                const Text(
                  'Age Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _AgeDistributionChart(ageCounts: ageCounts),
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().scale(),
    );
  }
}

// ─── Simple Bar Chart for Ages ─────────────────────────────────────
class _AgeDistributionChart extends StatelessWidget {
  final Map<int, int> ageCounts;
  const _AgeDistributionChart({required this.ageCounts});

  @override
  Widget build(BuildContext context) {
    if (ageCounts.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('No age data available yet')),
      );
    }

    final maxCount = ageCounts.values.reduce(max);
    final sortedAges = ageCounts.keys.toList()..sort();

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sortedAges.map((age) {
          final count = ageCounts[age]!;
          final heightFactor = count / maxCount;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: max(10, 150 * heightFactor), // 150 is max bar height
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Age $age',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ... [احتفظ بباقي الكلاسات زي _Sidebar و _TopBar بدون تغيير] ...

// ─── Sidebar ─────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_outlined,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EyeFocus',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            _NavItem(
              icon: Icons.grid_view_rounded,
              label: 'Dashboard',
              active: true,
              onTap: () {},
            ),
            _NavItem(
              icon: Icons.child_care_rounded,
              label: 'Children',
              onTap: () => context.push('/children'),
            ),
            _NavItem(
              icon: Icons.play_circle_outline_rounded,
              label: 'New session',
              onTap: () => context.push('/session/setup'),
            ),

            _NavItem(
              icon: Icons.music_note_rounded,
              label: 'Music Library',
              onTap: () => context.push('/music-library'),
            ),

            const Spacer(),

            const Divider(),
            const SizedBox(height: 8),

            _NavItem(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              },
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryDim : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: active
              ? AppColors.primary
              : (color ?? AppColors.textSecondary),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active
                ? AppColors.primary
                : (color ?? AppColors.textSecondary),
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.push('/session/setup'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New session'),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'Total sessions',
        '24',
        AppColors.primary,
        Icons.play_circle_outline_rounded,
      ),
      ('Children tracked', '8', AppColors.accent, Icons.child_care_rounded),
      ('Avg focus rate', '72%', AppColors.success, Icons.track_changes_rounded),
      ('This week', '6', AppColors.warning, Icons.calendar_today_outlined),
    ];
    return Row(
      children: stats
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: e.key < stats.length - 1 ? 16 : 0,
                ),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: e.value.$3.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(e.value.$4, color: e.value.$3, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.$2,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: e.value.$3,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            e.value.$1,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (e.key * 80).ms).slideY(begin: 0.1),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Recent Sessions ─────────────────────────────────────────────
class _RecentSessions extends StatelessWidget {
  final FirestoreService service;
  const _RecentSessions({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent sessions',
          subtitle: 'Click a session to view results',
          trailing: TextButton(
            onPressed: () {
              context.push('/sessions');
            },
            child: const Text(
              'View all',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<SessionResult>>(
          stream: service.watchSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return EmptyState(
                title: 'No sessions yet',
                message: 'Start a new session to begin tracking attention.',
                icon: Icons.play_circle_outline_rounded,
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/session/setup'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Start first session'),
                ),
              );
            }
            return Column(
              children: sessions
                  .take(10)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SessionCard(
                        session: e.value,
                      ).animate().fadeIn(delay: (e.key * 60).ms),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionResult session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy · HH:mm');
    final focusPct = session.focusPercentage;
    final focusColor = focusPct >= 70
        ? AppColors.success
        : focusPct >= 45
        ? AppColors.warning
        : AppColors.danger;

    return AppCard(
      onTap: () => context.push('/results/${session.id}', extra: session),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.childName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.format(session.startTime),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          // Focus rate badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: focusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: focusColor.withOpacity(0.3)),
            ),
            child: Text(
              '${focusPct.toStringAsFixed(0)}% focus',
              style: TextStyle(
                color: focusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

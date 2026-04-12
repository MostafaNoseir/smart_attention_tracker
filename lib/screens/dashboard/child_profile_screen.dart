import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';

class ChildProfileScreen extends StatelessWidget {
  final ChildProfile child;
  const ChildProfileScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('${child.name} Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Child Information ──
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        child.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Age: ${child.age} years',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (child.wearsGlasses)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Wears glasses',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (child.notes != null && child.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notes: ${child.notes}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/session/setup', extra: child),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start New Session'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Child Sessions ──
            const Text(
              'Previous Tracking Sessions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<SessionResult>>(
              stream: service.watchSessions(childId: child.id),
              builder: (context, snapshot) {
                // 1. If there's an error, we print it to see the Firebase link
                if (snapshot.hasError) {
                  print(
                    "Firebase Error: ${snapshot.error}",
                  ); // Will print in the console
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: SelectableText(
                      'An error occurred (Index might be needed):\n${snapshot.error}',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  // ✅ CORRECT: Use Padding widget inside or outside Center
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No sessions recorded for this child yet.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: sessions.asMap().entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChildSessionCard(
                        session: e.value,
                      ).animate().fadeIn(delay: (e.key * 50).ms),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// class _ChildSessionCard extends StatelessWidget {
//   final SessionResult session;
//   const _ChildSessionCard({required this.session});

//   @override
//   Widget build(BuildContext context) {
//     final fmt = DateFormat('MMM d, yyyy · HH:mm');
//     final focusPct = session.focusPercentage;
//     final focusColor = focusPct >= 70
//         ? AppColors.success
//         : focusPct >= 45
//         ? AppColors.warning
//         : AppColors.danger;

//     return AppCard(
//       onTap: () => context.push('/results/${session.id}', extra: session),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.history_rounded,
//             color: AppColors.textMuted,
//             size: 28,
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Attention Tracking Session',
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   fmt.format(session.startTime),
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodyMedium?.copyWith(fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//             decoration: BoxDecoration(
//               color: focusColor.withOpacity(0.12),
//               borderRadius: BorderRadius.circular(50),
//               border: Border.all(color: focusColor.withOpacity(0.3)),
//             ),
//             child: Text(
//               '${focusPct.toStringAsFixed(0)}% Focus',
//               style: TextStyle(
//                 color: focusColor,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
//         ],
//       ),
//     );
//   }
// }

class _ChildSessionCard extends StatelessWidget {
  final SessionResult session;
  const _ChildSessionCard({required this.session});

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
            child: const Icon(Icons.person_outline_rounded,
              color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.childName,
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(fmt.format(session.startTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
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
            child: Text('${focusPct.toInt()}% focus',
              style: TextStyle(color: focusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
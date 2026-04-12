import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class AllSessionsScreen extends StatelessWidget {
  const AllSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Sessions'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<SessionResult>>(
          stream: service.watchSessions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final sessions = snapshot.data ?? [];

            if (sessions.isEmpty) {
              return Center(
                child: EmptyState(
                  title: 'No sessions found',
                  message: 'All your sessions will appear here.',
                  icon: Icons.history_rounded,
                  action: ElevatedButton.icon(
                    onPressed: () => context.push('/session/setup'),
                    icon: const Icon(Icons.add),
                    label: const Text('Start New Session'),
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SessionCard(session: session)
                      .animate()
                      .fadeIn(delay: (index * 40).ms)
                      .slideX(begin: 0.05),
                );
              },
            );
          },
        ),
      ),
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
            child: Text('${focusPct.toStringAsFixed(0)}% focus',
              style: TextStyle(color: focusColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
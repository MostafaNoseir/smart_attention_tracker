import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Children profiles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(context, service),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add child'),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ChildProfile>>(
        stream: service.watchChildren(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final children = snapshot.data ?? [];
          if (children.isEmpty) {
            return EmptyState(
              title: 'No children yet',
              message: 'Add child profiles to start tracking attention sessions.',
              icon: Icons.child_care_rounded,
              action: ElevatedButton.icon(
                onPressed: () => _showAddChildDialog(context, service),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add first child'),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(32),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: children.length,
              itemBuilder: (ctx, i) =>
                _ChildCard(child: children[i], service: service)
                  .animate().fadeIn(delay: (i * 60).ms).scale(begin: const Offset(0.95, 0.95)),
            ),
          );
        },
      ),
    );
  }

  static void _showAddChildDialog(BuildContext context, FirestoreService service) {
    showDialog(
      context: context,
      builder: (_) => _AddChildDialog(service: service),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildProfile child;
  final FirestoreService service;
  const _ChildCard({required this.child, required this.service});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/child-profile', extra: child),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                ),
                child: Center(
                  child: Text(
                    child.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // if (child.wearsGlasses)
              //   const Tooltip(
              //     message: 'Wears glasses',
              //     child: Icon(Icons.visibility, size: 18, color: AppColors.textMuted),
              //   ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                color: AppColors.surfaceElevated,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'session', child: Text('Start session')),
                  const PopupMenuItem(value: 'delete',
                    child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                ],
                onSelected: (val) async {
                  if (val == 'session') {
                    context.push('/session/setup', extra: child);
                  } else if (val == 'delete') {
                    await service.deleteChild(child.id);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(child.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Age ${child.age}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
          if (child.notes != null && child.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(child.notes!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11, color: AppColors.textMuted)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/session/setup', extra: child),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surfaceBorder),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Start session'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChildDialog extends StatefulWidget {
  final FirestoreService service;
  const _AddChildDialog({required this.service});

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  int _age = 7;
  bool _glasses = false;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.service.addChild(ChildProfile(
      id: '', name: _nameCtrl.text.trim(), age: _age,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      wearsGlasses: _glasses, createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add child profile', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 28),

                AppTextField(
                  label: 'CHILD\'S NAME',
                  hint: 'First name only',
                  controller: _nameCtrl,
                  prefixIcon: Icons.child_care_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),

                // Age selector
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     const Text('AGE', style: TextStyle(
                //       color: AppColors.textSecondary, fontSize: 12,
                //       fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                //     const SizedBox(height: 8),
                //     DropdownButtonFormField<int>(
                //       value: _age,
                //       icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                //       decoration: InputDecoration(
                //         filled: true,
                //         fillColor: AppColors.surfaceElevated,
                //         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(10),
                //           borderSide: const BorderSide(color: AppColors.surfaceBorder),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(10),
                //           borderSide: const BorderSide(color: AppColors.surfaceBorder),
                //         ),
                //         focusedBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(10),
                //           borderSide: const BorderSide(color: AppColors.primary),
                //         ),
                //       ),
                //       dropdownColor: AppColors.surfaceElevated,
                //       // إنشاء قائمة بالأعمار من 2 إلى 12 (11 رقم)
                //       items: List.generate(11, (i) {
                //         final age = i + 2; 
                //         return DropdownMenuItem<int>(
                //           value: age,
                //           child: Text(
                //             '$age',
                //             style: const TextStyle(
                //               color: AppColors.textSecondary,
                //               fontWeight: FontWeight.w600,
                //             ),
                //           ),
                //         );
                //       }),
                //       onChanged: (int? newValue) {
                //         if (newValue != null) {
                //           setState(() => _age = newValue);
                //         }
                //       },
                //     ),
                //   ],
                // ),
                const Text('AGE', style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _age,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: List.generate(11, (i) => i + 2).map((age) {
                    return DropdownMenuItem<int>(
                      value: age,
                      child: Text('$age Years', style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _age = val);
                  },
                ),
                const SizedBox(height: 20),

                AppTextField(
                  label: 'NOTES (OPTIONAL)',
                  hint: 'Any relevant info for the researcher...',
                  controller: _notesCtrl,
                  maxLines: 2,
                ),
                // const SizedBox(height: 16),

                // // Glasses toggle
                // Row(
                //   children: [
                //     Switch(
                //       value: _glasses,
                //       onChanged: (v) => setState(() => _glasses = v),
                //       activeColor: AppColors.primary,
                //     ),
                //     const SizedBox(width: 10),
                //     const Icon(Icons.visibility, size: 18, color: AppColors.textMuted),
                //     const SizedBox(width: 8),
                //     const Text('Child wears glasses',
                //       style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                //   ],
                // ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Add child',
                        onPressed: _save,
                        isLoading: _loading,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
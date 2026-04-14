import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class SessionCompleteScreen extends StatelessWidget {
	final SessionResult result;
	const SessionCompleteScreen({super.key, required this.result});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Session Complete'),
				backgroundColor: AppColors.surface,
			),
			backgroundColor: AppColors.background,
			body: Center(
				child: Padding(
					padding: const EdgeInsets.all(24),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
							const SizedBox(height: 16),
							Text('Session Complete', style: TextStyle(fontSize: 20, color: AppColors.textPrimary)),
							const SizedBox(height: 8),
							Text('You can now view the results', style: TextStyle(color: AppColors.textSecondary)),
							const SizedBox(height: 24),
							ElevatedButton(
								onPressed: () => context.go('/results/${result.id}', extra: result),
								child: const Text('View Results'),
							),
						],
					),
				),
			),
		);
	}
}
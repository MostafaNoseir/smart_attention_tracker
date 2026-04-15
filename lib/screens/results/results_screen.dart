import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';

class ResultsScreen extends StatefulWidget {
  final SessionResult result;
  const ResultsScreen({super.key, required this.result});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _videoSaved = false;
  String? _tempVideoPath;

  @override
  void initState() {
    super.initState();
    _tempVideoPath = widget.result.tempVideoPath;

    if (_tempVideoPath != null) {
      try {
        final f = File(_tempVideoPath!);
        if (!f.existsSync()) _tempVideoPath = null;
      } catch (_) {
        _tempVideoPath = null;
      }
    }
  }

  @override
  void dispose() {
    // ←←← هنا بنعمل "consume" للفيديو عشان المرة الجاية الزر يكون معطل
    if (_tempVideoPath != null) {
      try {
        FirestoreService().clearSessionTempVideo(widget.result.id);
      } catch (_) {}
    }
    super.dispose();
  }

      Future<void> _saveVideo() async {
    if (_tempVideoPath == null) return;

    final src = File(_tempVideoPath!);
    if (!await src.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temporary video not found')),
        );
      }
      return;
    }

    final suggestedName = 'session_${widget.result.childName}_${widget.result.id}.avi';

    try {
      final output = await FilePicker.platform.saveFile(
        dialogTitle: 'Save session video',
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['avi'],
      );

      if (output != null) {
        await src.copy(output);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Video saved successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        // ←←← مهم: ما بنمسحش أي حاجة ولا بنعطل الزر
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final sessionMetrics = result.metrics ?? calculateSessionMetrics(result.gazePoints);
    final hasGazeData = result.gazePoints.isNotEmpty;
    final hasTimeline = result.attentionTimeline.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (hasGazeData) context.go('/dashboard');
            else context.pop();
          } ,
        ),
        title: Text('Results — ${result.childName}'),
        actions: [
          // Save video button (always shown; disabled when no temp video or already saved)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _tempVideoPath == null ? null : () => _saveVideo(),
              child: Opacity(
                opacity: _tempVideoPath == null ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_alt_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text('Save video', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _ExportButton(result: result),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            _ResultsHeader(result: result)
              .animate().fadeIn().slideY(begin: -0.05),

            const SizedBox(height: 32),

            // ── Stats row ───────────────────────────────────────
            _StatsRow(result: result)
              .animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // Advanced metrics (always show using persisted or computed values)
            const SizedBox(height: 24),
            _AdvancedMetricsRow(result: result, metrics: sessionMetrics),

           // ── Attention Timeline ──────────────────────────────
            if (hasTimeline) ...[
              const SizedBox(height: 32),
              _AttentionTimelineChart(result: result)
                .animate().fadeIn(delay: 200.ms),
            ],

            // ── Focus breakdown ─────────────────────────────────
            if (hasTimeline) ...[
              const SizedBox(height: 24),
              _FocusBreakdown(result: result)
                .animate().fadeIn(delay: 300.ms),
            ],

            // ── Gaze path chart ─────────────────────────────────
            if (hasGazeData) ...[
              const SizedBox(height: 24),
              _GazePathChart(result: result)
                .animate().fadeIn(delay: 400.ms),
            ],

            if (!hasGazeData)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    "Detailed gaze coordinates are only available immediately after a session.",
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Results Header ──────────────────────────────────────────────
class _ResultsHeader extends StatelessWidget {
  final SessionResult result;
  const _ResultsHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, MMMM d yyyy · HH:mm');
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryDim,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
            ),
            child: Center(
              child: Text(
                result.childName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.childName,
                  style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(fmt.format(result.startTime),
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _Chip(label: '${result.durationSeconds ~/ 60} min session',
                      color: AppColors.primary),
                    _Chip(label: result.config.targetShape.label,
                      color: AppColors.accent),
                    _Chip(label: result.config.distractorType.label,
                      color: AppColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final SessionResult result;
  const _StatsRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final focus = result.focusPercentage;
    final resist = result.distractorResistance;

    final focusColor = focus >= 70 ? AppColors.success : focus >= 45 ? AppColors.warning : AppColors.danger;
    final resistColor = resist >= 70 ? AppColors.success : resist >= 45 ? AppColors.warning : AppColors.danger;

    return Row(
      children: [
        Expanded(child: AppCard(
          color: AppColors.surface,
          child: Column(
            children: [
              Text('${focus.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                  color: focusColor)),
              const SizedBox(height: 6),
              const Text('Focus rate', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: focus / 100,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation(focusColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: AppCard(
          child: Column(
            children: [
              Text('${resist.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                  color: resistColor)),
              const SizedBox(height: 6),
              const Text('Distractor resistance', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: resist / 100,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation(resistColor),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: AppCard(
          child: Column(
            children: [
              Text('${result.durationSeconds ~/ 60}:${(result.durationSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Duration', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1.0,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        )),
        if (result.gazePoints.isNotEmpty) ...[
          const SizedBox(width: 16),
        Expanded(child: AppCard(
          child: Column(
            children: [
              Text('${result.gazePoints.length}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Data points', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 1.0,
                backgroundColor: AppColors.surfaceBorder,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        )),
        ],
        
      ],
    );
  }
}

// ─── Attention Timeline Chart ─────────────────────────────────────
class _AttentionTimelineChart extends StatelessWidget {
  final SessionResult result;
  const _AttentionTimelineChart({required this.result});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Text('Attention timeline',
                style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              // Legend
              _LegendItem(color: AppColors.chartFocus, label: 'Focused'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.chartDistract, label: 'Distracted'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.chartDistractor, label: 'Distractor event', isDot: true),
            ],
          ),
          const SizedBox(height: 24),

          // Timeline bar
          SizedBox(
            height: 48,
            child: result.attentionTimeline.isEmpty
                ? const Center(
                    child: Text('No attention data recorded',
                      style: TextStyle(color: AppColors.textMuted)))
                : _TimelineBar(timeline: result.attentionTimeline),
          ),

          const SizedBox(height: 12),

          // Time labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0:00', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(
                '${result.durationSeconds ~/ 60}:${(result.durationSeconds % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),

          const SizedBox(height: 20),

          // Focus line chart over time
          SizedBox(
            height: 120,
            child: _FocusLineChart(result: result),
          ),
        ],
      ),
    );
  }
}

class _TimelineBar extends StatelessWidget {
  final List<AttentionSpan> timeline;
  const _TimelineBar({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) return const SizedBox.shrink();
    final total = timeline.last.endMs.toDouble();

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Attention spans
          ...timeline.map((span) {
            final left = (span.startMs / total) * constraints.maxWidth;
            final width = (span.durationMs / total) * constraints.maxWidth;
            return Positioned(
              left: left,
              width: width,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: span.isFocused
                      ? AppColors.chartFocus.withOpacity(0.8)
                      : AppColors.chartDistract.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
          // Distractor markers
          ...timeline.where((s) => s.hasDistractor).map((span) {
            final left = (span.startMs / total) * constraints.maxWidth;
            return Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(
                color: AppColors.chartDistractor,
              ),
            );
          }),
        ],
      );
    });
  }
}

class _FocusLineChart extends StatelessWidget {
  final SessionResult result;
  const _FocusLineChart({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.gazePoints.isEmpty) return const SizedBox.shrink();

    // Build rolling focus average (every 5 points)
    final spots = <FlSpot>[];
    const window = 5;
    for (int i = 0; i < result.gazePoints.length; i += window) {
      final chunk = result.gazePoints.skip(i).take(window).toList();
      final focused = chunk.where((p) => p.isOnTarget).length;
      spots.add(FlSpot(i.toDouble(), focused / chunk.length));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDot;
  const _LegendItem({required this.color, required this.label, this.isDot = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        isDot
            ? Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle))
            : Container(
                width: 14, height: 8,
                decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

// ─── Focus Breakdown ──────────────────────────────────────────────
class _FocusBreakdown extends StatelessWidget {
  final SessionResult result;
  const _FocusBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    final focusedSpans = result.attentionTimeline.where((s) => s.isFocused).toList();
    final distractedSpans = result.attentionTimeline.where((s) => !s.isFocused).toList();

    final avgFocusDuration = focusedSpans.isEmpty ? 0.0
        : focusedSpans.map((s) => s.durationSeconds).reduce((a, b) => a + b) / focusedSpans.length;
    final maxFocusDuration = focusedSpans.isEmpty ? 0.0
        : focusedSpans.map((s) => s.durationSeconds).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Focus spans', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              StatBadge(
                value: '${focusedSpans.length}',
                label: 'focused periods',
                color: AppColors.chartFocus,
              ),
              const SizedBox(height: 16),
              _MiniStat('Avg duration', '${avgFocusDuration.toStringAsFixed(1)}s'),
              _MiniStat('Longest focus', '${maxFocusDuration.toStringAsFixed(1)}s'),
            ],
          ),
        )),
        const SizedBox(width: 16),
        Expanded(child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Distraction events', style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              StatBadge(
                value: '${distractedSpans.length}',
                label: 'distraction events',
                color: AppColors.chartDistract,
              ),
              const SizedBox(height: 16),
              _MiniStat('Distractor events',
                '${result.gazePoints.where((p) => p.isDistractorActive).length ~/ 10}'),
              _MiniStat('Resistance rate',
                '${result.distractorResistance.toStringAsFixed(0)}%'),
            ],
          ),
        )),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(
            color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Gaze Path Chart (scatter) ────────────────────────────────────
class _GazePathChart extends StatelessWidget {
  final SessionResult result;
  const _GazePathChart({required this.result});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.scatter_plot_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Text('Gaze heatmap', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Distribution of gaze points during session',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: result.gazePoints.isEmpty
                ? const Center(child: Text('No gaze data', style: TextStyle(color: AppColors.textMuted)))
                : _GazeScatterPlot(points: result.gazePoints),
          ),
        ],
      ),
    );
  }
}

class _GazeScatterPlot extends StatelessWidget {
  final List<GazePoint> points;
  const _GazeScatterPlot({required this.points});

  @override
  Widget build(BuildContext context) {
    // Sample max 200 points for performance
    // final sample = points.length > 200
    //     ? points.where((_, i) => i % (points.length ~/ 200) == 0)
    //     : points as Iterable<GazePoint>;

    final sample = points.length > 200
    ? points.whereIndexed((_, i) => i % (points.length ~/ 200) == 0) // Use new name here
    : points;

    // Normalize points to 0..1 range
    final maxX = points.map((p) => p.x).reduce((a, b) => a > b ? a : b);
    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);

    return ScatterChart(
      ScatterChartData(
        minX: 0, maxX: maxX,
        minY: 0, maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        scatterSpots: sample.map((p) => ScatterSpot(
          p.x, p.y,
          dotPainter: FlDotCirclePainter(
            radius: 3,
            color: p.isOnTarget
                ? AppColors.chartFocus.withOpacity(0.4)
                : AppColors.chartDistract.withOpacity(0.4),
            strokeWidth: 0,
          ),
        )).toList(),
      ),
    );
  }
}

// extension _IndexedWhere on Iterable<GazePoint> {
//   Iterable<GazePoint> where(bool Function(GazePoint, int) test) sync* {
//     int i = 0;
//     for (final e in this) {
//       if (test(e, i)) yield e;
//       i++;
//     }
//   }
// }

extension _IndexedWhere on Iterable<GazePoint> {
  // Rename 'where' to 'whereIndexed'
  Iterable<GazePoint> whereIndexed(bool Function(GazePoint, int) test) sync* {
    int i = 0;
    for (final e in this) {
      if (test(e, i)) yield e;
      i++;
    }
  }
}

// ─── Export Button ────────────────────────────────────────────────
class _ExportButton extends StatefulWidget {
  final SessionResult result;
  const _ExportButton({required this.result});

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _loading = false;

  // Future<void> _exportCsv() async {
  //   setState(() => _loading = true);
  //   try {
  //     final service = FirestoreService();
  //     await service.exportCsv(widget.result);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('CSV exported to Documents folder'),
  //           backgroundColor: AppColors.success,
  //         ),
  //       );
  //     }
  //   } finally {
  //     if (mounted) setState(() => _loading = false);
  //   }
  // }

  Future<void> _exportCsv() async {
  setState(() => _loading = true);
  try {
    final service = FirestoreService();
    await service.exportCsv(widget.result);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    // If it's a cancellation, we just stop loading without an error message
    // Otherwise, show an error.
    if (e.toString() != "Exception: Export cancelled" && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        

      );
      print('Error exporting CSV: $e');
      debugPrint('Error exporting CSV: $e');
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surfaceElevated,
      onSelected: (val) {
        if (val == 'csv') _exportCsv();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'csv', child: Row(
          children: [
            Icon(Icons.table_chart_outlined, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text('Export CSV'),
          ],
        )),
        // const PopupMenuItem(value: 'pdf', child: Row(
        //   children: [
        //     Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.textSecondary),
        //     SizedBox(width: 10),
        //     Text('Export PDF report'),
        //   ],
        // )),
      ],
      child: _loading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download_rounded, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Export', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
    );
  }
}

// ─── Advanced Metrics UI ───────────────────────────────────────
class _AdvancedMetricsRow extends StatelessWidget {
  final SessionResult result;
  final SessionMetrics metrics;
  const _AdvancedMetricsRow({super.key, required this.result, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final m = metrics;
    return Row(
      children: [
        Expanded(child: _MetricTile(title: 'Max Focus streak', value: '${m.maxFocusStreak.toStringAsFixed(1)}', icon: Icons.timer)),
        const SizedBox(width: 16),
        Expanded(child: _MetricTile(title: 'Fatigue Index', value: m.fatigueIndex.toStringAsFixed(2), icon: Icons.psychology, color: m.fatigueIndex > 0 ? Colors.orange : Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _MetricTile(title: 'Micro Distractions', value: '${m.microDistractions}', icon: Icons.flash_on)),
        const SizedBox(width: 16),
        Expanded(child: _MetricTile(title: 'Calibration retries', value: '${m.calibrationRetries}', icon: Icons.replay)),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  const _MetricTile({super.key, required this.title, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
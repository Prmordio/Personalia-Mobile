import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../data/execution_recorder.dart';
import '../domain/exercise_rule_set.dart';
import '../domain/execution_report.dart';
import '../state/execution_analysis_controller.dart';
import 'execution_capture_screen.dart';
import 'issue_presentation.dart';
import 'widgets/skeleton_overlay_painter.dart';

const _speeds = [1.0, 0.5, 0.25];

/// Resultado: vídeo local com o esqueleto sincronizado, timeline das reps, problemas
/// medidos (com "Ver" em câmera lenta) e o comentário da IA.
class ExecutionResultScreen extends ConsumerStatefulWidget {
  const ExecutionResultScreen({super.key, required this.args, required this.recorded});
  final ExecutionCaptureArgs args;
  final RecordedSet recorded;

  @override
  ConsumerState<ExecutionResultScreen> createState() => _ExecutionResultScreenState();
}

class _ExecutionResultScreenState extends ConsumerState<ExecutionResultScreen> {
  late final VideoPlayerController _video;
  double _speed = 1;
  int? _pauseAtMs;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.file(File(widget.recorded.videoPath))
      ..addListener(_onVideoTick)
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
    Future.microtask(() {
      final language = ref.read(localeProvider)?.languageCode ?? 'pt';
      ref.read(executionAnalysisProvider.notifier).analyze(
            exerciseKey: widget.args.exerciseKey,
            exerciseName: widget.args.exerciseName,
            recorded: widget.recorded,
            language: language,
          );
    });
  }

  void _onVideoTick() {
    final pauseAt = _pauseAtMs;
    if (pauseAt != null && _video.value.position.inMilliseconds >= pauseAt) {
      _pauseAtMs = null;
      _video
        ..pause()
        ..seekTo(Duration(milliseconds: pauseAt));
    }
  }

  /// Volta ao começo da rep e toca em câmera lenta até o pior momento, pausando ali.
  Future<void> _showMoment(ExecutionReport report, IssueHighlight h) async {
    final rep = report.reps.firstWhere((r) => r.index == h.rep);
    await _setSpeed(0.25);
    await _video.seekTo(Duration(milliseconds: rep.startMs));
    _pauseAtMs = h.tMs;
    await _video.play();
  }

  Future<void> _setSpeed(double speed) async {
    await _video.setPlaybackSpeed(speed);
    if (mounted) setState(() => _speed = speed);
  }

  @override
  void dispose() {
    _video
      ..removeListener(_onVideoTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(executionAnalysisProvider);
    final report = state.report;

    return Scaffold(
      appBar: AppBar(title: Text(l.execTitle)),
      body: switch (state.phase) {
        ExecutionPhase.idle || ExecutionPhase.analyzing => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(l.execAnalyzing)],
            ),
          ),
        ExecutionPhase.noReps => _NoReps(onRetry: _retry),
        ExecutionPhase.result => ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _VideoWithOverlay(video: _video, state: state),
              _PlaybackControls(
                video: _video,
                speed: _speed,
                onSpeed: _setSpeed,
              ),
              _RepTimeline(video: _video, report: report!),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _ScoreHeader(report: report, exerciseName: widget.args.exerciseName),
                    const SizedBox(height: 12),
                    _FeedbackCard(state: state),
                    const SizedBox(height: 16),
                    Text(l.execIssuesTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (report.issues.isEmpty && (state.feedback?.extraIssues.isEmpty ?? true))
                      Text(l.execNoIssues)
                    else ...[
                      for (final issue in report.issues)
                        _IssueCard(issue: issue, onSee: () => _showMoment(report, issue.worst)),
                      for (final extra in state.feedback?.extraIssues ?? const [])
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome, color: AppColors.blue),
                            title: Text(extra.label),
                            subtitle: Text(
                              [l.execExtraIssue, if (extra.reps.isNotEmpty) l.execRepsList(extra.reps.join(', '))].join(' · '),
                            ),
                          ),
                        ),
                    ],
                    if (report.fatigue case final fatigue?) ...[
                      const SizedBox(height: 8),
                      _Note(icon: Icons.trending_down, text: l.execFatigue(fatigue.romDropPct, fatigue.fromRep)),
                    ],
                    if (report.unclearReps.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _Note(icon: Icons.visibility_off_outlined, text: l.execUnclear(report.unclearReps.join(', '))),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.videocam), label: Text(l.execTryAgain)),
                  ],
                ),
              ),
            ],
          ),
      },
    );
  }

  void _retry() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ExecutionCaptureScreen(args: widget.args)));
  }
}

class _VideoWithOverlay extends StatelessWidget {
  const _VideoWithOverlay({required this.video, required this.state});
  final VideoPlayerController video;
  final ExecutionAnalysisState state;

  @override
  Widget build(BuildContext context) {
    if (!video.value.isInitialized) {
      return const AspectRatio(aspectRatio: 9 / 16, child: ColoredBox(color: Colors.black));
    }
    final report = state.report!;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(video),
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: video,
                  builder: (context, value, _) {
                    final tMs = value.position.inMilliseconds;
                    final active = report.issuesAt(tMs);
                    return CustomPaint(
                      painter: SkeletonOverlayPainter(
                        frame: frameAt(state.frames, tMs),
                        side: report.side,
                        alertJoints: {for (final i in active) ...i.joints},
                        annotation: annotationFor(active),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.video, required this.speed, required this.onSpeed});
  final VideoPlayerController video;
  final double speed;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: video,
        builder: (context, value, _) => Row(
          children: [
            IconButton(
              icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => value.isPlaying ? video.pause() : video.play(),
            ),
            const Spacer(),
            for (final s in _speeds)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${s == s.roundToDouble() ? s.toInt() : s}x'),
                  selected: speed == s,
                  onSelected: (_) => onSpeed(s),
                ),
              ),
          ],
        ),
      );
}

/// Barra com um segmento por rep (vermelho se alguma verificação falhou); toque para pular.
class _RepTimeline extends StatelessWidget {
  const _RepTimeline({required this.video, required this.report});
  final VideoPlayerController video;
  final ExecutionReport report;

  @override
  Widget build(BuildContext context) {
    final total = video.value.duration.inMilliseconds;
    if (total <= 0) return const SizedBox(height: 28);
    final failing = {for (final i in report.issues) ...i.reps};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double x(int ms) => (ms / total).clamp(0, 1) * width;
          return GestureDetector(
            onTapDown: (d) => video.seekTo(Duration(milliseconds: (d.localPosition.dx / width * total).round())),
            child: SizedBox(
              height: 28,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: video,
                builder: (context, value, _) => Stack(
                  children: [
                    Positioned.fill(
                      top: 10,
                      bottom: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    for (final rep in report.reps)
                      Positioned(
                        left: x(rep.startMs),
                        width: (x(rep.endMs) - x(rep.startMs)).clamp(2, width),
                        top: 6,
                        bottom: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: report.unclearReps.contains(rep.index)
                                ? Colors.grey
                                : failing.contains(rep.index)
                                    ? alertColor
                                    : okColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Center(
                            child: Text('${rep.index}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ),
                      ),
                    Positioned(
                      left: x(value.position.inMilliseconds) - 1,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: const ColoredBox(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.report, required this.exerciseName});
  final ExecutionReport report;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = report.score >= 80 ? okColor : (report.score >= 60 ? AppColors.orange : alertColor);
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color,
          child: Text('${report.score}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exerciseName, style: Theme.of(context).textTheme.titleMedium),
              Text('${l.execScore(report.score)} · ${l.execRepsCount(report.repCount)}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.state});
  final ExecutionAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = state.feedback?.feedback;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.record_voice_over_outlined, color: AppColors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: state.feedbackLoading
                  ? Row(
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.execAiLoading)),
                      ],
                    )
                  : Text(text ?? l.execAiUnavailable),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue, required this.onSee});
  final ExecutionIssue issue;
  final VoidCallback onSee;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final color = switch (issue.severity) {
      IssueSeverity.high => alertColor,
      IssueSeverity.medium => AppColors.orange,
      IssueSeverity.low => Colors.amber.shade700,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issueLabel(l, issue.id), style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${l.execRepsList(issue.reps.join(', '))} · '
                    '${l.execMeasured(formatMeasure(issue.measured, issue.check.unit), formatTarget(issue.check))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(issue.check.cueFor(language)),
                ],
              ),
            ),
            TextButton(onPressed: onSee, child: Text(l.execSee)),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      );
}

class _NoReps extends StatelessWidget {
  const _NoReps({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.accessibility_new, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(l.execNoRepsTitle, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l.execNoRepsBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.videocam), label: Text(l.execTryAgain)),
          ],
        ),
      ),
    );
  }
}

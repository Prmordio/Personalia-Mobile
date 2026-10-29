import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/execution_recorder.dart';
import '../data/local_video_store.dart';
import '../data/pose_extractor.dart';
import '../domain/exercise_rule_set.dart';
import '../domain/geometry.dart';
import '../domain/pose_frame.dart';
import '../domain/rep_segmenter.dart';
import '../domain/signals.dart';
import '../state/execution_analysis_controller.dart';
import 'execution_result_screen.dart';
import 'widgets/skeleton_overlay_painter.dart';

class ExecutionCaptureArgs {
  const ExecutionCaptureArgs({required this.exerciseKey, required this.exerciseName});
  final String exerciseKey;
  final String exerciseName;
}

const _countdownSeconds = 3;
const _maxRecording = Duration(seconds: 60);
const _framingChain = [Joint.shoulder, Joint.hip, Joint.knee, Joint.ankle];

/// Gravação guiada: consentimento → enquadramento (esqueleto ao vivo) → contagem →
/// gravação com contador de reps → análise.
class ExecutionCaptureScreen extends ConsumerStatefulWidget {
  const ExecutionCaptureScreen({super.key, required this.args});
  final ExecutionCaptureArgs args;

  @override
  ConsumerState<ExecutionCaptureScreen> createState() => _ExecutionCaptureScreenState();
}

class _ExecutionCaptureScreenState extends ConsumerState<ExecutionCaptureScreen> with WidgetsBindingObserver {
  ExecutionRecorder? _recorder;
  ExerciseRuleSet? _ruleSet;
  CameraLensDirection _lens = CameraLensDirection.back;
  bool _cameraError = false;
  int? _countdown;
  bool _recording = false;
  bool _stopping = false;
  int _liveReps = 0;
  Timer? _timer;
  final _elapsed = Stopwatch();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    const LocalVideoStore().purgeExpired();
    final consent = ExecutionConsentStore();
    if (!await consent.hasConsent()) {
      if (!mounted) return;
      final accepted = await _askConsent();
      if (!accepted) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      await consent.accept();
    }
    _ruleSet = await ref.read(ruleSetRepositoryProvider).load(widget.args.exerciseKey);
    await _openCamera();
  }

  Future<bool> _askConsent() async {
    final l = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l.execConsentTitle),
        content: Text(l.execConsentBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancelar)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.execConsentAccept)),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openCamera() async {
    final recorder = ExecutionRecorder(MlKitPoseExtractor());
    try {
      await recorder.initialize(lens: _lens);
    } catch (e) {
      debugPrint('camera init failed: $e');
      await recorder.dispose();
      if (mounted) setState(() => _cameraError = true);
      return;
    }
    if (!mounted) {
      await recorder.dispose();
      return;
    }
    recorder.livePose.addListener(_onPose);
    setState(() {
      _recorder = recorder;
      _cameraError = false;
    });
  }

  Future<void> _closeCamera() async {
    final recorder = _recorder;
    _recorder = null;
    if (recorder == null) return;
    recorder.livePose.removeListener(_onPose);
    await recorder.dispose();
  }

  void _onPose() {
    final recorder = _recorder;
    final ruleSet = _ruleSet;
    if (!_recording || recorder == null || ruleSet == null) return;
    final frames = recorder.recordedFrames;
    if (frames.length % 5 != 0) return;
    final samples = extractSignals(frames, pickVisibleSide(frames), {ruleSet.rep.signal}, minConfidence: ruleSet.minConfidence);
    final reps = RepSegmenter(ruleSet.rep).segment(samples).length;
    if (reps != _liveReps && mounted) setState(() => _liveReps = reps);
  }

  bool _isFramed(PoseFrame? frame) {
    if (frame == null) return false;
    final min = _ruleSet?.minConfidence ?? 0.5;
    bool sideOk(BodySide s) => _framingChain.every((j) => frame.visible(j.on(s), min) != null);
    return sideOk(BodySide.left) || sideOk(BodySide.right);
  }

  Future<void> _beginCountdown() async {
    for (var s = _countdownSeconds; s > 0; s--) {
      if (!mounted) return;
      setState(() => _countdown = s);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted || _recorder == null) return;
    await _recorder!.startRecording();
    _elapsed
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_elapsed.elapsed >= _maxRecording) _stop();
      if (mounted) setState(() {});
    });
    setState(() {
      _countdown = null;
      _recording = true;
      _liveReps = 0;
    });
  }

  Future<void> _stop() async {
    final recorder = _recorder;
    if (_stopping || recorder == null || !_recording) return;
    _stopping = true;
    _timer?.cancel();
    _elapsed.stop();
    final recorded = await recorder.stopRecording();
    final videoPath = await const LocalVideoStore().keep(recorded.videoPath);
    await _closeCamera();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ExecutionResultScreen(
        args: widget.args,
        recorded: RecordedSet(videoPath: videoPath, frames: recorded.frames),
      ),
    ));
  }

  Future<void> _switchLens() async {
    await _closeCamera();
    _lens = _lens == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
    await _openCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_recording) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _closeCamera();
    } else if (state == AppLifecycleState.resumed && _recorder == null && _ruleSet != null) {
      _openCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final recorder = _recorder;
    final controller = recorder?.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.args.exerciseName),
        actions: [
          if (!_recording && _countdown == null && recorder != null)
            IconButton(
              tooltip: l.execSwitchCamera,
              icon: const Icon(Icons.cameraswitch_outlined),
              onPressed: _switchLens,
            ),
        ],
      ),
      body: _cameraError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.execCameraError, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              ),
            )
          : controller == null || !controller.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: CameraPreview(
                          controller,
                          child: ValueListenableBuilder<PoseFrame?>(
                            valueListenable: recorder!.livePose,
                            builder: (context, frame, _) => Stack(
                              fit: StackFit.expand,
                              children: [
                                CustomPaint(
                                  painter: SkeletonOverlayPainter(
                                    frame: frame,
                                    side: frame == null ? BodySide.left : pickVisibleSide([frame]),
                                    minConfidence: _ruleSet?.minConfidence ?? 0.5,
                                  ),
                                ),
                                if (_countdown != null)
                                  Center(
                                    child: Text(
                                      '$_countdown',
                                      style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  top: 12,
                                  child: _StatusBanner(
                                    text: _recording
                                        ? '${l.execRecording} · ${l.execLiveReps(_liveReps)}'
                                        : _countdown != null
                                            ? l.execCountdown(_countdown!)
                                            : _isFramed(frame)
                                                ? l.execFramingOk
                                                : '${l.execFramingBad}\n${l.execFramingHint}',
                                    ok: _recording || _isFramed(frame),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: _recording
                            ? Row(
                                children: [
                                  Text(
                                    _format(_elapsed.elapsed),
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontFeatures: [FontFeature.tabularFigures()]),
                                  ),
                                  const Spacer(),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                    onPressed: _stopping ? null : _stop,
                                    icon: const Icon(Icons.stop),
                                    label: Text(l.execStop),
                                  ),
                                ],
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
                                  onPressed: _countdown == null ? _beginCountdown : null,
                                  icon: const Icon(Icons.fiber_manual_record),
                                  label: Text(l.execStart),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  static String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.text, required this.ok});
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (ok ? const Color(0xFF1B5E20) : Colors.black).withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
      );
}

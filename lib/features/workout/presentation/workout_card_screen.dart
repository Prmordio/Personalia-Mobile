import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../data/workout_summary.dart';

class WorkoutCardScreen extends StatefulWidget {
  const WorkoutCardScreen({super.key, required this.summary, required this.mood});
  final WorkoutSummary summary;
  final String mood;

  @override
  State<WorkoutCardScreen> createState() => _WorkoutCardScreenState();
}

class _WorkoutCardScreenState extends State<WorkoutCardScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;
  File? _photo;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); setState(() => _photo = null); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = File('${Directory.systemTemp.path}/personalia_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Treino ${widget.summary.dayName} concluído! 💪 #PersonaliA',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Card do treino', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _WorkoutCard(summary: widget.summary, mood: widget.mood, photo: _photo),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(_photo == null ? Icons.add_a_photo : Icons.edit, size: 18),
                      label: Text(_photo == null ? 'Adicionar foto' : 'Trocar foto'),
                      onPressed: _showPhotoOptions,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _sharing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.share),
                      label: Text(_sharing ? 'Gerando...' : 'Compartilhar'),
                      onPressed: _sharing ? null : _share,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.summary, required this.mood, this.photo});
  final WorkoutSummary summary;
  final String mood;
  final File? photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        boxShadow: [
          BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Text('PersonaliA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                const Spacer(),
                Text(summary.dayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          // Photo or mood emoji
          if (photo != null)
            ClipRRect(
              child: Image.file(photo!, width: 360, height: 200, fit: BoxFit.cover),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Text(mood, style: const TextStyle(fontSize: 72)),
            ),
          // If photo, show mood on top as overlay — done via Stack below
          if (photo != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(mood, style: const TextStyle(fontSize: 36)),
            ),
          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                _StatTile(icon: Icons.timer_outlined, label: 'Duração', value: summary.durationFormatted),
                const SizedBox(width: 10),
                _StatTile(icon: Icons.fitness_center, label: 'Exercícios', value: '${summary.completedCount}/${summary.totalExercises}'),
                const SizedBox(width: 10),
                _StatTile(icon: Icons.monitor_weight_outlined, label: 'Volume', value: summary.totalVolumeFormatted),
              ],
            ),
          ),
          // Footer
          Container(
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                'personalia.app • ${_dateStr()}',
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateStr() {
    final d = summary.finishedAt;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.orange, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

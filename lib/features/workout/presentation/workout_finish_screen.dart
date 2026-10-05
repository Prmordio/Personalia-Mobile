import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/app_api.dart';
import '../data/workout_summary.dart';
import '../state/active_workout_session.dart';
import '../state/completed_workout_session.dart';
import 'workout_card_screen.dart';

const _moods = [
  (emoji: '😤', label: 'Exausto'),
  (emoji: '😑', label: 'Mais ou menos'),
  (emoji: '😊', label: 'Bom / Rendimento ok'),
  (emoji: '🔥', label: 'Excelente / Superei limites!'),
];

class WorkoutFinishScreen extends ConsumerStatefulWidget {
  const WorkoutFinishScreen({super.key, required this.summary});
  final WorkoutSummary summary;

  @override
  ConsumerState<WorkoutFinishScreen> createState() => _WorkoutFinishScreenState();
}

class _WorkoutFinishScreenState extends ConsumerState<WorkoutFinishScreen> {
  String? _selectedEmoji;
  final _customEmojiController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _customEmojiController.dispose();
    super.dispose();
  }

  String get _effectiveMood {
    if (_customEmojiController.text.trim().isNotEmpty) return _customEmojiController.text.trim();
    return _selectedEmoji ?? '💪';
  }

  Future<void> _saveToBackend(String mood) async {
    final s = widget.summary;
    try {
      await ref.read(appApiProvider).logWorkout(
        dayName: s.dayName,
        startedAt: s.startedAt,
        endedAt: s.finishedAt,
        mood: mood.isEmpty ? null : mood,
        exercises: s.exercises
            .where((e) => e.finished)
            .map((e) => {
                  'name': e.nome,
                  'weight': e.weight.isEmpty ? null : e.weight,
                  'observation': e.observation,
                })
            .toList(),
      );
      ref.invalidate(lastWorkoutProvider);
    } catch (_) {
      // best-effort — falha de rede não bloqueia o usuário
    }
  }

  Future<void> _finalize() async {
    if (_saving) return;
    setState(() => _saving = true);
    final mood = _effectiveMood;
    await _saveToBackend(mood);
    if (!mounted) return;
    final s = widget.summary;
    ref.read(completedWorkoutSessionProvider.notifier).state = CompletedWorkoutSession(
      dayName: s.dayName,
      completedAt: s.finishedAt,
      duration: s.duration,
      completedCount: s.completedCount,
      totalCount: s.totalExercises,
    );
    ref.read(activeWorkoutSessionProvider.notifier).state = null;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _goToCard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkoutCardScreen(summary: widget.summary, mood: _effectiveMood)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    final canProceed = !_saving && (_selectedEmoji != null || _customEmojiController.text.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Treino finalizado! 🎉')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📊 Resumo — ${s.dayName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  children: [
                    _SummaryItem('⏱️ Duração', s.durationFormatted),
                    _SummaryItem('🏆 Exercícios', '${s.completedCount}/${s.totalExercises}'),
                    if (s.totalVolume > 0) _SummaryItem('⚖️ Volume', s.totalVolumeFormatted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Como você se sentiu?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 16),
          // Emoji grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: _moods.map((m) {
              final selected = _selectedEmoji == m.emoji;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() {
                  _selectedEmoji = selected ? null : m.emoji;
                  if (!selected) _customEmojiController.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.orange : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.orange : Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Text(m.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Custom emoji
          TextField(
            controller: _customEmojiController,
            decoration: const InputDecoration(
              labelText: 'Outro emoji ou sentimento',
              prefixText: '✏️ ',
              border: OutlineInputBorder(),
              helperText: 'Ex: 🥵 Destruído!',
            ),
            onChanged: (_) => setState(() => _selectedEmoji = null),
          ),
          const SizedBox(height: 32),
          // Card button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Gerar card do treino', style: TextStyle(fontSize: 15)),
              onPressed: canProceed ? _goToCard : null,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Finalizar sem card', style: TextStyle(fontSize: 15)),
              onPressed: _saving ? null : _finalize,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

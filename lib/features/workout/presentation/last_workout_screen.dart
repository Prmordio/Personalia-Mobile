import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../home/data/app_api.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _timeFormat = DateFormat('HH:mm');

class LastWorkoutScreen extends ConsumerWidget {
  const LastWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return const Center(child: Text('Você ainda não finalizou nenhum treino.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(workoutHistoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) => _WorkoutHistoryCard(entry: history[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Não foi possível carregar o histórico.')),
      ),
    );
  }
}

class _WorkoutHistoryCard extends StatefulWidget {
  const _WorkoutHistoryCard({required this.entry});
  final WorkoutHistoryEntry entry;

  @override
  State<_WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<_WorkoutHistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final date = entry.date;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (entry.isToday)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Hoje', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            Expanded(
                              child: Text(
                                entry.dayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (date != null) ...[
                              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(_dateFormat.format(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              if (entry.startedAt != null) ...[
                                Text('  ·  ', style: TextStyle(color: Colors.grey.shade400)),
                                Icon(Icons.schedule_outlined, size: 13, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(_timeFormat.format(entry.startedAt!), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ],
                            if (entry.durationMinutes != null) ...[
                              Text('  ·  ', style: TextStyle(color: Colors.grey.shade400)),
                              Icon(Icons.timer_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text('${entry.durationMinutes}min', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text('${entry.exercises.length} ex.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                const Divider(height: 20),
                ...entry.exercises.map(
                  (ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              if (ex.observation != null && ex.observation!.isNotEmpty)
                                Text(ex.observation!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (ex.weight != null)
                          Text('${ex.weight} kg', style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

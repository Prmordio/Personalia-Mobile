import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../home/data/app_api.dart';

class LastWorkoutScreen extends ConsumerWidget {
  const LastWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAsync = ref.watch(lastWorkoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Último Treino')),
      body: lastAsync.when(
        data: (last) {
          if (last == null) {
            return const Center(child: Text('Você ainda não finalizou nenhum treino.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(last.dayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (last.date != null)
                Text(DateFormat('dd/MM/yyyy').format(last.date!), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              for (final ex in last.exercises)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ex.name),
                    subtitle: ex.observation != null ? Text(ex.observation!) : null,
                    trailing: ex.weight != null ? Text('${ex.weight} kg') : null,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Não foi possível carregar.')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';

/// Layout compartilhado por toda tela da wizard de onboarding: título, subtítulo opcional,
/// o conteúdo específico do passo, e um botão de ação principal — mesmo esqueleto visual do
/// `login_screen.dart` (Padding + Column stretch), só que reaproveitado passo a passo.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.buttonLabel,
    this.onContinue,
    this.loading = false,
    this.error,
    this.onBack,
    this.backLabel,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String? buttonLabel;
  final VoidCallback? onContinue;
  final bool loading;
  final String? error;
  final VoidCallback? onBack;
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: backLabel == null
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: loading ? null : onBack,
                        )
                      : TextButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: Text(backLabel!),
                          onPressed: loading ? null : onBack,
                        ),
                ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 24),
              Expanded(child: SingleChildScrollView(child: child)),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  context.resolveMessage(error)!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (buttonLabel != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: loading ? null : onContinue,
                  child: loading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        )
                      : Text(buttonLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de opções únicas (objetivo, nível de atividade, foco de treino etc.) — botões cheios
/// de largura total, mesmo padrão do `_channelStep` em `login_screen.dart`.
class ChoiceList extends StatelessWidget {
  const ChoiceList({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<MapEntry<String, String>> options; // value -> label
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              alignment: Alignment.centerLeft,
              backgroundColor: selected == option.key
                  ? AppColors.blue.withValues(alpha: 0.1)
                  : null,
              side: BorderSide(
                color: selected == option.key
                    ? AppColors.blue
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onPressed: () => onSelected(option.key),
            child: Text(option.value),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Par de botões Sim/Não, reaproveitado nas perguntas de doenças/limitações e nas confirmações.
class YesNoChoice extends StatelessWidget {
  const YesNoChoice({super.key, required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: value == true
                  ? AppColors.blue.withValues(alpha: 0.1)
                  : null,
              side: BorderSide(
                color: value == true
                    ? AppColors.blue
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onPressed: () => onChanged(true),
            child: Text(context.l10n.sim),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: value == false
                  ? AppColors.blue.withValues(alpha: 0.1)
                  : null,
              side: BorderSide(
                color: value == false
                    ? AppColors.blue
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            onPressed: () => onChanged(false),
            child: Text(context.l10n.nao),
          ),
        ),
      ],
    );
  }
}

/// Spinner numérico (decrementar/valor/incrementar) — evita depender de picker nativo (que
/// mostrou comportamento inconsistente em alguns aparelhos, ver GymTimeStep) e de pacote
/// externo novo. Usado em duração de treino e dias por semana.
class NumberSpinner extends StatelessWidget {
  const NumberSpinner({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.valueLabel,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final String? valueLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove),
        ),
        Flexible(
          child: SizedBox(
            width: 140,
            child: Text(
              valueLabel ?? '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

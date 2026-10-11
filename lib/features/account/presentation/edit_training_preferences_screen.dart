import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/l10n.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../../onboarding/presentation/widgets/step_scaffold.dart'
    show NumberSpinner;
import '../state/account_providers.dart';

const _focusKeys = ['superior', 'inferior', 'corpo_todo'];

/// "Preferências de treino" (Menu). Mesmo PUT do onboarding. As mudanças valem para os
/// próximos treinos gerados — o treino atual não muda sozinho.
class EditTrainingPreferencesScreen extends ConsumerWidget {
  const EditTrainingPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(accountStatusProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.editTrainingPrefsTitle)),
      body: statusAsync.when(
        data: (status) => _PreferencesForm(current: status.trainingPreferences),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(context.l10n.errLoadPrefs),
        ),
      ),
    );
  }
}

class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({required this.current});
  final OnboardingTrainingPreferences? current;

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late int _minDuration = widget.current?.minTrainingDuration ?? 45;
  late int _maxDuration = widget.current?.maxTrainingDuration ?? 60;
  late int _days = widget.current?.trainingDaysPerWeek ?? 3;
  late String? _focus = widget.current?.trainingFocus;
  late bool _wantsCardio = widget.current?.wantsCardio ?? false;
  late final _hour = TextEditingController(text: _timePart(0));
  late final _minute = TextEditingController(text: _timePart(1));
  Map<String, String> _errors = const {};
  bool _saving = false;

  String _timePart(int index) {
    final parts = (widget.current?.preferredGymTime ?? '').split(':');
    return parts.length == 2 ? parts[index] : '';
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  /// null = sem horário (opcional); '' = inválido.
  String? _gymTime() {
    if (_hour.text.isEmpty && _minute.text.isEmpty) return null;
    final h = int.tryParse(_hour.text);
    final m = int.tryParse(_minute.text);
    if (h == null || m == null || h > 23 || m > 59) return '';
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final gymTime = _gymTime();
    final l = context.l10n;
    final local = <String, String>{
      if (_minDuration > _maxDuration)
        'maxTrainingDuration': l.errOnboardingDurationRange,
      if (_focus == null) 'trainingFocus': l.errOnboardingChooseFocus,
      if (gymTime == '') 'preferredGymTime': l.errOnboardingGymTime,
    };
    if (local.isNotEmpty) {
      setState(() => _errors = local);
      return;
    }

    setState(() {
      _saving = true;
      _errors = const {};
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(onboardingApiProvider)
          .saveTrainingPreferences(
            minTrainingDuration: _minDuration,
            maxTrainingDuration: _maxDuration,
            trainingDaysPerWeek: _days,
            wantsCardio: _wantsCardio,
            trainingFocus: _focus!,
            preferredGymTime: gymTime,
          );
      ref.invalidate(accountStatusProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.prefsSaved)),
      );
      navigator.maybePop();
    } on OnboardingValidationException catch (e) {
      setState(() => _errors = e.errors);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.errSavePrefs)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final focusOptions = [
      MapEntry(_focusKeys[0], l.focusUpper),
      MapEntry(_focusKeys[1], l.focusLower),
      MapEntry(_focusKeys[2], l.focusFullBody),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(
          title: l.onboardingDurationTitle,
          error:
              _errors['minTrainingDuration'] ?? _errors['maxTrainingDuration'],
          child: Column(
            children: [
              Text(l.onboardingDurationMin),
              NumberSpinner(
                value: _minDuration,
                min: 30,
                max: 180,
                step: 5,
                onChanged: (v) => setState(() => _minDuration = v),
              ),
              const SizedBox(height: 8),
              Text(l.onboardingDurationMax),
              NumberSpinner(
                value: _maxDuration,
                min: 30,
                max: 180,
                step: 5,
                onChanged: (v) => setState(() => _maxDuration = v),
              ),
            ],
          ),
        ),
        _Section(
          title: l.onboardingTrainingDaysTitle,
          error: _errors['trainingDaysPerWeek'],
          child: NumberSpinner(
            value: _days,
            min: 1,
            max: 7,
            suffix: ' ${l.suffixDays(_days)}',
            onChanged: (v) => setState(() => _days = v),
          ),
        ),
        _Section(
          title: l.onboardingTrainingFocusTitle,
          error: _errors['trainingFocus'],
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in focusOptions)
                ChoiceChip(
                  label: Text(option.value),
                  selected: _focus == option.key,
                  onSelected: (_) => setState(() => _focus = option.key),
                ),
            ],
          ),
        ),
        _Section(
          title: l.onboardingCardioTitle,
          error: _errors['wantsCardio'],
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.onboardingCardioInclude),
            value: _wantsCardio,
            onChanged: (v) => setState(() => _wantsCardio = v),
          ),
        ),
        _Section(
          title: l.onboardingGymTimeTitle,
          error: _errors['preferredGymTime'],
          child: Row(
            children: [
              SizedBox(width: 64, child: _timeField(_hour, 'HH')),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 64, child: _timeField(_minute, 'MM')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l.salvar),
        ),
      ],
    );
  }

  Widget _timeField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 2,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(hintText: hint, counterText: ''),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.error});
  final String title;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
            if (error != null) ...[
              const SizedBox(height: 4),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

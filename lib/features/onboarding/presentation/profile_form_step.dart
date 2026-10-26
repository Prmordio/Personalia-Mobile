import '../../../core/validation/cpf_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers.dart';
import '../state/onboarding_controller.dart';
import 'widgets/step_scaffold.dart';

/// Two profile steps with explicit terms acceptance before submission.
class ProfileFormStep extends ConsumerStatefulWidget {
  const ProfileFormStep({super.key});
  @override
  ConsumerState<ProfileFormStep> createState() => _ProfileFormStepState();
}

class _ProfileFormStepState extends ConsumerState<ProfileFormStep> {
  final _forms = [GlobalKey<FormState>(), GlobalKey<FormState>()];
  int _page = 0;
  late final OnboardingState _initial = ref.read(onboardingControllerProvider);
  late final _name = TextEditingController(text: _initial.name);
  late final _cpf = TextEditingController(text: _initial.cpf);
  late final _birthDate = TextEditingController(
    text: _initial.birthDate == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(_initial.birthDate!),
  );
  late final _weight = TextEditingController(
    text: _initial.weight?.toString() ?? '',
  );
  late final _height = TextEditingController(
    text: _initial.height?.toString() ?? '',
  );
  late final _email = TextEditingController(text: _initial.email);
  /// Email já comprovado no cadastro não pode ser trocado aqui; sessão antiga sem email digita.
  late final bool _emailLocked = _initial.email.isNotEmpty;
  late String? _gender = _initial.gender;
  late bool _accepted = _initial.disclaimerAccepted;
  bool _showValidationHint = false;
  bool _leaving = false;
  bool _logoutFailed = false;

  DateTime? _parseDate() {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(_birthDate.text.trim());
    } on FormatException {
      return null;
    }
  }

  Future<void> _backToLogin() async {
    if (_leaving || ref.read(onboardingControllerProvider).loading) return;
    final storage = ref.read(tokenStorageProvider);
    final refresh = ref.read(authRefreshProvider);
    setState(() {
      _leaving = true;
      _logoutFailed = false;
    });
    try {
      await storage.clear();
      if (mounted) ref.invalidate(onboardingControllerProvider);
      refresh.value++;
    } catch (_) {
      if (mounted) {
        setState(() {
          _leaving = false;
          _logoutFailed = true;
        });
      }
    }
  }

  void _previous() {
    FocusScope.of(context).unfocus();
    setState(() {
      _page = 0;
      _showValidationHint = false;
    });
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateUtils.dateOnly(DateTime.now());
    final first = DateTime(1900);
    final current = _parseDate();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          current != null && !current.isBefore(first) && !current.isAfter(now)
          ? current
          : DateTime(now.year - 30, now.month, now.day),
      firstDate: first,
      lastDate: now,
    );
    if (picked != null && mounted) {
      _birthDate.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!_accepted) return;
    if (!_forms[_page].currentState!.validate()) {
      setState(() => _showValidationHint = true);
      return;
    }
    setState(() => _showValidationHint = false);
    FocusScope.of(context).unfocus();
    if (_page == 0) {
      setState(() => _page = 1);
      return;
    }
    final saved = await ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
          name: _name.text.trim(),
          cpf: _cpf.text.replaceAll(RegExp(r'\D'), ''),
          gender: _gender!,
          birthDate: _parseDate()!,
          weight: num.parse(_weight.text.replaceAll(',', '.')),
          height: num.parse(_height.text.replaceAll(',', '.')),
          email: _email.text.trim(),
          accepted: _accepted,
        );
    if (!saved && mounted) {
      final errors = ref.read(onboardingControllerProvider).fieldErrors;
      if ([
        'name',
        'cpf',
        'email',
        'accepted',
      ].any(errors.containsKey)) {
        _previous();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _cpf,
      _birthDate,
      _weight,
      _height,
      _email,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(onboardingControllerProvider);
    InputDecoration decoration(String label, String key, {String? hint}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: switch (state.fieldErrors[key]) {
            'errProfileCpf' => l.errProfileCpf,
            'disclaimerCheckbox' => l.disclaimerCheckbox,
            final message => message,
          },
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
    String? positiveNumber(String? value, String error) {
      final number = num.tryParse((value ?? '').replaceAll(',', '.'));
      return number == null || !number.isFinite || number <= 0 ? error : null;
    }

    return StepScaffold(
      title: _page == 0
          ? l.onboardingProfileFormTitle
          : l.onboardingBodyFormTitle,
      subtitle: l.onboardingProfileFormSubtitle,
      loading: state.loading || _leaving,
      onBack: _page == 0 ? _backToLogin : _previous,
      backLabel: _page == 0 ? l.onboardingBackToLogin : null,
      error:
          (_logoutFailed ? l.genericError : null) ??
          state.error ??
          state.fieldErrors.values.firstOrNull ??
          (_showValidationHint ? l.onboardingProfileFormError : null),
      buttonLabel: l.continuar,
      onContinue: _accepted ? _submit : null,
      child: AbsorbPointer(
        absorbing: state.loading || _leaving,
        child: Form(
          key: _forms[_page],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: l.onboardingProfileProgress(_page + 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.onboardingProfileProgress(_page + 1)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (_page + 1) / 2),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (_page == 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  isExpanded: true,
                  decoration: decoration(l.profileFieldGender, 'gender'),
                  items: [
                    DropdownMenuItem(
                      value: 'Masculino',
                      child: Text(l.genderMale),
                    ),
                    DropdownMenuItem(
                      value: 'Feminino',
                      child: Text(l.genderFemale),
                    ),
                  ],
                  onChanged: (value) => setState(() => _gender = value),
                  validator: (v) => v == null ? l.errProfileGender : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _birthDate,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  decoration:
                      decoration(
                        l.profileFieldBirthDate,
                        'birthDate',
                        hint: 'dd/mm/yyyy',
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: l.onboardingPickDate,
                          onPressed: _pickBirthDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                        ),
                      ),
                  inputFormatters: [_DateInputFormatter()],
                  validator: (_) =>
                      _parseDate() == null ||
                          _parseDate()!.isBefore(DateTime(1900)) ||
                          _parseDate()!.isAfter(DateTime.now())
                      ? l.errProfileBirthDate
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: decoration(
                          l.profileFieldWeight,
                          'weight',
                          hint: '70',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        validator: (v) => positiveNumber(v, l.errProfileWeight),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _height,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: decoration(
                          l.profileFieldHeight,
                          'height',
                          hint: '170',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        validator: (v) => positiveNumber(v, l.errProfileHeight),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (_page == 0) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: decoration(l.profileFieldName, 'name'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.errProfileName : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cpf,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: decoration(
                    l.onboardingCpfLabel,
                    'cpf',
                    hint: l.onboardingCpfHint,
                  ),
                  validator: (v) =>
                      !isValidCpf(v ?? '') ? l.errProfileCpf : null,
                ),
                const SizedBox(height: 8),
                Text(
                  l.onboardingCpfPrivacy,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  readOnly: _emailLocked,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: decoration(
                    l.profileFieldEmail,
                    'email',
                    hint: l.onboardingEmailHint,
                  ).copyWith(
                    suffixIcon: _emailLocked
                        ? const Icon(Icons.verified_outlined)
                        : null,
                  ),
                  validator: (v) =>
                      !RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch((v ?? '').trim())
                      ? l.errAppAccessEmail
                      : null,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://personalia.fit/legal'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(l.disclaimerReadTerms),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _accepted,
                  onChanged: (value) =>
                      setState(() => _accepted = value ?? false),
                  title: Text(l.disclaimerCheckbox),
                ),
                if (state.fieldErrors['accepted'] != null)
                  Text(
                    state.fieldErrors['accepted']!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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

/// Formats both typing and pasted dates while preserving the cursor position.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, digits.length.clamp(0, 8));
    String format(String value) {
      final buffer = StringBuffer();
      for (var i = 0; i < value.length; i++) {
        if (i == 2 || i == 4) buffer.write('/');
        buffer.write(value[i]);
      }
      return buffer.toString();
    }

    final offset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final before = newValue.text
        .substring(0, offset)
        .replaceAll(RegExp(r'\D'), '');
    final cursorDigits = before.length.clamp(0, limited.length);
    final text = format(limited);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: format(limited.substring(0, cursorDigits)).length,
      ),
    );
  }
}

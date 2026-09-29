import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/app_api.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../state/account_providers.dart';

final _brDate = DateFormat('dd/MM/yyyy');
const _genders = ['Masculino', 'Feminino'];

/// "Atualizar meu perfil" (Menu). Usa o mesmo PUT do onboarding — as validações são as do
/// backend (mesmas mensagens do bot). O email é só leitura: ele é o login e só muda com
/// código de confirmação (fluxo de acesso), nunca por aqui.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(accountStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Atualizar meu perfil')),
      body: statusAsync.when(
        data: (status) => _ProfileForm(profile: status.profile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Não foi possível carregar seu perfil.')),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});
  final OnboardingProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final _name = TextEditingController(text: widget.profile.name ?? '');
  late final _weight = TextEditingController(text: widget.profile.weight?.toString() ?? '');
  late final _height = TextEditingController(text: widget.profile.height?.toString() ?? '');
  late final _cpf = TextEditingController(text: _formatCpf(widget.profile.cpf ?? ''));
  late String? _gender = _genders.contains(widget.profile.gender) ? widget.profile.gender : null;
  late DateTime? _birthDate = _parseBr(widget.profile.birthDate);
  Map<String, String> _errors = const {};
  bool _saving = false;

  static DateTime? _parseBr(String? value) {
    try {
      return value == null || value.isEmpty ? null : _brDate.parseStrict(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final weight = num.tryParse(_weight.text.replaceAll(',', '.'));
    final height = num.tryParse(_height.text.replaceAll(',', '.'));
    final local = <String, String>{
      if (_name.text.trim().isEmpty) 'name': 'Informe seu nome.',
      if (_gender == null) 'gender': 'Selecione o gênero.',
      if (_birthDate == null) 'birthDate': 'Informe sua data de nascimento.',
      if (weight == null) 'weight': 'Informe seu peso em kg.',
      if (height == null) 'height': 'Informe sua altura em cm.',
      if (_cpf.text.isNotEmpty && _cpf.text.replaceAll(RegExp(r'\D'), '').length != 11) 'cpf': 'O CPF tem 11 dígitos.',
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
      await ref.read(onboardingApiProvider).updateProfile(
            name: _name.text.trim(),
            gender: _gender!,
            birthDate: _brDate.format(_birthDate!),
            weight: weight!,
            height: height!,
            email: widget.profile.email ?? '',
            cpf: _cpf.text.replaceAll(RegExp(r'\D'), ''),
          );
      ref.invalidate(accountStatusProvider);
      ref.invalidate(progressProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Perfil atualizado ✅')));
      navigator.maybePop();
    } on OnboardingValidationException catch (e) {
      setState(() => _errors = e.errors);
    } on OnboardingConflictException catch (e) {
      setState(() => _errors = {e.field: e.message});
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente novamente.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Field(
          label: 'Nome',
          error: _errors['name'],
          child: TextField(controller: _name, textCapitalization: TextCapitalization.words),
        ),
        _Field(
          label: 'Gênero',
          error: _errors['gender'],
          child: Wrap(
            spacing: 8,
            children: [
              for (final g in _genders)
                ChoiceChip(label: Text(g), selected: _gender == g, onSelected: (_) => setState(() => _gender = g)),
            ],
          ),
        ),
        _Field(
          label: 'Data de nascimento',
          error: _errors['birthDate'],
          child: OutlinedButton(
            onPressed: _pickBirthDate,
            child: Text(_birthDate != null ? _brDate.format(_birthDate!) : 'Selecionar data'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Peso (kg)',
                error: _errors['weight'],
                child: TextField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                label: 'Altura (cm)',
                error: _errors['height'],
                child: TextField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
          ],
        ),
        _Field(
          label: 'CPF (opcional)',
          error: _errors['cpf'],
          child: TextField(
            controller: _cpf,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11), _CpfFormatter()],
            decoration: const InputDecoration(hintText: '000.000.000-00'),
          ),
        ),
        if ((widget.profile.phone ?? '').isNotEmpty)
          _Field(
            label: 'Telefone',
            child: TextFormField(
              initialValue: _formatPhone(widget.profile.phone!),
              enabled: false,
              decoration: const InputDecoration(helperText: 'É o seu número do WhatsApp — identifica sua conta.'),
            ),
          ),
        _Field(
          label: 'Email',
          error: _errors['email'],
          child: TextFormField(
            initialValue: widget.profile.email ?? '',
            enabled: false,
            decoration: const InputDecoration(helperText: 'O email é o seu login e não pode ser alterado aqui.'),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.error});
  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

String _formatCpf(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length != 11) return d;
  return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
}

/// +55 (11) 98765-4321
String _formatPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (!d.startsWith('55') || (d.length != 12 && d.length != 13)) return '+$d';
  final local = d.substring(4);
  final split = local.length - 4;
  return '+55 (${d.substring(2, 4)}) ${local.substring(0, split)}-${local.substring(split)}';
}

/// Máscara 000.000.000-00 enquanto digita (recebe só dígitos, até 11).
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Chave l10n do erro do CPF, ou `null` se ele é válido.
///
/// Separa os dois casos para a mensagem não enganar o usuário:
/// - `errProfileCpf`: não tem 11 dígitos;
/// - `errProfileCpfInvalid`: tem 11 dígitos, mas são todos iguais ou os dígitos verificadores
///   não batem (normalmente erro de digitação).
String? cpfErrorKey(String value) {
  final cpf = value.replaceAll(RegExp(r'\D'), '');
  if (cpf.length != 11) return 'errProfileCpf';
  if (cpf.split('').toSet().length == 1) return 'errProfileCpfInvalid';
  final digits = cpf.split('').map(int.parse).toList();
  for (var position = 9; position <= 10; position++) {
    var sum = 0;
    for (var i = 0; i < position; i++) {
      sum += digits[i] * (position + 1 - i);
    }
    final remainder = sum % 11;
    final expected = remainder < 2 ? 0 : 11 - remainder;
    if (digits[position] != expected) return 'errProfileCpfInvalid';
  }
  return null;
}

/// Validates CPF length, repeated digits and both check digits locally.
bool isValidCpf(String value) => cpfErrorKey(value) == null;

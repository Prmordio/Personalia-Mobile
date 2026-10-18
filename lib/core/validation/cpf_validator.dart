/// Validates CPF length, repeated digits and both check digits locally.
bool isValidCpf(String value) {
  final cpf = value.replaceAll(RegExp(r'\D'), '');
  if (cpf.length != 11 || cpf.split('').toSet().length == 1) return false;
  final digits = cpf.split('').map(int.parse).toList();
  for (var position = 9; position <= 10; position++) {
    var sum = 0;
    for (var i = 0; i < position; i++) {
      sum += digits[i] * (position + 1 - i);
    }
    final remainder = sum % 11;
    final expected = remainder < 2 ? 0 : 11 - remainder;
    if (digits[position] != expected) return false;
  }
  return true;
}

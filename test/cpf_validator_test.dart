import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/validation/cpf_validator.dart';

void main() {
  test('should_accept_valid_cpf_with_or_without_mask', () {
    expect(cpfErrorKey('52998224725'), isNull);
    expect(cpfErrorKey('529.982.247-25'), isNull);
    expect(cpfErrorKey('91171091249'), isNull);
    expect(isValidCpf('91171091249'), isTrue);
  });

  test('should_report_length_error_only_when_not_11_digits', () {
    expect(cpfErrorKey(''), 'errProfileCpf');
    expect(cpfErrorKey('5299822472'), 'errProfileCpf');
  });

  test('should_report_invalid_when_11_digits_but_check_digits_do_not_match', () {
    // Caso reportado: 11 dígitos, verificadores errados — antes mostrava "O CPF tem 11 dígitos.".
    expect(cpfErrorKey('91171091219'), 'errProfileCpfInvalid');
    expect(cpfErrorKey('52998224724'), 'errProfileCpfInvalid');
    expect(cpfErrorKey('11111111111'), 'errProfileCpfInvalid');
    expect(isValidCpf('91171091219'), isFalse);
  });
}

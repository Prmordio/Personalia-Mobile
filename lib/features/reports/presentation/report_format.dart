import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formatação de números e datas dos relatórios no idioma escolhido no app
/// (vírgula decimal em pt/es, ponto em en; dd/MM vs MM/dd conforme o locale).
class ReportFormat {
  ReportFormat.of(BuildContext context) : _locale = Localizations.localeOf(context).toLanguageTag();

  final String _locale;

  /// Até [decimals] casas, sem zeros à direita (`2,5`, `40`). `null` vira travessão.
  String number(num? value, {int decimals = 1}) {
    if (value == null) return '—';
    final format = NumberFormat.decimalPattern(_locale)..maximumFractionDigits = decimals;
    return format.format(value);
  }

  String kg(num? value) => '${number(value)} kg';

  /// Variação com sinal explícito: `+2,5 kg`, `-1 kg`.
  String signedKg(num value) => '${value > 0 ? '+' : ''}${kg(value)}';

  String shortDate(DateTime date) => DateFormat.Md(_locale).format(date);

  String fullDate(DateTime date) => DateFormat.yMd(_locale).format(date);
}

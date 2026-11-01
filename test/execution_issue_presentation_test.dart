import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/execution_analysis/domain/exercise_rule_set.dart';
import 'package:personalia_app/features/execution_analysis/presentation/issue_presentation.dart';

RuleCheck _check(double target, String unit) => RuleCheck(
      id: 'x',
      signal: 'heel_lift',
      agg: Aggregation.max,
      op: CheckOp.lte,
      target: target,
      unit: unit,
      severity: IssueSeverity.medium,
      weight: 10,
      joints: const [],
      cue: const {'pt': ''},
    );

void main() {
  group('formatMeasured', () {
    test('should_add_a_decimal_when_rounding_would_match_the_target', () {
      expect(formatMeasured(8.4, _check(8, 'pct_shin')), '8.4%');
      expect(formatMeasured(95.3, _check(95, 'deg')), '95.3°');
      expect(formatMeasured(760, _check(800, 'ms')), '0.76s');
    });

    test('should_keep_default_precision_when_clearly_different', () {
      expect(formatMeasured(11.6, _check(8, 'pct_shin')), '12%');
      expect(formatMeasured(104.2, _check(95, 'deg')), '104°');
      expect(formatMeasured(500, _check(800, 'ms')), '0.5s');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'measures_test.dart' as measures;
import 'signup_test.dart' as signup;
import 'swap_test.dart' as swap;
import 'workout_test.dart' as workout;

/// Todos os fluxos num app só. No celular cada arquivo de integration_test/ vira um APK próprio
/// (build + instalação, ~70s cada); agrupados aqui, o scripts/e2e/run.sh compila e instala uma
/// vez. O nome do grupo é o do arquivo: é por ele que o run.sh filtra (T="signup workout"), que o
/// E2eEnv.seededEmail acha o usuário e que o report.py separa o resumo.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('measures', measures.main);
  group('signup', signup.main);
  group('swap', swap.main);
  group('workout', workout.main);
}

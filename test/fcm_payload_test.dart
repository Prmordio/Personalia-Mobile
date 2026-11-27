import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/notifications/fcm_service.dart';

void main() {
  group('payload da notificação local', () {
    test('push em primeiro plano ida e volta preserva o tipo', () {
      final payload = FcmService.pushPayload('medidas_regua');
      expect(FcmService.isPushPayload(payload), isTrue);
      expect(FcmService.pushTypeFromPayload(payload), 'medidas_regua');
    });

    test('push sem tipo continua sendo push (vai para a home)', () {
      final payload = FcmService.pushPayload(null);
      expect(FcmService.isPushPayload(payload), isTrue);
      expect(FcmService.pushTypeFromPayload(payload), isNull);
      expect(FcmService.routeForType(null), '/home');
    });

    test('alarme do descanso (sem payload) não é tratado como push', () {
      expect(FcmService.isPushPayload(null), isFalse);
      expect(FcmService.isPushPayload(''), isFalse);
    });
  });

  test('campanha do push só aceita tipos conhecidos', () {
    expect(FcmService.pushCampaign('medidas_regua'), 'medidas_regua');
    expect(FcmService.pushCampaign('subscription_funnel_d3'), 'subscription_funnel');
    expect(FcmService.pushCampaign('qualquer'), 'other');
    expect(FcmService.pushCampaign(null), 'none');
  });
}

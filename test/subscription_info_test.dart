import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/home/data/app_api.dart';

void main() {
  group('SubscriptionInfo store state', () {
    test('a Google Play grace period is a pending payment, not a scheduled charge', () {
      final info = SubscriptionInfo.fromJson({
        'isValid': true,
        'status': 'active',
        'dueDate': '2026-11-20T15:30:24.000Z',
        'isFreeTrial': false,
        'provider': 'google',
        'storeState': 'grace',
      });
      expect(info.provider, 'google');
      expect(info.isInGracePeriod, isTrue);
      expect(info.isRenewalCanceled, isFalse);
      expect(info.dueDate, DateTime.utc(2026, 11, 20, 15, 30, 24));
    });

    test('a canceled renewal keeps access until the due date', () {
      final info = SubscriptionInfo.fromJson({
        'isValid': true,
        'storeState': 'canceled',
        'provider': 'apple',
      });
      expect(info.isRenewalCanceled, isTrue);
      expect(info.isInGracePeriod, isFalse);
    });

    test('Mercado Pago and older backends carry no store state', () {
      final info = SubscriptionInfo.fromJson({'isValid': true, 'status': 'authorized'});
      expect(info.provider, isNull);
      expect(info.storeState, isNull);
      expect(info.isInGracePeriod, isFalse);
      expect(info.isRenewalCanceled, isFalse);
    });

    test('a state without access never shows as grace or canceled', () {
      final info = SubscriptionInfo.fromJson({'isValid': false, 'storeState': 'grace'});
      expect(info.isInGracePeriod, isFalse);
    });
  });
}

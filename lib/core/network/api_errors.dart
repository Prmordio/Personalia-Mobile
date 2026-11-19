import 'package:dio/dio.dart';

/// O servidor recusou porque o recurso exige assinatura
/// (trainer: AppFeatureAccessGuard → 403 `{ reason: 'subscription_required' }`).
class SubscriptionRequiredException implements Exception {
  const SubscriptionRequiredException();
}

bool isSubscriptionRequired(Object error) {
  if (error is SubscriptionRequiredException) return true;
  if (error is! DioException || error.response?.statusCode != 403) return false;
  final data = error.response?.data;
  // O gateway pode repassar o corpo inteiro do Nest ou só a mensagem.
  final body = data is Map && data['message'] is Map ? data['message'] : data;
  return body is Map && body['reason'] == 'subscription_required';
}

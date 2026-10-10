import '../telemetry/app_telemetry.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Sistema exibe automaticamente quando há notification payload no FCM.
  // Nada a fazer aqui — apenas garantir que o handler esteja registrado.
}

/// Canal FCM para notificações gerais (diferente do canal rest_timer).
const _kChannelId = 'personalia_push';
const _kChannelName = 'Notificações PersonaliA';

class FcmService {
  FcmService._();
  static final instance = FcmService._();

  // Lazy getter — evita acesso ao Firebase antes de initializeApp() (ex: em testes).
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final _localPlugin = FlutterLocalNotificationsPlugin();

  /// Rota pendente capturada quando o app estava encerrado e o usuário tocou na notificação.
  String? _pendingRoute;
  String? get pendingRoute => _pendingRoute;
  void clearPendingRoute() => _pendingRoute = null;

  /// Callback injetado pelo widget raiz para navegar via GoRouter.
  void Function(String route)? onRoute;

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // iOS: exibir notificação mesmo com o app em foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Android: inicializar plugin local para foreground (iOS usa a config acima)
    await _localPlugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _localPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
        ));

    // Foreground (Android não exibe notificação FCM automaticamente)
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Background → foreground via toque na notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageRoute);

    // App encerrado: captura rota para processar depois que o router estiver pronto
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      AppTelemetry.instance.event('push_opened');
      _pendingRoute = _routeFromMessage(initial);
    }
  }

  /// Chama após login para registrar/atualizar o FCM token no backend.
  /// [callback] faz o POST para users-api.
  Future<void> registerToken(
    Future<void> Function(String token, String platform) callback,
  ) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        await callback(token, platform);
      }
      _messaging.onTokenRefresh.listen((newToken) async {
        try {
          final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          await callback(newToken, platform);
        } catch (e) {
          debugPrint('[FCM] onTokenRefresh callback failed: $e');
        }
      });
    } catch (e) {
      debugPrint('[FCM] registerToken failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final route = _routeFromMessage(message);
    _localPlugin.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: route,
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route == null || route.isEmpty) return;
    _navigate(route);
  }

  void _handleMessageRoute(RemoteMessage message) {
    AppTelemetry.instance.event('push_opened');
    final route = _routeFromMessage(message);
    if (route != null) _navigate(route);
  }

  void _navigate(String route) {
    if (onRoute != null) {
      onRoute!(route);
    } else {
      _pendingRoute = route;
    }
  }

  String? _routeFromMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    switch (type) {
      case 'rest_timer':
        return '/workout/today';
      case 'workout_regua':
      case 'stale_workout':
        return '/workout/today';
      case 'medidas_regua':
        return '/reports/body';
      case 'weekly_summary':
        return '/reports';
      case 'subscription':
      case 'subscription_expired':
      case 'subscription_funnel':
        return '/home';
      default:
        return '/home';
    }
  }
}

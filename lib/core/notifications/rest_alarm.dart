import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Aviso de fim do descanso. [schedule] agenda para disparar mesmo com o app em segundo plano
/// ou a tela desligada; [fireNow] avisa na hora quando o cronômetro termina com o app aberto.
abstract class RestAlarm {
  Future<void> schedule({required int id, required Duration after, required String exerciseName});
  Future<void> cancel(int id);
  Future<void> fireNow({required int id, required String exerciseName});
}

/// Textos da notificação no idioma escolhido no app. Injetados pela raiz do app (que tem
/// acesso ao AppLocalizations) para esta camada não depender de l10n.
class RestAlarmMessages {
  const RestAlarmMessages({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  /// Padrão até o primeiro frame com locale resolvido.
  static final fallback = RestAlarmMessages(
    title: '⏱️ Descanso encerrado!',
    body: (exercise) => 'Hora da próxima série de $exercise 💪',
    channelName: 'Fim do descanso',
    channelDescription: 'Avisa quando o descanso entre as séries termina',
  );

  final String title;
  final String Function(String exerciseName) body;
  final String channelName;
  final String channelDescription;
}

/// Notificação local (sem servidor): canal de alta prioridade com som, para o aviso tocar
/// mesmo no bolso. Um id por exercício — a notificação agendada e a imediata se substituem
/// (onlyAlertOnce evita tocar duas vezes).
class LocalNotificationRestAlarm implements RestAlarm {
  LocalNotificationRestAlarm._();
  static final instance = LocalNotificationRestAlarm._();

  static const _channelId = 'rest_timer';

  RestAlarmMessages _messages = RestAlarmMessages.fallback;

  /// Atualiza os textos quando o idioma do app muda.
  void localize(RestAlarmMessages messages) => _messages = messages;

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _messages.channelName,
      channelDescription: _messages.channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      onlyAlertOnce: true,
    ),
    iOS: const DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
  );

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionAsked = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permissão pedida só no primeiro descanso, não na abertura do app.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Rest alarm init failed: $e');
    }
  }

  Future<void> _ensurePermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      sound: true,
    );
  }

  @override
  Future<void> schedule({required int id, required Duration after, required String exerciseName}) async {
    if (!_initialized) return;
    try {
      await _ensurePermission();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Horário exato quando o sistema permite; senão o Android pode atrasar um pouco (e o
      // fireNow cobre o caso do app aberto).
      final exact = await android?.canScheduleExactNotifications() ?? true;
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: _details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: _messages.title,
        body: _messages.body(exerciseName),
      );
    } catch (e) {
      debugPrint('Rest alarm schedule failed: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  @override
  Future<void> fireNow({required int id, required String exerciseName}) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: id,
        title: _messages.title,
        body: _messages.body(exerciseName),
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Rest alarm show failed: $e');
    }
  }
}

final restAlarmProvider = Provider<RestAlarm>((ref) => LocalNotificationRestAlarm.instance);

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Optional native services must not prevent the app from becoming usable.
Future<bool> runStartupTask(
  String name,
  Future<void> Function() initialize, {
  Duration timeout = const Duration(seconds: 15),
  Future<void>? cancelled,
}) async {
  try {
    await Future.any<void>([
      Future<void>.sync(initialize),
      if (cancelled != null)
        cancelled.then<void>((_) => throw const _StartupTaskCancelled()),
    ]).timeout(timeout);
    return true;
  } catch (error) {
    if (error is _StartupTaskCancelled) return false;
    final reason = error is PlatformException
        ? error.code
        : error.runtimeType.toString();
    debugPrint('[Startup] $name failed: $reason');
    return false;
  }
}

class _StartupTaskCancelled implements Exception {
  const _StartupTaskCancelled();
}

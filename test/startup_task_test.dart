import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/core/startup_task.dart';

void main() {
  test(
    'disposing startup stops waiting for an unresponsive native service',
    () async {
      final native = Completer<void>();
      final cancelled = Completer<void>();
      final task = runStartupTask(
        'firebase',
        () => native.future,
        cancelled: cancelled.future,
      );
      cancelled.complete();
      expect(await task, isFalse);
      native.complete();
    },
  );

  test('a failed native service does not abort startup', () async {
    expect(
      await runStartupTask('notifications', () async {
        throw PlatformException(code: 'permission_failed');
      }),
      isFalse,
    );
    expect(await runStartupTask('next_service', () async {}), isTrue);
  });

  test('a native call that never responds is bounded', () async {
    final pending = Completer<void>();
    expect(
      await runStartupTask(
        'firebase',
        () => pending.future,
        timeout: const Duration(milliseconds: 10),
      ),
      isFalse,
    );
    pending.complete();
  });

  test('synchronous plugin initialization errors are also contained', () async {
    expect(
      await runStartupTask('plugin', () => throw StateError('unavailable')),
      isFalse,
    );
  });
}

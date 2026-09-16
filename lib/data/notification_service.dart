import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// System notifications, behind an interface so tests never touch the
/// platform channel (widget tests have no plugin implementation).
abstract class NotificationService {
  /// Prepares the plugin once at startup. Must not throw: a device that
  /// cannot show notifications still runs the rest of the app.
  Future<void> init();

  /// Asks for the Android 13+ notification permission.
  ///
  /// Returns `true` when notifications can be shown. Older Android grants
  /// it at install time, so this answers `true` there without a prompt.
  Future<bool> requestPermission();

  Future<void> show({
    required int id,
    required String title,
    required String body,
  });
}

/// [NotificationService] backed by flutter_local_notifications.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// False until [init] succeeds; [show] is a no-op before that so a failed
  /// init degrades to "no notification" instead of a crash.
  bool _ready = false;

  // One channel for every grant reminder, so a user can mute them in
  // system settings without muting anything else.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'grant_reminders',
      'Grant reminders',
      channelDescription: 'Alerts when a grant opens for a reminder you set.',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> init() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = ok ?? false;
    } catch (error) {
      // desktop builds have no Android settings to initialise with
      debugPrint('Notifications unavailable: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return false;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}

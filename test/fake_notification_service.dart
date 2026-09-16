import 'package:bmit2073_asgm/data/notification_service.dart';

/// Records notifications instead of showing them: widget tests have no
/// platform implementation of the notifications plugin.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true});

  /// What [requestPermission] answers, so both prompt outcomes are testable.
  final bool permissionGranted;

  final List<({String title, String body})> shown = [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    shown.add((title: title, body: body));
  }
}

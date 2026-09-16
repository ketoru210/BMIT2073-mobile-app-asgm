// The reminder check runs on every launch, sign-in and resume, so both of
// its failure modes reach a user: a reminder that never fires, and one
// that fires on every launch or for a grant the user opted out of.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/gdp_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/data/local_grant_repository.dart';
import 'package:bmit2073_asgm/data/policy_source.dart';
import 'package:bmit2073_asgm/data/user_repository.dart';
import 'package:bmit2073_asgm/models/grant.dart';
import 'package:bmit2073_asgm/models/sector.dart';
import 'package:bmit2073_asgm/state/app_state.dart';

import 'fake_location_service.dart';
import 'fake_notification_service.dart';

void main() {
  late FakeNotificationService notifications;
  late LocalGrantReminderRepository reminders;
  late AppState app;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // An empty but already-seeded grants store: the bundled seed would
    // otherwise decide what matches.
    SharedPreferences.setMockInitialValues({
      'grant.seeded': true,
      'grant.grants': '[]',
    });
    notifications = FakeNotificationService();
    reminders = LocalGrantReminderRepository();
    app = AppState(
      repository: GdpRepository(),
      policySource: PolicySource(),
      catalogue: const PolicyCatalogue(
        version: 0,
        policies: [],
        isRemote: false,
      ),
      users: LocalUserRepository(),
      grants: LocalGrantRepository(),
      reminders: reminders,
      notifications: notifications,
      location: FakeLocationService.at(6.44, 100.20),
    );
  });

  /// Publishes an open grant; published now unless [publishedAt] is given.
  Future<void> publish({
    required String name,
    String? state = 'Perlis',
    Sector? sector = Sector.mining,
    int? maxAmountRm = 50000,
    DateTime? publishedAt,
  }) {
    return LocalGrantAdminRepository().publish(
      Grant(
        id: 'grant-$name',
        name: name,
        agency: 'Demo Agency',
        state: state,
        sector: sector,
        maxAmountRm: maxAmountRm,
        deadline: DateTime.now().add(const Duration(days: 30)),
        sourceUrl: 'https://example.com',
        criteriaNote: 'Demo criteria.',
        description: 'Demo grant.',
        publishedBy: 'admin',
        publishedAt: publishedAt ?? DateTime.now(),
        isOpen: true,
      ),
    );
  }

  test('a grant for another state keeps the reminder waiting', () async {
    await reminders.create(state: 'Perlis', sector: Sector.mining);
    await publish(name: 'Selangor Fund', state: 'Selangor');

    await app.checkGrantReminders();

    expect(notifications.shown, isEmpty);
    expect(await reminders.active(), hasLength(1));
  });

  test('a new grant for the pair notifies once and fulfils it', () async {
    await reminders.create(state: 'Perlis', sector: Sector.mining);
    await publish(name: 'Perlis Mining Fund');

    await app.checkGrantReminders();

    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.title, contains('Perlis · Mining'));
    expect(notifications.shown.single.body, contains('Perlis Mining Fund'));
    expect(await reminders.active(), isEmpty);

    // the next launch must not notify about the same grant again
    await app.checkGrantReminders();
    expect(notifications.shown, hasLength(1));
  });

  test('a grant published before the reminder does not fire it', () async {
    await publish(
      name: 'Old Perlis Fund',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await reminders.create(state: 'Perlis', sector: Sector.mining);

    await app.checkGrantReminders();

    expect(notifications.shown, isEmpty);
  });

  test('a nationwide grant only counts when the user opted in', () async {
    await reminders.create(state: 'Perlis', sector: Sector.mining);
    await publish(name: 'Nationwide Mining Fund', state: null);

    await app.checkGrantReminders();
    expect(notifications.shown, isEmpty);

    await reminders.create(
      state: 'Perlis',
      sector: Sector.mining,
      includeAllStates: true,
    );
    await publish(name: 'Second Nationwide Fund', state: null);

    await app.checkGrantReminders();
    expect(notifications.shown, hasLength(1));
  });

  test('an any-sector grant only counts when the user opted in', () async {
    await reminders.create(
      state: 'Perlis',
      sector: Sector.mining,
      includeAllSectors: true,
    );
    await publish(name: 'Perlis Any Sector Fund', sector: null);

    await app.checkGrantReminders();

    expect(notifications.shown, hasLength(1));
  });

  test('the minimum amount filters out smaller grants', () async {
    await reminders.create(
      state: 'Perlis',
      sector: Sector.mining,
      minAmountRm: 100000,
    );
    await publish(name: 'Small Perlis Fund', maxAmountRm: 20000);

    await app.checkGrantReminders();
    expect(notifications.shown, isEmpty);

    // no stated ceiling is treated as meeting any minimum
    await publish(name: 'Uncapped Perlis Fund', maxAmountRm: null);

    await app.checkGrantReminders();
    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.body, contains('Uncapped Perlis Fund'));
  });
}

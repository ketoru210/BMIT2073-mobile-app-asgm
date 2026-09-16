// A reminder that fires twice, or cannot be set again after it fired,
// fails silently on the device. These pin the set / restart / fulfil
// rules against the local stub, which shares the contract with Supabase.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bmit2073_asgm/data/local_grant_reminder_repository.dart';
import 'package:bmit2073_asgm/models/sector.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('a new reminder is active and findable by its pair', () async {
    final repo = LocalGrantReminderRepository();
    await repo.create(state: 'Perlis', sector: Sector.mining);

    final found = await repo.find(state: 'Perlis', sector: Sector.mining);
    expect(found, isNotNull);
    expect(found!.isActive, isTrue);
    expect(await repo.active(), hasLength(1));

    // a different sector in the same state is a different reminder
    expect(
      await repo.find(state: 'Perlis', sector: Sector.services),
      isNull,
    );
  });

  test('setting the same pair twice keeps a single reminder', () async {
    final repo = LocalGrantReminderRepository();
    await repo.create(state: 'Perlis', sector: Sector.mining);
    await repo.create(state: 'Perlis', sector: Sector.mining);

    expect(await repo.active(), hasLength(1));
  });

  test('a fulfilled reminder stops being active', () async {
    final repo = LocalGrantReminderRepository();
    final reminder = await repo.create(state: 'Perlis', sector: Sector.mining);
    await repo.fulfil(reminder.id, 'grant-1');

    expect(await repo.active(), isEmpty);
    expect(await repo.find(state: 'Perlis', sector: Sector.mining), isNull);
  });

  test('a pair can be set again after its reminder fired', () async {
    final repo = LocalGrantReminderRepository();
    final first = await repo.create(state: 'Perlis', sector: Sector.mining);
    await repo.fulfil(first.id, 'grant-1');

    await repo.create(state: 'Perlis', sector: Sector.mining);
    final again = await repo.find(state: 'Perlis', sector: Sector.mining);
    expect(again, isNotNull);
    expect(again!.grantId, isNull);
    expect(await repo.active(), hasLength(1));
  });

  test('cancelling removes the reminder', () async {
    final repo = LocalGrantReminderRepository();
    final reminder = await repo.create(state: 'Perlis', sector: Sector.mining);
    await repo.cancel(reminder.id);

    expect(await repo.active(), isEmpty);
  });
}

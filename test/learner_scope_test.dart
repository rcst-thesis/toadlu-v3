import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tudlo/features/learner/domain/learner_scope.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('listSavedProfiles returns every persisted profile', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);

    final saved = await controller.listSavedProfiles();
    expect(saved.map((p) => p.name).toSet(), {'Anna', 'Beto'});
  });

  test('switchTo makes the profile current in memory and on disk', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final anna = controller.profile!;
    await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);
    expect(controller.profile!.name, 'Beto');

    await controller.switchTo(anna);
    expect(controller.profile!.name, 'Anna');

    // Persisted too, not just in memory.
    final fresh = LearnerController();
    await fresh.loadSaved();
    expect(fresh.profile!.name, 'Anna');
  });

  test('deleteProfile on the current profile clears it from memory', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final id = controller.profile!.id;

    await controller.deleteProfile(id);

    expect(controller.profile, isNull);
    expect(await controller.listSavedProfiles(), isEmpty);
  });

  test('deleteProfile on a non-current profile leaves the current one alone',
      () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);
    final current = controller.profile!;
    await controller.createAndSave(name: 'Beto', grade: 2, energy: 60);
    // createAndSave always makes the newest one current -- switch back so
    // "Anna" is current while we delete "Beto".
    await controller.switchTo(current);

    final beto = (await controller.listSavedProfiles())
        .firstWhere((p) => p.name == 'Beto');
    await controller.deleteProfile(beto.id);

    expect(controller.profile?.name, 'Anna');
    expect(
      (await controller.listSavedProfiles()).map((p) => p.name),
      ['Anna'],
    );
  });

  test('loadLastUsedProfile survives logOut', () async {
    final controller = LearnerController();
    await controller.createAndSave(name: 'Anna', grade: 1, energy: 60);

    await controller.logOut();

    expect(controller.profile, isNull);
    expect((await controller.loadLastUsedProfile())?.name, 'Anna');
  });
}

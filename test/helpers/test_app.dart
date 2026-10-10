import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/app/app_scope.dart';
import 'package:slotly/app/theme.dart';
import 'package:slotly/core/utils/clock.dart';
import 'package:slotly/data/local/app_database.dart';
import 'package:slotly/data/local/database_storage.dart';
import 'package:slotly/data/local/local_context.dart';
import 'package:slotly/data/seed/demo_accounts.dart';
import 'package:slotly/data/seed/demo_seed.dart';
import 'package:slotly/features/auth/domain/app_user.dart';
import 'package:slotly/features/business/data/photo_picker.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/reminders/data/reminder_service.dart';

final testNow = DateTime(2026, 10, 5, 9);

void usePhoneSurface(WidgetTester tester, {double textScale = 1}) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.625;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

class FakePhotoPicker implements PhotoPicker {
  String? nextPath = '/picked/photo.jpg';
  int calls = 0;

  @override
  Future<String?> pickImage() async {
    calls++;
    return nextPath;
  }
}

Future<AppDependencies> createTestDependencies({
  Clock? clock,
  InMemoryReminderService? reminders,
  FakePhotoPicker? photoPicker,
  MemoryPhotoStorage? photoStorage,
  MemoryDatabaseStorage? storage,
}) => AppDependencies.create(
  storage: storage ?? MemoryDatabaseStorage(),
  photoStorage: photoStorage ?? MemoryPhotoStorage(),
  reminderService: reminders ?? InMemoryReminderService(),
  photoPicker: photoPicker ?? FakePhotoPicker(),
  clock: clock ?? () => testNow,
);

DemoAccount accountOf(String login) =>
    demoAccounts.firstWhere((a) => a.user.login == login);

AppUser userOf(String login) => accountOf(login).user;

Future<void> signIn(AppDependencies dependencies, String login) =>
    dependencies.session.signIn(login, accountOf(login).password);

class TestData {
  TestData._(this.database, this.clock);

  static Future<TestData> create({
    bool withActivity = false,
    DateTime? now,
  }) async {
    final database = await AppDatabase.inMemory();
    final data = TestData._(database, now ?? testNow);
    await DemoSeed(
      clock: () => data.clock,
      withActivity: withActivity,
    ).apply(database);
    return data;
  }

  final AppDatabase database;
  DateTime clock;
  AppUser? user;

  late final LocalContext context = LocalContext(
    database: database,
    currentUser: () => user,
    clock: () => clock,
  );

  void signInAs(String? login) => user = login == null ? null : userOf(login);
}

Future<AppDependencies> pumpApp(
  WidgetTester tester, {
  String? login,
  double textScale = 1,
  AppDependencies? dependencies,
}) async {
  usePhoneSurface(tester, textScale: textScale);
  final deps = dependencies ?? await createTestDependencies();
  if (login != null) await signIn(deps, login);
  addTearDown(deps.dispose);
  await tester.pumpWidget(SlotlyApp(dependencies: deps));
  await tester.pumpAndSettle();
  return deps;
}

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  ThemeData? theme,
  AppDependencies? dependencies,
}) async {
  usePhoneSurface(tester);
  final app = MaterialApp(
    theme: theme ?? AppTheme.light(),
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: screen,
  );
  await tester.pumpWidget(
    dependencies == null
        ? app
        : AppScope(dependencies: dependencies, child: app),
  );
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> scrollToIn(
  WidgetTester tester,
  Finder finder, {
  required Type screen,
}) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

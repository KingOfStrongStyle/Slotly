import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/client_shell.dart';
import 'package:slotly/app/owner_shell.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/auth/presentation/login_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> openLogin(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  }

  Finder field(String key) => find.byKey(ValueKey(key));

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.signInSubmit),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty fields are explained', (tester) async {
    await openLogin(tester);
    await submit(tester);
    expect(find.text(AppStrings.signInLoginRequired), findsOneWidget);
    expect(find.text(AppStrings.signInPasswordRequired), findsOneWidget);
  });

  testWidgets('a wrong password shows one neutral error', (tester) async {
    await openLogin(tester);
    await tester.enterText(field('login-field'), 'aliya');
    await tester.enterText(field('password-field'), 'oops');
    await submit(tester);
    expect(find.text(AppStrings.signInInvalid), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('password can be shown and hidden', (tester) async {
    await openLogin(tester);
    EditableText editable() => tester.widget<EditableText>(
      find.descendant(
        of: field('password-field'),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable().obscureText, isTrue);
    await tester.tap(find.byTooltip(AppStrings.signInShowPassword));
    await tester.pump();
    expect(editable().obscureText, isFalse);
  });

  testWidgets('a demo account fills the form; client gets the client shell', (
    tester,
  ) async {
    await openLogin(tester);
    expect(find.text(AppStrings.signInDemoNotice), findsOneWidget);
    await tester.ensureVisible(find.textContaining('aliya / aliya-demo'));
    await tester.tap(find.textContaining('aliya / aliya-demo'));
    await tester.pump();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, AppStrings.signInSubmit),
    );
    await submit(tester);
    expect(find.byType(ClientShell), findsOneWidget);
  });

  testWidgets('owner credentials open the owner shell', (tester) async {
    await openLogin(tester);
    await tester.enterText(field('login-field'), 'whiteline');
    await tester.enterText(field('password-field'), 'whiteline-demo');
    await submit(tester);
    expect(find.byType(OwnerShell), findsOneWidget);
    expect(find.text('Стоматология «Белая линия»'), findsWidgets);
  });
}

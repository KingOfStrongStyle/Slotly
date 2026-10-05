import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/gesture_checkin/data/mock_ticket_repository.dart';
import 'package:slotly/features/gesture_checkin/data/symbol_templates.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_classifier.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_point.dart';
import 'package:slotly/features/gesture_checkin/presentation/ticket_check_in_screen.dart';
import 'package:slotly/features/gesture_checkin/presentation/widgets/gesture_pad.dart';
import 'package:slotly/features/gesture_checkin/presentation/widgets/template_preview.dart';

import '../../helpers/gesture_shapes.dart';
import '../../helpers/test_app.dart';

void main() {
  final pad = find.byKey(const ValueKey('gesture-pad'));

  Future<void> pumpCheckIn(WidgetTester tester) => pumpScreen(
    tester,
    TicketCheckInScreen(
      classifier: GestureClassifier(templates: symbolTemplates),
      templates: symbolTemplates,
      tickets: const MockTicketRepository(),
      finishSymbol: finishSymbol,
    ),
  );

  /// Draws strokes given in a 0..100 box inside the pad, like a finger.
  Future<void> draw(WidgetTester tester, List<GestureStroke> strokes) async {
    final rect = tester.getRect(pad);
    Offset toScreen(GesturePoint p) => Offset(
      rect.left + rect.width * (0.15 + 0.7 * p.x / 100),
      rect.top + rect.height * (0.15 + 0.7 * p.y / 100),
    );
    for (final stroke in strokes) {
      final gesture = await tester.startGesture(toScreen(stroke.first));
      for (final point in stroke.skip(1)) {
        await gesture.moveTo(toScreen(point));
      }
      await gesture.up();
      await tester.pump();
    }
  }

  Future<void> recognize(WidgetTester tester) async {
    await tester.tap(find.text(AppStrings.checkInRecognize));
    await tester.pumpAndSettle();
  }

  String number(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('ticket-number'))).data!;

  List<GestureStroke> template(String label) =>
      symbolTemplates.firstWhere((t) => t.label == label).strokes;

  testWidgets('drawing shows strokes and recognized digits build a number', (
    tester,
  ) async {
    await pumpCheckIn(tester);
    expect(number(tester), AppStrings.checkInNumberPlaceholder);

    await draw(tester, [lineStroke(52, 5, 48, 95)]);
    final controller = tester
        .widget<GesturePad>(find.byType(GesturePad))
        .controller;
    expect(controller.strokes, hasLength(1));

    await recognize(tester);
    expect(number(tester), '1');
    expect(find.textContaining('Распознано: 1'), findsOneWidget);
    expect(controller.isEmpty, isTrue, reason: 'pad is cleared after success');

    await draw(tester, distort(template('7'), rotationDegrees: 4));
    await recognize(tester);
    expect(number(tester), '17');
  });

  testWidgets('an unknown gesture shows the error state and can be retried', (
    tester,
  ) async {
    await pumpCheckIn(tester);

    await draw(tester, [lineStroke(5, 50, 95, 52)]);
    await recognize(tester);

    expect(find.textContaining('Жест не распознан'), findsOneWidget);
    expect(tester.widget<GesturePad>(find.byType(GesturePad)).hasError, isTrue);
    expect(number(tester), AppStrings.checkInNumberPlaceholder);

    await tester.tap(find.byTooltip(AppStrings.checkInClearPad));
    await tester.pump();
    expect(
      tester.widget<GesturePad>(find.byType(GesturePad)).hasError,
      isFalse,
    );
    expect(
      tester.widget<GesturePad>(find.byType(GesturePad)).controller.isEmpty,
      isTrue,
    );
  });

  testWidgets('undo removes only the last stroke', (tester) async {
    await pumpCheckIn(tester);

    await draw(tester, template('4'));
    final controller = tester
        .widget<GesturePad>(find.byType(GesturePad))
        .controller;
    expect(controller.strokes, hasLength(2));

    await tester.tap(find.byTooltip(AppStrings.checkInUndo));
    await tester.pump();
    expect(controller.strokes, hasLength(1));
  });

  testWidgets('S finishes the input and shows a found ticket', (tester) async {
    await pumpCheckIn(tester);

    for (final label in ['1', '7', finishSymbol]) {
      await draw(tester, template(label));
      await recognize(tester);
    }

    expect(find.text(AppStrings.checkInFound('17')), findsOneWidget);
    expect(find.textContaining('Демо-клиент А.'), findsOneWidget);
    expect(find.text(AppStrings.checkInReset), findsOneWidget);

    await tester.tap(find.text(AppStrings.checkInReset));
    await tester.pumpAndSettle();
    expect(number(tester), AppStrings.checkInNumberPlaceholder);
  });

  testWidgets('unknown ticket and S without digits are explained', (
    tester,
  ) async {
    await pumpCheckIn(tester);

    await draw(tester, template(finishSymbol));
    await recognize(tester);
    expect(find.text(AppStrings.checkInNumberEmpty), findsOneWidget);

    for (final label in ['9', '9', finishSymbol]) {
      await draw(tester, template(label));
      await recognize(tester);
    }
    expect(find.text(AppStrings.checkInNotFound('99')), findsOneWidget);
  });

  testWidgets('template hints show every symbol', (tester) async {
    await pumpCheckIn(tester);

    await tester.tap(find.byTooltip(AppStrings.checkInTemplates));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.checkInTemplatesHint), findsOneWidget);
    for (final label in ['0', '5', '9', finishSymbol]) {
      expect(find.text(label), findsWidgets);
    }
    final previews = find.byType(TemplatePreview);
    expect(previews, findsNWidgets(symbolTemplates.length));
    // A zero-sized canvas would draw every template as a single dot.
    expect(tester.getSize(previews.first), const Size(56, 56));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/gesture_checkin/data/symbol_templates.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_classifier.dart';
import 'package:slotly/features/gesture_checkin/domain/gesture_point.dart';
import 'package:slotly/features/gesture_checkin/presentation/ticket_check_in_screen.dart';
import 'package:slotly/features/gesture_checkin/presentation/widgets/gesture_pad.dart';
import 'package:slotly/features/gesture_checkin/presentation/widgets/template_preview.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/gesture_shapes.dart';
import '../../helpers/test_app.dart';

void main() {
  final pad = find.byKey(const ValueKey('gesture-pad'));
  late TestData data;

  /// Reception tablet of "Северный": ticket 17 starts in 30 minutes, so
  /// check-in is already open; ticket 42 is tomorrow.
  Future<void> pumpCheckIn(WidgetTester tester) async {
    data = await TestData.create();
    data.signInAs('north');
    await data.database.update((t) {
      for (final booking in [
        fixtureBooking(
          id: 'soon',
          ticketNumber: '17',
          startAt: testNow.add(const Duration(minutes: 30)),
        ),
        fixtureBooking(
          id: 'later',
          ticketNumber: '42',
          startAt: DateTime(2026, 10, 6, 12),
        ),
      ]) {
        t.bookings[booking.id] = booking;
      }
    });
    final repository = LocalBookingRepository(data.context);
    await pumpScreen(
      tester,
      TicketCheckInScreen(
        classifier: GestureClassifier(templates: symbolTemplates),
        templates: symbolTemplates,
        checkIn: repository.checkIn,
        finishSymbol: finishSymbol,
      ),
    );
  }

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

  Future<void> enter(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      await draw(tester, template(label));
      await recognize(tester);
    }
  }

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

  testWidgets('S finishes the input and checks the booking in', (tester) async {
    await pumpCheckIn(tester);

    await enter(tester, ['1', '7', finishSymbol]);

    expect(find.text(AppStrings.checkInSuccess('17')), findsOneWidget);
    expect(data.database.tables.bookings['soon']!.isCheckedIn, isTrue);
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

    await enter(tester, ['9', '9', finishSymbol]);
    expect(find.text(AppStrings.checkInNotFound('99')), findsOneWidget);
  });

  testWidgets('a ticket for a later visit explains when check-in opens', (
    tester,
  ) async {
    await pumpCheckIn(tester);

    await enter(tester, ['4', '2', finishSymbol]);

    expect(find.textContaining('Отметиться по талону 42 можно с'), findsOne);
    expect(
      data.database.tables.bookings.values.every((b) => !b.isCheckedIn),
      isTrue,
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/features/booking/data/demo_schedule.dart';
import 'package:slotly/features/booking/data/in_memory_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_draft.dart';
import 'package:slotly/features/booking/presentation/booking_form_screen.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';

import '../../helpers/test_app.dart';

void main() {
  final service = demoServices.firstWhere((s) => s.id == 'svc-men-haircut');
  final specialist = service.availableSpecialists.first;
  const schedule = DemoSchedule();
  final todayStarts = schedule.startTimes(testNow, service.duration);
  final freeTime = todayStarts.firstWhere(
    (t) => !schedule.isTakenByOthers(specialist, t),
  );
  final busyTime = todayStarts.firstWhere(
    (t) => schedule.isTakenByOthers(specialist, t),
  );

  late BookingsController bookings;
  late List<Booking> booked;

  Finder continueButton() =>
      find.widgetWithText(FilledButton, AppStrings.bookingContinue);

  bool isContinueEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(continueButton()).onPressed != null;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pumpForm(WidgetTester tester) async {
    bookings = BookingsController(
      InMemoryBookingRepository(clock: () => testNow),
    );
    addTearDown(bookings.dispose);
    booked = [];
    await pumpScreen(
      tester,
      BookingFormScreen(
        service: service,
        bookings: bookings,
        clock: () => testNow,
        onBooked: booked.add,
      ),
    );
  }

  testWidgets('button stays disabled until required fields are filled', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(isContinueEnabled(tester), isFalse);
    expect(find.text(AppStrings.bookingChooseSpecialistFirst), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.bookingMissingPrefix}'
        '${AppStrings.bookingMissingSpecialist}, ${AppStrings.bookingMissingTime}',
      ),
      findsOneWidget,
    );

    await tapVisible(tester, find.text(specialist.name));
    expect(isContinueEnabled(tester), isFalse);

    await tapVisible(tester, find.text(Formatters.time(freeTime)));
    expect(isContinueEnabled(tester), isTrue);
  });

  testWidgets('an unavailable slot cannot be selected', (tester) async {
    await pumpForm(tester);
    await tapVisible(tester, find.text(specialist.name));

    final busyChip = find.widgetWithText(ChoiceChip, Formatters.time(busyTime));
    expect(tester.widget<ChoiceChip>(busyChip).onSelected, isNull);

    await tapVisible(tester, busyChip);
    expect(tester.widget<ChoiceChip>(busyChip).selected, isFalse);
    expect(isContinueEnabled(tester), isFalse);
  });

  testWidgets('too long comment shows an error and blocks submit', (
    tester,
  ) async {
    await pumpForm(tester);
    await tapVisible(tester, find.text(specialist.name));
    await tapVisible(tester, find.text(Formatters.time(freeTime)));

    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'a' * (BookingDraft.maxCommentLength + 1));
    await tester.pumpAndSettle();

    expect(
      find.text(
        AppStrings.bookingCommentTooLong(BookingDraft.maxCommentLength),
      ),
      findsOneWidget,
    );
    expect(isContinueEnabled(tester), isFalse);

    await tester.enterText(field, 'Буду на машине');
    await tester.pumpAndSettle();
    expect(isContinueEnabled(tester), isTrue);
  });

  testWidgets('confirmation dialog can be cancelled and then confirmed', (
    tester,
  ) async {
    await pumpForm(tester);
    await tapVisible(tester, find.text(specialist.name));
    await tapVisible(tester, find.text(Formatters.time(freeTime)));

    await tapVisible(tester, continueButton());
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(AppStrings.confirmTitle), findsOneWidget);
    expect(find.text(Formatters.dayWithWeekday(freeTime)), findsOneWidget);

    await tester.tap(find.text(AppStrings.confirmEdit));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(booked, isEmpty);
    expect(bookings.active, isEmpty);

    await tapVisible(tester, continueButton());
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(booked.single.startAt, freeTime);
    expect(bookings.active.single.id, booked.single.id);
  });
}

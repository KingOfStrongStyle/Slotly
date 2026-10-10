import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/features/booking/data/local_booking_repository.dart';
import 'package:slotly/features/booking/domain/booking.dart';
import 'package:slotly/features/booking/domain/booking_draft.dart';
import 'package:slotly/features/booking/presentation/booking_form_screen.dart';
import 'package:slotly/features/booking/presentation/bookings_controller.dart';
import 'package:slotly/features/catalog/domain/service.dart';

import '../../helpers/booking_fixtures.dart';
import '../../helpers/test_app.dart';

void main() {
  final freeTime = DateTime(2026, 10, 5, 12);
  final busyTime = DateTime(2026, 10, 5, 14);

  late TestData data;
  late BookingsController bookings;
  late List<Booking> booked;

  Finder submitButton(String label) => find.widgetWithText(FilledButton, label);

  bool isEnabled(
    WidgetTester tester, [
    String label = AppStrings.bookingContinue,
  ]) => tester.widget<FilledButton>(submitButton(label)).onPressed != null;

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<Service> pumpForm(
    WidgetTester tester, {
    String serviceId = 'svc-beard',
    Booking? rescheduling,
  }) async {
    data = await TestData.create();
    data.signInAs('aliya');
    final service = data.database.tables.services[serviceId]!;
    await data.database.update((t) {
      final other = fixtureBooking(
        id: 'other',
        startAt: busyTime,
        serviceId: serviceId,
        clientId: 'someone-else',
      );
      t.bookings[other.id] = other;
      if (rescheduling != null) t.bookings[rescheduling.id] = rescheduling;
    });
    bookings = BookingsController(LocalBookingRepository(data.context));
    addTearDown(bookings.dispose);
    booked = [];
    await pumpScreen(
      tester,
      BookingFormScreen(
        service: service,
        bookings: bookings,
        clock: () => testNow,
        onBooked: booked.add,
        rescheduling: rescheduling,
      ),
    );
    return service;
  }

  testWidgets('button stays disabled until required fields are filled', (
    tester,
  ) async {
    final service = await pumpForm(tester);

    expect(isEnabled(tester), isFalse);
    expect(find.text(AppStrings.bookingChooseSpecialistFirst), findsOneWidget);
    expect(
      find.text(
        '${AppStrings.bookingMissingPrefix}'
        '${AppStrings.bookingMissingSpecialist}, ${AppStrings.bookingMissingTime}',
      ),
      findsOneWidget,
    );

    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );
    expect(isEnabled(tester), isFalse);

    await tapVisible(tester, find.text(Formatters.time(freeTime)));
    expect(isEnabled(tester), isTrue);
  });

  testWidgets('a service with a price list asks for an option', (tester) async {
    final service = await pumpForm(tester, serviceId: 'svc-men-haircut');
    final option = service.priceOptions.last;

    expect(find.text(AppStrings.bookingPriceSection), findsOneWidget);
    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );
    await tapVisible(tester, find.text(Formatters.time(freeTime)));
    expect(isEnabled(tester), isFalse);
    expect(
      find.textContaining(AppStrings.bookingMissingPriceOption),
      findsOneWidget,
    );

    await tapVisible(
      tester,
      find.text('${option.label} · ${Formatters.price(option.priceKzt)}'),
    );
    expect(isEnabled(tester), isTrue);

    await tapVisible(tester, submitButton(AppStrings.bookingContinue));
    expect(find.textContaining(option.label), findsWidgets);
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();
    expect(booked.single.priceKzt, option.priceKzt);
    expect(booked.single.priceLabel, option.label);
  });

  testWidgets('a slot taken by another customer cannot be selected', (
    tester,
  ) async {
    final service = await pumpForm(tester);
    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );

    final busyChip = find.widgetWithText(ChoiceChip, Formatters.time(busyTime));
    expect(tester.widget<ChoiceChip>(busyChip).onSelected, isNull);
    await tapVisible(tester, busyChip);
    expect(tester.widget<ChoiceChip>(busyChip).selected, isFalse);
    expect(isEnabled(tester), isFalse);
  });

  testWidgets('too long comment shows an error and blocks submit', (
    tester,
  ) async {
    final service = await pumpForm(tester);
    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );
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
    expect(isEnabled(tester), isFalse);

    await tester.enterText(field, 'Буду на машине');
    await tester.pumpAndSettle();
    expect(isEnabled(tester), isTrue);
  });

  testWidgets('confirmation dialog can be cancelled and then confirmed', (
    tester,
  ) async {
    final service = await pumpForm(tester);
    await tapVisible(
      tester,
      find.text(service.availableSpecialists.first.name),
    );
    await tapVisible(tester, find.text(Formatters.time(freeTime)));

    await tapVisible(tester, submitButton(AppStrings.bookingContinue));
    expect(find.text(AppStrings.confirmTitle), findsOneWidget);
    expect(find.text(Formatters.dayWithWeekday(freeTime)), findsOneWidget);

    await tester.tap(find.text(AppStrings.confirmEdit));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(booked, isEmpty);

    await tapVisible(tester, submitButton(AppStrings.bookingContinue));
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(booked.single.startAt, freeTime);
    expect(booked.single.ticketNumber, isNotEmpty);
  });

  testWidgets('rescheduling moves the booking after confirmation', (
    tester,
  ) async {
    final current = fixtureBooking(
      id: 'mine',
      serviceId: 'svc-beard',
      startAt: DateTime(2026, 10, 6, 12),
    );
    await pumpForm(tester, rescheduling: current);

    expect(find.text(AppStrings.rescheduleTitle), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing, reason: 'no comment');
    expect(find.textContaining(AppStrings.rescheduleCurrent), findsOneWidget);

    await tapVisible(tester, find.text(AppStrings.bookingTomorrow));
    await tapVisible(tester, find.text('15:00'));
    await tapVisible(tester, submitButton(AppStrings.rescheduleSubmit));
    expect(find.text(AppStrings.rescheduleConfirmTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.rescheduleSubmit).last,
    );
    await tester.pumpAndSettle();

    expect(booked.single.id, 'mine');
    expect(booked.single.startAt, DateTime(2026, 10, 6, 15));
    expect(booked.single.ticketNumber, current.ticketNumber);
  });
}

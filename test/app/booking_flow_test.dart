import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/utils/formatters.dart';
import 'package:slotly/features/booking/data/demo_schedule.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('catalog -> details -> form -> confirm -> my bookings', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final service = demoServices.firstWhere((s) => s.id == 'svc-men-haircut');
    final specialist = service.availableSpecialists.first;
    const schedule = DemoSchedule();
    final freeTime = schedule
        .startTimes(testNow, service.duration)
        .firstWhere((t) => !schedule.isTakenByOthers(specialist, t));

    await tester.pumpWidget(
      const SlotlyApp(createDependencies: createTestDependencies),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();

    await tester.tap(find.text(service.title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.detailsBook));
    await tester.pumpAndSettle();

    await tester.tap(find.text(specialist.name));
    await tester.pumpAndSettle();
    final slot = find.text(Formatters.time(freeTime));
    await tester.ensureVisible(slot);
    await tester.pumpAndSettle();
    await tester.tap(slot);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.bookingContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.textContaining(
        AppStrings.bookingCreated(service.title, Formatters.dateTime(freeTime)),
      ),
      findsOneWidget,
    );
    final tile = tester.widget<BookingTile>(find.byType(BookingTile));
    expect(tile.booking.startAt, freeTime);
    expect(find.text(AppStrings.bookingsActiveTab(1)), findsOneWidget);
  });
}

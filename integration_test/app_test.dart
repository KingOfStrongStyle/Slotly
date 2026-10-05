import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:slotly/app/app.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/core/widgets/time_slot_chip.dart';
import 'package:slotly/features/booking/presentation/widgets/booking_tile.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';

/// End-to-end booking on a real device or emulator with the real clock:
/// welcome -> catalog -> details -> form -> confirmation -> "Мои записи".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user books a service and sees it in My bookings', (
    tester,
  ) async {
    final service = demoServices.firstWhere((s) => s.id == 'svc-men-haircut');
    final specialist = service.availableSpecialists.first;

    await tester.pumpWidget(const SlotlyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.welcomeShowServices));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.catalogTitle), findsWidgets);

    await tester.tap(find.text(service.title));
    await tester.pumpAndSettle();
    expect(find.text(service.description), findsOneWidget);

    await tester.tap(find.text(AppStrings.detailsBook));
    await tester.pumpAndSettle();

    await tester.tap(find.text(specialist.name));
    await tester.pumpAndSettle();
    // Tomorrow always has free slots, whatever the current time is.
    await tester.tap(find.text(AppStrings.bookingTomorrow));
    await tester.pumpAndSettle();

    final freeSlot = find
        .byWidgetPredicate((w) => w is TimeSlotChip && w.isAvailable)
        .first;
    await tester.ensureVisible(freeSlot);
    await tester.pumpAndSettle();
    await tester.tap(freeSlot);
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.bookingContinue));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text(AppStrings.confirmSubmit));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text(AppStrings.bookingsActiveTab(1)), findsOneWidget);
    final tile = tester.widget<BookingTile>(find.byType(BookingTile));
    expect(tile.booking.serviceTitle, service.title);
    expect(tile.booking.specialist, specialist);
  });
}

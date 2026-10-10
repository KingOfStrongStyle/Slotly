import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/catalog/presentation/service_details_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows the service passed through the constructor', (
    tester,
  ) async {
    final service = demoServices.firstWhere((s) => s.id == 'svc-tires');
    var bookTaps = 0;

    await pumpScreen(
      tester,
      ServiceDetailsScreen(service: service, onBook: () => bookTaps++),
    );

    expect(find.text('Сезонный шиномонтаж'), findsOneWidget);
    expect(find.text(AppStrings.categoryAutoService), findsOneWidget);
    expect(find.textContaining('R13–R16 — 12\u00A0000\u00A0₸'), findsOneWidget);
    expect(
      find.textContaining('R20 и больше — 20\u00A0000\u00A0₸'),
      findsOneWidget,
    );
    expect(find.text('1 ч'), findsOneWidget);
    expect(find.text(service.description), findsOneWidget);
    for (final specialist in service.availableSpecialists) {
      expect(find.text(specialist.name), findsOneWidget);
    }

    await tester.tap(find.text(AppStrings.detailsBook));
    expect(bookTaps, 1);
  });

  testWidgets('without a booking action there is no "Записаться"', (
    tester,
  ) async {
    final service = demoServices.firstWhere((s) => s.id == 'svc-beard');
    await pumpScreen(
      tester,
      ServiceDetailsScreen(service: service, onBook: null),
    );
    expect(find.text(AppStrings.detailsBook), findsNothing);
    expect(find.text('4\u00A0000\u00A0₸'), findsOneWidget);
  });
}

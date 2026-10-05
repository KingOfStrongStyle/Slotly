import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/catalog/data/demo_services.dart';
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
    expect(find.text('12 000 ₸'), findsOneWidget);
    expect(find.text('1 ч'), findsOneWidget);
    expect(find.text(service.description), findsOneWidget);
    for (final specialist in service.availableSpecialists) {
      expect(find.text(specialist.name), findsOneWidget);
    }

    await tester.tap(find.text(AppStrings.detailsBook));
    expect(bookTaps, 1);
  });
}

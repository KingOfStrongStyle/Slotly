import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/catalog/domain/service.dart';
import 'package:slotly/features/catalog/domain/service_filter.dart';

void main() {
  test('empty query and no category return the whole catalog', () {
    expect(filterServices(demoServices), demoServices);
  });

  test('search is case-insensitive for Russian text', () {
    final results = filterServices(demoServices, query: 'СТРИЖКА');
    expect(results.map((s) => s.id), [
      'svc-men-haircut',
      'svc-haircut-beard',
      'svc-kids-haircut',
    ]);
  });

  test('search ignores surrounding spaces and treats ё as е', () {
    final results = filterServices(demoServices, query: '  четырЁх ');
    expect(results, isEmpty, reason: 'description is not searched');

    final byTitle = filterServices(demoServices, query: ' шиномонтаж ');
    expect(byTitle.single.id, 'svc-tires');

    expect(normalizeSearchText('Ёлка'), 'елка');
  });

  test('category filter keeps only the selected category', () {
    final results = filterServices(
      demoServices,
      category: ServiceCategory.dentistry,
    );
    expect(results, isNotEmpty);
    expect(
      results.every((s) => s.category == ServiceCategory.dentistry),
      isTrue,
    );
  });

  test('query and category are combined', () {
    expect(
      filterServices(
        demoServices,
        query: 'консультация',
        category: ServiceCategory.dentistry,
      ).single.id,
      'svc-dental-consult',
    );
    expect(
      filterServices(
        demoServices,
        query: 'стрижка',
        category: ServiceCategory.clinic,
      ),
      isEmpty,
    );
  });

  test('demo catalog covers every category and has specialists', () {
    final categories = demoServices.map((s) => s.category).toSet();
    expect(categories, ServiceCategory.values.toSet());
    expect(
      demoServices.every((s) => s.availableSpecialists.isNotEmpty),
      isTrue,
    );
    expect(demoServices.map((s) => s.id).toSet().length, demoServices.length);
  });
}

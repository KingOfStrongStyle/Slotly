import 'service.dart';

/// Filters the catalog by title and category.
///
/// The search is case-insensitive and treats `ё` as `е`, because Russian
/// users often type one instead of the other.
List<Service> filterServices(
  Iterable<Service> services, {
  String query = '',
  ServiceCategory? category,
}) {
  final normalizedQuery = normalizeSearchText(query);
  return [
    for (final service in services)
      if ((category == null || service.category == category) &&
          normalizeSearchText(service.title).contains(normalizedQuery))
        service,
  ];
}

String normalizeSearchText(String value) =>
    value.trim().toLowerCase().replaceAll('ё', 'е');

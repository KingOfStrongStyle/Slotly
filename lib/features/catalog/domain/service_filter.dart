import 'organization.dart';
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

/// Organizations whose name or any of whose [services] match [query].
List<Organization> filterOrganizations(
  Iterable<Organization> organizations, {
  required Iterable<Service> services,
  String query = '',
  ServiceCategory? category,
}) {
  final normalizedQuery = normalizeSearchText(query);
  bool matchesService(Organization organization) => services.any(
    (s) =>
        s.organizationId == organization.id &&
        normalizeSearchText(s.title).contains(normalizedQuery),
  );
  return [
    for (final organization in organizations)
      if ((category == null || organization.category == category) &&
          (normalizeSearchText(organization.name).contains(normalizedQuery) ||
              matchesService(organization)))
        organization,
  ];
}

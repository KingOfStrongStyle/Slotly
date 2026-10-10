import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/local_context.dart';
import '../domain/organization.dart';
import '../domain/service.dart';

abstract interface class CatalogRepository {
  Listenable get changes;

  Future<List<Organization>> fetchOrganizations();

  Future<Organization> fetchOrganization(String id);

  Future<List<Service>> fetchServices({String? organizationId});

  Future<List<Specialist>> fetchSpecialists(String organizationId);

  Future<List<BusinessPhoto>> fetchPhotos(String organizationId);
}

class LocalCatalogRepository implements CatalogRepository {
  const LocalCatalogRepository(this._context);

  final LocalContext _context;

  @override
  Listenable get changes => _context.database;

  @override
  Future<List<Organization>> fetchOrganizations() async {
    _context.require(AppAction.browseCatalog);
    return _context.database.tables.organizations.values
        .where((o) => o.isPublished)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Organization> fetchOrganization(String id) async {
    _context.require(AppAction.browseCatalog);
    final organization = _context.database.tables.organizations[id];
    final canSeeUnpublished = _context.user?.ownsOrganization(id) ?? false;
    if (organization == null ||
        (!organization.isPublished && !canSeeUnpublished)) {
      throw RecordNotFoundException('organization', id);
    }
    return organization;
  }

  @override
  Future<List<Service>> fetchServices({String? organizationId}) async {
    _context.require(AppAction.browseCatalog);
    final organizations = _context.database.tables.organizations;
    return [
      for (final service in _context.database.tables.services.values)
        if (!service.isHidden &&
            (organizationId == null ||
                service.organizationId == organizationId) &&
            (organizations[service.organizationId]?.isPublished ?? false))
          service,
    ];
  }

  @override
  Future<List<Specialist>> fetchSpecialists(String organizationId) async {
    _context.require(AppAction.browseCatalog);
    return [
      for (final specialist in _context.database.tables.specialists.values)
        if (specialist.organizationId == organizationId) specialist,
    ];
  }

  @override
  Future<List<BusinessPhoto>> fetchPhotos(String organizationId) async {
    _context.require(AppAction.browseCatalog);
    return _context.database.tables.photos.values
        .where((p) => p.organizationId == organizationId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }
}

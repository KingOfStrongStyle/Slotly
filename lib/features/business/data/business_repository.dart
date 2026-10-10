import 'package:flutter/foundation.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/local/database_tables.dart';
import '../../../data/local/local_context.dart';
import '../../catalog/domain/organization.dart';
import '../../catalog/domain/service.dart';
import '../domain/business_rules.dart';
import 'photo_storage.dart';

/// What an owner changes in their organization: the profile, services with
/// price lists, and the photo gallery. Every method checks that the
/// signed-in owner manages the organization being changed.
abstract interface class BusinessRepository {
  Listenable get changes;

  /// All services of the organization, including hidden ones.
  Future<List<Service>> fetchManagedServices(String organizationId);

  /// Throws [ValidationException] with [OrganizationIssue] values.
  Future<Organization> updateOrganization(Organization organization);

  /// Creates the service when [Service.id] is empty, otherwise updates it.
  /// Throws [ValidationException] with [ServiceIssue] values.
  Future<Service> saveService(Service service);

  Future<Service> setServiceHidden(String serviceId, {required bool hidden});

  /// Throws [ValidationException] with [PhotoIssue] values.
  Future<BusinessPhoto> addPhoto(
    String organizationId, {
    required String sourcePath,
  });

  Future<void> removePhoto(String photoId);

  /// Moves the photo to [newPosition] (0-based) and renumbers the rest.
  Future<void> movePhoto(String photoId, int newPosition);
}

class LocalBusinessRepository implements BusinessRepository {
  const LocalBusinessRepository(this._context, this._photos);

  final LocalContext _context;
  final PhotoStorage _photos;

  DatabaseTables get _tables => _context.database.tables;

  @override
  Listenable get changes => _context.database;

  @override
  Future<List<Service>> fetchManagedServices(String organizationId) async {
    _context.require(AppAction.manageServices, organizationId: organizationId);
    return _tables.services.values
        .where((s) => s.organizationId == organizationId)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  @override
  Future<Organization> updateOrganization(Organization organization) async {
    final stored = _tables.organizations[organization.id];
    _context.require(
      AppAction.editOrganization,
      organizationId: organization.id,
    );
    if (stored == null) {
      throw RecordNotFoundException('organization', organization.id);
    }
    // Only editable fields are taken from the input.
    final updated = stored.copyWith(
      name: organization.name.trim(),
      description: organization.description.trim(),
      address: organization.address.trim(),
      phone: organization.phone.trim(),
    );
    final issues = BusinessRules.validateOrganization(updated);
    if (issues.isNotEmpty) throw ValidationException(issues);
    return _context.database.update((t) {
      t.organizations[updated.id] = updated;
      // Keep the name in existing bookings readable for customers.
      return updated;
    });
  }

  @override
  Future<Service> saveService(Service service) async {
    _context.require(
      AppAction.manageServices,
      organizationId: service.organizationId,
    );
    final organization = _tables.organizations[service.organizationId];
    if (organization == null) {
      throw RecordNotFoundException('organization', service.organizationId);
    }
    final existing = service.id.isEmpty ? null : _tables.services[service.id];
    if (service.id.isNotEmpty &&
        (existing == null ||
            existing.organizationId != service.organizationId)) {
      throw RecordNotFoundException('service', service.id);
    }
    final foreignSpecialist = service.availableSpecialists.any(
      (s) => _tables.specialists[s.id]?.organizationId != organization.id,
    );
    if (foreignSpecialist) {
      throw const AccessDeniedException(
        AppAction.manageServices,
        'specialist of another organization',
      );
    }
    final issues = BusinessRules.validateService(service);
    if (issues.isNotEmpty) throw ValidationException(issues);

    return _context.database.update((t) {
      final id = existing?.id ?? 'svc-custom-${t.nextCounter('service')}';
      final saved = Service(
        id: id,
        organizationId: organization.id,
        title: service.title.trim(),
        category: organization.category,
        description: service.description.trim(),
        duration: service.duration,
        priceKzt: service.priceKzt,
        priceOptions: [
          for (final (i, option) in service.priceOptions.indexed)
            PriceOption(
              id: option.id.isEmpty ? 'option-$i' : option.id,
              label: option.label.trim(),
              priceKzt: option.priceKzt,
            ),
        ],
        availableSpecialists: [
          for (final s in service.availableSpecialists) t.specialists[s.id]!,
        ],
        artworkVariant: existing?.artworkVariant ?? t.services.length % 3,
        isHidden: service.isHidden,
      );
      t.services[id] = saved;
      return saved;
    });
  }

  @override
  Future<Service> setServiceHidden(
    String serviceId, {
    required bool hidden,
  }) async {
    final service = _tables.services[serviceId];
    _context.require(
      AppAction.manageServices,
      organizationId: service?.organizationId,
    );
    if (service == null) throw RecordNotFoundException('service', serviceId);
    return _context.database.update((t) {
      final updated = service.copyWith(isHidden: hidden);
      t.services[serviceId] = updated;
      return updated;
    });
  }

  @override
  Future<BusinessPhoto> addPhoto(
    String organizationId, {
    required String sourcePath,
  }) async {
    _context.require(AppAction.managePhotos, organizationId: organizationId);
    final issues = BusinessRules.validatePhoto(
      existingCount: _photosOf(organizationId).length,
      fileName: sourcePath,
      sizeBytes: await _photos.sizeOf(sourcePath),
    );
    if (issues.isNotEmpty) throw ValidationException(issues);

    final id =
        'photo-$organizationId-${_context.clock().microsecondsSinceEpoch}';
    final path = await _photos.importPhoto(sourcePath, id);
    return _context.database.update((t) {
      final photo = BusinessPhoto(
        id: id,
        organizationId: organizationId,
        position: _photosOf(organizationId).length,
        addedAt: _context.clock(),
        filePath: path,
      );
      t.photos[id] = photo;
      return photo;
    });
  }

  @override
  Future<void> removePhoto(String photoId) async {
    final photo = _tables.photos[photoId];
    _context.require(
      AppAction.managePhotos,
      organizationId: photo?.organizationId,
    );
    if (photo == null) throw RecordNotFoundException('photo', photoId);
    final rest = _photosOf(photo.organizationId)..remove(photo);
    await _context.database.update((t) {
      t.photos.remove(photoId);
      _renumber(t, rest);
    });
    final path = photo.filePath;
    if (path != null) await _photos.delete(path);
  }

  @override
  Future<void> movePhoto(String photoId, int newPosition) async {
    final photo = _tables.photos[photoId];
    _context.require(
      AppAction.managePhotos,
      organizationId: photo?.organizationId,
    );
    if (photo == null) throw RecordNotFoundException('photo', photoId);
    final ordered = _photosOf(photo.organizationId)..remove(photo);
    ordered.insert(newPosition.clamp(0, ordered.length), photo);
    await _context.database.update((t) => _renumber(t, ordered));
  }

  List<BusinessPhoto> _photosOf(String organizationId) =>
      _tables.photos.values
          .where((p) => p.organizationId == organizationId)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  static void _renumber(DatabaseTables t, List<BusinessPhoto> ordered) {
    for (final (index, photo) in ordered.indexed) {
      t.photos[photo.id] = photo.withPosition(index);
    }
  }
}

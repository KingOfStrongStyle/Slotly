typedef JsonMap = Map<String, Object?>;

/// Upgrades a stored database from one schema version to the next.
typedef Migration = JsonMap Function(JsonMap data);

/// Thrown when the stored data cannot be read by this app version.
class UnsupportedSchemaException implements Exception {
  const UnsupportedSchemaException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedSchemaException: $message';
}

/// Brings stored JSON to [currentVersion] by applying migrations one by
/// one: version 1 -> 2 -> 3 and so on.
///
/// Every structural change of the stored data adds a migration under the
/// version it upgrades from and increases [currentVersion]. Old data is
/// never read by code that expects the new structure.
class SchemaMigrator {
  const SchemaMigrator({
    this.currentVersion = latestSchemaVersion,
    this.migrations = schemaMigrations,
  });

  final int currentVersion;
  final Map<int, Migration> migrations;

  JsonMap migrate(JsonMap data) {
    final stored = data['schemaVersion'];
    if (stored is! int || stored < 1) {
      throw const UnsupportedSchemaException('schemaVersion is missing');
    }
    var version = stored;
    if (version > currentVersion) {
      throw UnsupportedSchemaException(
        'data has version $version, app supports up to $currentVersion',
      );
    }
    var result = data;
    while (version < currentVersion) {
      final migration = migrations[version];
      if (migration == null) {
        throw UnsupportedSchemaException('no migration from version $version');
      }
      result = migration(Map.of(result));
      version++;
      result['schemaVersion'] = version;
    }
    return result;
  }
}

/// Version 1: first persisted schema (users, organizations, catalog,
/// photos, bookings, reviews, favorites, settings).
/// Version 2: services can be hidden from customers (`isHidden`).
const latestSchemaVersion = 2;

const schemaMigrations = <int, Migration>{1: _addServiceVisibility};

JsonMap _addServiceVisibility(JsonMap data) {
  final services = (data['services'] as List?) ?? const [];
  data['services'] = [
    for (final service in services.cast<JsonMap>())
      {...service, 'isHidden': service['isHidden'] ?? false},
  ];
  return data;
}

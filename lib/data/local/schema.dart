typedef JsonMap = Map<String, Object?>;

typedef Migration = JsonMap Function(JsonMap data);

class UnsupportedSchemaException implements Exception {
  const UnsupportedSchemaException(this.message);

  final String message;

  @override
  String toString() => 'UnsupportedSchemaException: $message';
}

// Влад: миграции идут цепочкой по одной версии. Новая версия схемы = новая
// функция в schemaMigrations + тест на старый json
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

/// Business category of a service. Labels and icons are mapped in the
/// presentation layer so the domain stays independent of Flutter.
enum ServiceCategory {
  barbershop,
  beauty,
  dentistry,
  clinic,
  autoService,
  tutoring,
}

class Specialist {
  const Specialist({required this.id, required this.name, required this.role});

  final String id;
  final String name;
  final String role;

  @override
  bool operator ==(Object other) => other is Specialist && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Specialist($id, $name)';
}

class Service {
  const Service({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.priceKzt,
    required this.availableSpecialists,
    required this.artworkVariant,
  });

  final String id;
  final String title;
  final ServiceCategory category;
  final String description;
  final Duration duration;

  /// Price in tenge. Integer amounts avoid floating point rounding issues.
  final int priceKzt;
  final List<Specialist> availableSpecialists;

  /// Visual identifier: selects one of the built-in abstract illustrations,
  /// so the catalog needs no network or third-party images.
  final int artworkVariant;

  @override
  bool operator ==(Object other) => other is Service && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Service($id, $title)';
}

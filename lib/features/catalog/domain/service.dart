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
  const Specialist({
    required this.id,
    required this.name,
    required this.role,
    this.organizationId = '',
    this.workingWeekdays = defaultWorkingWeekdays,
  });

  /// Monday to Saturday ([DateTime.monday] = 1).
  static const defaultWorkingWeekdays = {1, 2, 3, 4, 5, 6};

  final String id;
  final String name;
  final String role;

  /// Empty only in bookings created before organizations existed.
  final String organizationId;

  /// Days of the week with appointments. Empty while on vacation.
  final Set<int> workingWeekdays;

  bool worksOn(DateTime day) => workingWeekdays.contains(day.weekday);

  @override
  bool operator ==(Object other) => other is Specialist && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Specialist($id, $name)';
}

/// One line of a detailed price list, for example "Длинные волосы".
class PriceOption {
  const PriceOption({
    required this.id,
    required this.label,
    required this.priceKzt,
  });

  final String id;
  final String label;
  final int priceKzt;

  @override
  bool operator ==(Object other) =>
      other is PriceOption &&
      other.id == id &&
      other.label == label &&
      other.priceKzt == priceKzt;

  @override
  int get hashCode => Object.hash(id, label, priceKzt);

  @override
  String toString() => 'PriceOption($label, $priceKzt)';
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
    this.organizationId = '',
    this.priceOptions = const [],
    this.isHidden = false,
  });

  final String id;

  /// Business that provides the service.
  final String organizationId;
  final String title;
  final ServiceCategory category;
  final String description;
  final Duration duration;

  /// Base price in tenge. Integer amounts avoid floating point rounding.
  final int priceKzt;

  /// Optional detailed price list. When it is not empty, the customer picks
  /// one option and its price replaces [priceKzt].
  final List<PriceOption> priceOptions;
  final List<Specialist> availableSpecialists;

  /// Visual identifier: selects one of the built-in abstract illustrations,
  /// so the catalog needs no network or third-party images.
  final int artworkVariant;

  /// Hidden services stay in existing bookings but are not offered to new
  /// customers.
  final bool isHidden;

  /// Lowest price a customer can pay, shown as "от …" in the catalog.
  int get minPriceKzt => priceOptions.isEmpty
      ? priceKzt
      : priceOptions.map((o) => o.priceKzt).reduce((a, b) => a < b ? a : b);

  bool get hasPriceOptions => priceOptions.isNotEmpty;

  Service copyWith({
    String? title,
    String? description,
    Duration? duration,
    int? priceKzt,
    List<PriceOption>? priceOptions,
    List<Specialist>? availableSpecialists,
    bool? isHidden,
  }) => Service(
    id: id,
    organizationId: organizationId,
    title: title ?? this.title,
    category: category,
    description: description ?? this.description,
    duration: duration ?? this.duration,
    priceKzt: priceKzt ?? this.priceKzt,
    priceOptions: priceOptions ?? this.priceOptions,
    availableSpecialists: availableSpecialists ?? this.availableSpecialists,
    artworkVariant: artworkVariant,
    isHidden: isHidden ?? this.isHidden,
  );

  @override
  bool operator ==(Object other) => other is Service && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Service($id, $title)';
}

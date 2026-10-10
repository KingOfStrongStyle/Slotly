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

  static const defaultWorkingWeekdays = {1, 2, 3, 4, 5, 6};

  final String id;
  final String name;
  final String role;

  final String organizationId;

  final Set<int> workingWeekdays;

  bool worksOn(DateTime day) => workingWeekdays.contains(day.weekday);

  @override
  bool operator ==(Object other) => other is Specialist && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Specialist($id, $name)';
}

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

  final String organizationId;
  final String title;
  final ServiceCategory category;
  final String description;
  final Duration duration;

  final int priceKzt;

  final List<PriceOption> priceOptions;
  final List<Specialist> availableSpecialists;

  final int artworkVariant;

  final bool isHidden;

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

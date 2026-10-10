import 'service.dart';

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    required this.artworkVariant,
    this.isPublished = true,
  });

  static const maxPhotos = 5;

  final String id;
  final String name;
  final ServiceCategory category;
  final String description;

  final String address;
  final String phone;
  final int artworkVariant;

  final bool isPublished;

  Organization copyWith({
    String? name,
    String? description,
    String? address,
    String? phone,
  }) => Organization(
    id: id,
    name: name ?? this.name,
    category: category,
    description: description ?? this.description,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    artworkVariant: artworkVariant,
    isPublished: isPublished,
  );

  @override
  bool operator ==(Object other) =>
      other is Organization &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.address == address &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(id, name, description, address, phone);

  @override
  String toString() => 'Organization($id, $name)';
}

class BusinessPhoto {
  const BusinessPhoto({
    required this.id,
    required this.organizationId,
    required this.position,
    required this.addedAt,
    this.filePath,
    this.illustrationVariant,
  }) : assert(
         (filePath == null) != (illustrationVariant == null),
         'A photo is either a file or an illustration',
       );

  final String id;
  final String organizationId;

  final int position;
  final DateTime addedAt;
  final String? filePath;
  final int? illustrationVariant;

  bool get isFile => filePath != null;

  BusinessPhoto withPosition(int value) => BusinessPhoto(
    id: id,
    organizationId: organizationId,
    position: value,
    addedAt: addedAt,
    filePath: filePath,
    illustrationVariant: illustrationVariant,
  );

  @override
  String toString() => 'BusinessPhoto($id, #$position)';
}

import '../../catalog/domain/organization.dart';
import '../../catalog/domain/service.dart';

enum OrganizationIssue {
  nameLength,
  descriptionTooLong,
  addressEmpty,
  phoneInvalid,
}

enum ServiceIssue {
  titleLength,
  descriptionTooLong,
  durationOutOfRange,
  priceOutOfRange,
  optionLabelEmpty,
  optionLabelDuplicate,
  optionPriceOutOfRange,
  tooManyOptions,
  noSpecialists,
}

enum PhotoIssue { limitReached, unsupportedFormat, fileTooLarge }

/// Validation rules for everything an owner edits. Repositories enforce
/// them; forms use the same rules to show messages next to fields.
abstract final class BusinessRules {
  static const minNameLength = 3;
  static const maxNameLength = 60;
  static const maxDescriptionLength = 600;
  static const minDuration = Duration(minutes: 15);
  static const maxDuration = Duration(hours: 8);
  static const durationStep = Duration(minutes: 15);
  static const maxPriceKzt = 1000000;
  static const maxPriceOptions = 6;
  static const maxPhotoBytes = 8 * 1024 * 1024;
  static const photoExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};

  static final _phone = RegExp(r'^\+?[0-9 ()-]{7,20}$');

  static List<OrganizationIssue> validateOrganization(Organization o) => [
    if (!_lengthBetween(o.name, minNameLength, maxNameLength))
      OrganizationIssue.nameLength,
    if (o.description.trim().length > maxDescriptionLength)
      OrganizationIssue.descriptionTooLong,
    if (o.address.trim().isEmpty) OrganizationIssue.addressEmpty,
    if (!_phone.hasMatch(o.phone.trim())) OrganizationIssue.phoneInvalid,
  ];

  static List<ServiceIssue> validateService(Service s) {
    final labels = [
      for (final o in s.priceOptions) o.label.trim().toLowerCase(),
    ];
    return [
      if (!_lengthBetween(s.title, minNameLength, maxNameLength))
        ServiceIssue.titleLength,
      if (s.description.trim().length > maxDescriptionLength)
        ServiceIssue.descriptionTooLong,
      if (s.duration < minDuration ||
          s.duration > maxDuration ||
          s.duration.inMinutes % durationStep.inMinutes != 0)
        ServiceIssue.durationOutOfRange,
      if (!_validPrice(s.priceKzt)) ServiceIssue.priceOutOfRange,
      if (labels.any((l) => l.isEmpty)) ServiceIssue.optionLabelEmpty,
      if (labels.toSet().length != labels.length)
        ServiceIssue.optionLabelDuplicate,
      if (s.priceOptions.any((o) => !_validPrice(o.priceKzt)))
        ServiceIssue.optionPriceOutOfRange,
      if (s.priceOptions.length > maxPriceOptions) ServiceIssue.tooManyOptions,
      if (s.availableSpecialists.isEmpty) ServiceIssue.noSpecialists,
    ];
  }

  static List<PhotoIssue> validatePhoto({
    required int existingCount,
    required String fileName,
    required int sizeBytes,
  }) {
    final dot = fileName.lastIndexOf('.');
    final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
    return [
      if (existingCount >= Organization.maxPhotos) PhotoIssue.limitReached,
      if (!photoExtensions.contains(extension)) PhotoIssue.unsupportedFormat,
      if (sizeBytes > maxPhotoBytes) PhotoIssue.fileTooLarge,
    ];
  }

  static bool _validPrice(int price) => price > 0 && price <= maxPriceKzt;

  static bool _lengthBetween(String value, int min, int max) {
    final length = value.trim().length;
    return length >= min && length <= max;
  }
}

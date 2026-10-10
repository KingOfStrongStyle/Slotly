import 'package:flutter/material.dart';

import '../../../core/app_strings.dart';
import '../domain/service.dart';

extension ServiceCategoryStyle on ServiceCategory {
  String get label => switch (this) {
    ServiceCategory.barbershop => AppStrings.categoryBarbershop,
    ServiceCategory.beauty => AppStrings.categoryBeauty,
    ServiceCategory.dentistry => AppStrings.categoryDentistry,
    ServiceCategory.clinic => AppStrings.categoryClinic,
    ServiceCategory.autoService => AppStrings.categoryAutoService,
    ServiceCategory.tutoring => AppStrings.categoryTutoring,
  };

  IconData get icon => switch (this) {
    ServiceCategory.barbershop => Icons.content_cut,
    ServiceCategory.beauty => Icons.spa_outlined,
    ServiceCategory.dentistry => Icons.sentiment_satisfied_alt_outlined,
    ServiceCategory.clinic => Icons.local_hospital_outlined,
    ServiceCategory.autoService => Icons.car_repair,
    ServiceCategory.tutoring => Icons.school_outlined,
  };
}

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/app_scope.dart';
import 'data/local/database_storage.dart';
import 'features/business/data/photo_picker.dart';
import 'features/business/data/photo_storage.dart';
import 'features/reminders/data/local_reminder_service.dart';

// Кирилл: база и фото лежат в support-каталоге приложения, при удалении приложения
// всё стирается. Сбросить демо-данные: adb shell pm clear kz.slotly.mobile
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationSupportDirectory();
  final dependencies = await AppDependencies.create(
    storage: FileDatabaseStorage(File('${directory.path}/slotly-db.json')),
    photoStorage: FilePhotoStorage(Directory('${directory.path}/photos')),
    reminderService: await LocalReminderService.create(),
    photoPicker: SystemPhotoPicker(),
  );
  runApp(SlotlyApp(dependencies: dependencies));
}

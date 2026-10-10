import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/data/local/local_context.dart';
import 'package:slotly/data/seed/demo_catalog.dart';
import 'package:slotly/features/business/data/business_repository.dart';
import 'package:slotly/features/business/data/photo_storage.dart';
import 'package:slotly/features/business/domain/business_rules.dart';
import 'package:slotly/features/catalog/data/catalog_repository.dart';
import 'package:slotly/features/catalog/domain/organization.dart';
import 'package:slotly/features/catalog/domain/service.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestData data;
  late MemoryPhotoStorage storage;
  late LocalBusinessRepository business;
  late LocalCatalogRepository catalog;

  setUp(() async {
    data = await TestData.create();
    data.signInAs('north');
    storage = MemoryPhotoStorage(sizes: {'/big.jpg': 9 * 1024 * 1024});
    business = LocalBusinessRepository(data.context, storage);
    catalog = LocalCatalogRepository(data.context);
  });

  Organization north() => data.database.tables.organizations[orgNorth]!;

  Matcher issues<T extends Enum>(List<T> expected) => throwsA(
    isA<ValidationException<T>>().having((e) => e.issues, 'issues', expected),
  );

  group('organization', () {
    test('saves trimmed editable fields', () async {
      final saved = await business.updateOrganization(
        north().copyWith(
          name: '  Северный Барбер  ',
          description: 'Новое описание',
          phone: '+7 (700) 000-00-09',
        ),
      );
      expect(saved.name, 'Северный Барбер');
      expect((await catalog.fetchOrganization(orgNorth)).name, saved.name);
    });

    test('rejects invalid values', () {
      expect(
        () => business.updateOrganization(
          north().copyWith(name: 'A', address: ' ', phone: 'abc'),
        ),
        issues([
          OrganizationIssue.nameLength,
          OrganizationIssue.addressEmpty,
          OrganizationIssue.phoneInvalid,
        ]),
      );
      expect(
        () => business.updateOrganization(
          north().copyWith(description: 'x' * 601),
        ),
        issues([OrganizationIssue.descriptionTooLong]),
      );
    });
  });

  group('services', () {
    Service draft({
      String title = 'Камуфляж седины',
      int price = 5000,
      List<PriceOption> options = const [],
      List<String> specialists = const ['sp-arman'],
      Duration duration = const Duration(minutes: 45),
    }) => Service(
      id: '',
      organizationId: orgNorth,
      title: title,
      category: ServiceCategory.barbershop,
      description: 'Тонирование седых волос',
      duration: duration,
      priceKzt: price,
      priceOptions: options,
      availableSpecialists: [
        for (final id in specialists) data.database.tables.specialists[id]!,
      ],
      artworkVariant: 0,
    );

    test(
      'creates a service with a price list and shows it in the catalog',
      () async {
        final saved = await business.saveService(
          draft(
            options: const [
              PriceOption(id: '', label: 'Короткие', priceKzt: 5000),
              PriceOption(id: '', label: 'Длинные', priceKzt: 7000),
            ],
          ),
        );
        expect(saved.id, startsWith('svc-custom-'));
        expect(saved.category, ServiceCategory.barbershop);
        expect(saved.minPriceKzt, 5000);
        expect(saved.priceOptions.map((o) => o.id), ['option-0', 'option-1']);
        final services = await catalog.fetchServices(organizationId: orgNorth);
        expect(services.map((s) => s.id), contains(saved.id));
      },
    );

    test('updates an existing service', () async {
      final beard = data.database.tables.services['svc-beard']!;
      final saved = await business.saveService(beard.copyWith(priceKzt: 4500));
      expect(saved.id, 'svc-beard');
      expect(data.database.tables.services['svc-beard']!.priceKzt, 4500);
    });

    test('validation lists every problem', () {
      expect(
        () => business.saveService(
          draft(
            title: 'ab',
            price: 0,
            duration: const Duration(minutes: 20),
            specialists: const [],
            options: const [
              PriceOption(id: '', label: 'Длинные', priceKzt: 0),
              PriceOption(id: '', label: ' длинные ', priceKzt: 100),
              PriceOption(id: '', label: '', priceKzt: 100),
            ],
          ),
        ),
        issues([
          ServiceIssue.titleLength,
          ServiceIssue.durationOutOfRange,
          ServiceIssue.priceOutOfRange,
          ServiceIssue.optionLabelEmpty,
          ServiceIssue.optionLabelDuplicate,
          ServiceIssue.optionPriceOutOfRange,
          ServiceIssue.noSpecialists,
        ]),
      );
      expect(
        () => business.saveService(
          draft(
            options: [
              for (var i = 0; i <= BusinessRules.maxPriceOptions; i++)
                PriceOption(id: '', label: 'Вариант $i', priceKzt: 1000),
            ],
          ),
        ),
        issues([ServiceIssue.tooManyOptions]),
      );
    });

    test(
      'hidden services disappear from the catalog but stay managed',
      () async {
        await business.setServiceHidden('svc-beard', hidden: true);
        final public = await catalog.fetchServices(organizationId: orgNorth);
        expect(public.map((s) => s.id), isNot(contains('svc-beard')));
        final managed = await business.fetchManagedServices(orgNorth);
        expect(managed.firstWhere((s) => s.id == 'svc-beard').isHidden, isTrue);

        await business.setServiceHidden('svc-beard', hidden: false);
        expect(
          (await catalog.fetchServices(organizationId: orgNorth))
              .map((s) => s.id),
          contains('svc-beard'),
        );
      },
    );
  });

  group('photos', () {
    Future<List<BusinessPhoto>> photos() => catalog.fetchPhotos(orgNorth);

    test('adds up to five photos, then refuses', () async {
      expect(await photos(), hasLength(4), reason: 'demo data has four');
      final added = await business.addPhoto(orgNorth, sourcePath: '/new.jpg');
      expect(added.position, 4);
      expect(added.filePath, startsWith('memory://'));
      expect(storage.stored, contains(added.filePath));

      expect(
        () => business.addPhoto(orgNorth, sourcePath: '/more.jpg'),
        issues([PhotoIssue.limitReached]),
      );
      expect(await photos(), hasLength(Organization.maxPhotos));
    });

    test('checks format and size', () async {
      expect(
        () => business.addPhoto(orgNorth, sourcePath: '/doc.pdf'),
        issues([PhotoIssue.unsupportedFormat]),
      );
      expect(
        () => business.addPhoto(orgNorth, sourcePath: '/big.jpg'),
        issues([PhotoIssue.fileTooLarge]),
      );
    });

    test('remove renumbers the rest and deletes the file', () async {
      final added = await business.addPhoto(orgNorth, sourcePath: '/a.png');
      final first = (await photos()).first;
      await business.removePhoto(first.id);
      await business.removePhoto(added.id);

      final rest = await photos();
      expect(rest.map((p) => p.position), [0, 1, 2]);
      expect(storage.stored, isEmpty);
    });

    test('move changes the gallery order', () async {
      final before = await photos();
      await business.movePhoto(before.last.id, 0);
      final after = await photos();
      expect(after.first.id, before.last.id);
      expect(after.map((p) => p.position), [0, 1, 2, 3]);
    });
  });
}

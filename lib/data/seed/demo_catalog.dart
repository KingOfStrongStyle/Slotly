import '../../features/catalog/domain/organization.dart';
import '../../features/catalog/domain/service.dart';

const orgNorth = 'org-north';
const orgLavanda = 'org-lavanda';
const orgWhiteLine = 'org-white-line';
const orgHealth = 'org-health';
const orgGarage = 'org-garage';
const orgFormula = 'org-formula';

const demoOrganizations = <Organization>[
  Organization(
    id: orgNorth,
    name: 'Барбершоп «Северный»',
    category: ServiceCategory.barbershop,
    description:
        'Мужские стрижки и уход за бородой. Запись на конкретного мастера, '
        'чай и кофе пока ждёте.',
    address: 'ул. Демонстрационная, 12 (демо)',
    phone: '+7 700 000 00 01',
    artworkVariant: 0,
  ),
  Organization(
    id: orgLavanda,
    name: 'Салон красоты «Лаванда»',
    category: ServiceCategory.beauty,
    description: 'Маникюр, окрашивание и укладки. Материалы мастера включены.',
    address: 'пр. Учебный, 5 (демо)',
    phone: '+7 700 000 00 02',
    artworkVariant: 1,
  ),
  Organization(
    id: orgWhiteLine,
    name: 'Стоматология «Белая линия»',
    category: ServiceCategory.dentistry,
    description:
        'Терапия, гигиена и хирургия. Первичная консультация с планом '
        'лечения и сметой.',
    address: 'ул. Примерная, 40 (демо)',
    phone: '+7 700 000 00 03',
    artworkVariant: 2,
  ),
  Organization(
    id: orgHealth,
    name: 'Клиника «Здоровье+»',
    category: ServiceCategory.clinic,
    description: 'Приём терапевта и профилактические осмотры для взрослых.',
    address: 'ул. Тестовая, 8 (демо)',
    phone: '+7 700 000 00 04',
    artworkVariant: 0,
  ),
  Organization(
    id: orgGarage,
    name: 'Автосервис «Гараж 24»',
    category: ServiceCategory.autoService,
    description:
        'Обслуживание легковых автомобилей: масло, шины, тормоза, ходовая.',
    address: 'промзона Условная, 3 (демо)',
    phone: '+7 700 000 00 05',
    artworkVariant: 1,
  ),
  Organization(
    id: orgFormula,
    name: 'Учебный центр «Формула»',
    category: ServiceCategory.tutoring,
    description:
        'Индивидуальные занятия по математике и английскому. Открылись '
        'недавно — отзывов пока нет.',
    address: 'ул. Школьная, 21 (демо)',
    phone: '+7 700 000 00 06',
    artworkVariant: 2,
  ),
];

const _arman = Specialist(
  id: 'sp-arman',
  organizationId: orgNorth,
  name: 'Арман С.',
  role: 'Барбер',
);
const _daniyar = Specialist(
  id: 'sp-daniyar',
  organizationId: orgNorth,
  name: 'Данияр А.',
  role: 'Старший барбер',
);
const _aliya = Specialist(
  id: 'sp-aliya',
  organizationId: orgLavanda,
  name: 'Алия Ж.',
  role: 'Мастер маникюра',
);
const _madina = Specialist(
  id: 'sp-madina',
  organizationId: orgLavanda,
  name: 'Мадина К.',
  role: 'Колорист',
);
const _erlan = Specialist(
  id: 'sp-erlan',
  organizationId: orgWhiteLine,
  name: 'Ерлан О.',
  role: 'Гигиенист',
);
const _saule = Specialist(
  id: 'sp-saule',
  organizationId: orgWhiteLine,
  name: 'Сауле Б.',
  role: 'Стоматолог-терапевт',
);

const _bauyrzhan = Specialist(
  id: 'sp-bauyrzhan',
  organizationId: orgWhiteLine,
  name: 'Бауыржан Т.',
  role: 'Хирург (в отпуске)',
  workingWeekdays: {},
);
const _gulnar = Specialist(
  id: 'sp-gulnar',
  organizationId: orgHealth,
  name: 'Гульнар И.',
  role: 'Терапевт',
);
const _timur = Specialist(
  id: 'sp-timur',
  organizationId: orgGarage,
  name: 'Тимур Н.',
  role: 'Автомеханик',
);
const _ruslan = Specialist(
  id: 'sp-ruslan',
  organizationId: orgGarage,
  name: 'Руслан К.',
  role: 'Шиномонтажник',
);
const _anna = Specialist(
  id: 'sp-anna',
  organizationId: orgFormula,
  name: 'Анна П.',
  role: 'Преподаватель математики',
  workingWeekdays: {1, 2, 3, 4, 5},
);
const _dana = Specialist(
  id: 'sp-dana',
  organizationId: orgFormula,
  name: 'Дана С.',
  role: 'Преподаватель английского',
  workingWeekdays: {1, 2, 3, 4, 5},
);

const demoSpecialists = <Specialist>[
  _arman,
  _daniyar,
  _aliya,
  _madina,
  _erlan,
  _saule,
  _bauyrzhan,
  _gulnar,
  _timur,
  _ruslan,
  _anna,
  _dana,
];

const demoServices = <Service>[
  Service(
    id: 'svc-men-haircut',
    organizationId: orgNorth,
    title: 'Мужская стрижка',
    category: ServiceCategory.barbershop,
    description:
        'Консультация, мытьё головы, стрижка машинкой и ножницами, укладка.',
    duration: Duration(minutes: 45),
    priceKzt: 6000,
    priceOptions: [
      PriceOption(id: 'short', label: 'Короткая', priceKzt: 6000),
      PriceOption(id: 'long', label: 'Удлинённая', priceKzt: 7500),
    ],
    availableSpecialists: [_arman, _daniyar],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-beard',
    organizationId: orgNorth,
    title: 'Оформление бороды',
    category: ServiceCategory.barbershop,
    description: 'Моделирование формы бороды, окантовка и уход маслом.',
    duration: Duration(minutes: 30),
    priceKzt: 4000,
    availableSpecialists: [_arman, _daniyar],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-haircut-beard',
    organizationId: orgNorth,
    title: 'Стрижка и борода',
    category: ServiceCategory.barbershop,
    description: 'Комплекс: стрижка любой длины и оформление бороды.',
    duration: Duration(hours: 1),
    priceKzt: 9000,
    availableSpecialists: [_daniyar],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-kids-haircut',
    organizationId: orgNorth,
    title: 'Детская стрижка',
    category: ServiceCategory.barbershop,
    description: 'Для детей до 12 лет. Мультфильмы на планшете по желанию.',
    duration: Duration(minutes: 30),
    priceKzt: 4500,
    availableSpecialists: [_arman],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-manicure',
    organizationId: orgLavanda,
    title: 'Маникюр с покрытием',
    category: ServiceCategory.beauty,
    description:
        'Аппаратный маникюр, выравнивание и покрытие гель-лаком. '
        'Снятие старого покрытия включено.',
    duration: Duration(hours: 1, minutes: 30),
    priceKzt: 9000,
    priceOptions: [
      PriceOption(id: 'short', label: 'Короткие ногти', priceKzt: 9000),
      PriceOption(id: 'long', label: 'Длинные ногти', priceKzt: 11000),
    ],
    availableSpecialists: [_aliya],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-coloring',
    organizationId: orgLavanda,
    title: 'Окрашивание волос',
    category: ServiceCategory.beauty,
    description:
        'Подбор оттенка, окрашивание в один тон, уход и укладка. '
        'Сложные техники обсуждаются на консультации.',
    duration: Duration(hours: 2),
    priceKzt: 25000,
    priceOptions: [
      PriceOption(id: 'short', label: 'Короткие волосы', priceKzt: 20000),
      PriceOption(id: 'medium', label: 'Средняя длина', priceKzt: 25000),
      PriceOption(id: 'long', label: 'Длинные волосы', priceKzt: 32000),
    ],
    availableSpecialists: [_madina],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-styling',
    organizationId: orgLavanda,
    title: 'Укладка',
    category: ServiceCategory.beauty,
    description: 'Мытьё, сушка и укладка феном или на плойку.',
    duration: Duration(minutes: 45),
    priceKzt: 8000,
    availableSpecialists: [_madina],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-cleaning',
    organizationId: orgWhiteLine,
    title: 'Профессиональная чистка зубов',
    category: ServiceCategory.dentistry,
    description:
        'Ультразвуковая чистка, Air Flow, полировка и рекомендации по '
        'домашнему уходу.',
    duration: Duration(hours: 1),
    priceKzt: 18000,
    availableSpecialists: [_erlan],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-dental-consult',
    organizationId: orgWhiteLine,
    title: 'Консультация стоматолога',
    category: ServiceCategory.dentistry,
    description: 'Осмотр, план лечения и предварительная смета.',
    duration: Duration(minutes: 30),
    priceKzt: 5000,
    availableSpecialists: [_saule, _erlan],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-caries',
    organizationId: orgWhiteLine,
    title: 'Лечение кариеса',
    category: ServiceCategory.dentistry,
    description:
        'Анестезия, лечение и световая пломба. Цена зависит от глубины '
        'поражения.',
    duration: Duration(hours: 1),
    priceKzt: 22000,
    priceOptions: [
      PriceOption(id: 'surface', label: 'Поверхностный', priceKzt: 18000),
      PriceOption(id: 'medium', label: 'Средний', priceKzt: 22000),
      PriceOption(id: 'deep', label: 'Глубокий', priceKzt: 28000),
    ],
    availableSpecialists: [_saule],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-extraction',
    organizationId: orgWhiteLine,
    title: 'Удаление зуба',
    category: ServiceCategory.dentistry,
    description:
        'Простое удаление под местной анестезией. Специалист сейчас в '
        'отпуске — свободного времени нет.',
    duration: Duration(minutes: 45),
    priceKzt: 15000,
    availableSpecialists: [_bauyrzhan],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-therapist',
    organizationId: orgHealth,
    title: 'Приём терапевта',
    category: ServiceCategory.clinic,
    description:
        'Первичный приём, сбор анамнеза и направления на анализы при '
        'необходимости.',
    duration: Duration(minutes: 30),
    priceKzt: 8000,
    availableSpecialists: [_gulnar],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-checkup',
    organizationId: orgHealth,
    title: 'Профилактический осмотр',
    category: ServiceCategory.clinic,
    description: 'Осмотр, давление, ЭКГ и рекомендации на год.',
    duration: Duration(hours: 1),
    priceKzt: 12000,
    availableSpecialists: [_gulnar],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-oil-change',
    organizationId: orgGarage,
    title: 'Замена моторного масла',
    category: ServiceCategory.autoService,
    description:
        'Замена масла и масляного фильтра. Масло клиента или сервиса — '
        'на выбор.',
    duration: Duration(minutes: 45),
    priceKzt: 7000,
    availableSpecialists: [_timur],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-tires',
    organizationId: orgGarage,
    title: 'Сезонный шиномонтаж',
    category: ServiceCategory.autoService,
    description:
        'Снятие и установка четырёх колёс, балансировка, проверка давления.',
    duration: Duration(hours: 1),
    priceKzt: 12000,
    priceOptions: [
      PriceOption(id: 'r13', label: 'R13–R16', priceKzt: 12000),
      PriceOption(id: 'r17', label: 'R17–R19', priceKzt: 16000),
      PriceOption(id: 'r20', label: 'R20 и больше', priceKzt: 20000),
    ],
    availableSpecialists: [_ruslan, _timur],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-diagnostics',
    organizationId: orgGarage,
    title: 'Диагностика ходовой',
    category: ServiceCategory.autoService,
    description: 'Осмотр подвески на подъёмнике и список работ с ценами.',
    duration: Duration(minutes: 45),
    priceKzt: 6000,
    availableSpecialists: [_timur],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-brakes',
    organizationId: orgGarage,
    title: 'Замена тормозных колодок',
    category: ServiceCategory.autoService,
    description: 'Замена передних или задних колодок, проверка дисков.',
    duration: Duration(hours: 1),
    priceKzt: 9000,
    availableSpecialists: [_timur, _ruslan],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-math',
    organizationId: orgFormula,
    title: 'Занятие по математике',
    category: ServiceCategory.tutoring,
    description:
        'Индивидуальное занятие для школьников 5–11 классов: разбор тем и '
        'подготовка к контрольным.',
    duration: Duration(hours: 1),
    priceKzt: 7000,
    availableSpecialists: [_anna],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-english',
    organizationId: orgFormula,
    title: 'Английский: разговорная практика',
    category: ServiceCategory.tutoring,
    description:
        'Разговорное занятие один на один по темам повседневного общения.',
    duration: Duration(hours: 1),
    priceKzt: 6500,
    availableSpecialists: [_dana],
    artworkVariant: 2,
  ),
];

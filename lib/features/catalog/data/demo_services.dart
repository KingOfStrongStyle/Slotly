import '../domain/service.dart';

// Demonstration data. All businesses, specialists and prices are fictional
// and exist only to show the booking flow without a backend.

const _arman = Specialist(id: 'sp-arman', name: 'Арман С.', role: 'Барбер');
const _daniyar = Specialist(
  id: 'sp-daniyar',
  name: 'Данияр А.',
  role: 'Старший барбер',
);
const _aliya = Specialist(
  id: 'sp-aliya',
  name: 'Алия Ж.',
  role: 'Мастер маникюра',
);
const _madina = Specialist(
  id: 'sp-madina',
  name: 'Мадина К.',
  role: 'Колорист',
);
const _erlan = Specialist(id: 'sp-erlan', name: 'Ерлан О.', role: 'Гигиенист');
const _saule = Specialist(
  id: 'sp-saule',
  name: 'Сауле Б.',
  role: 'Стоматолог-терапевт',
);
const _gulnar = Specialist(
  id: 'sp-gulnar',
  name: 'Гульнар И.',
  role: 'Терапевт',
);
const _timur = Specialist(
  id: 'sp-timur',
  name: 'Тимур Н.',
  role: 'Автомеханик',
);
const _ruslan = Specialist(
  id: 'sp-ruslan',
  name: 'Руслан К.',
  role: 'Шиномонтажник',
);
const _anna = Specialist(
  id: 'sp-anna',
  name: 'Анна П.',
  role: 'Преподаватель математики',
);
const _dana = Specialist(
  id: 'sp-dana',
  name: 'Дана С.',
  role: 'Преподаватель английского',
);

const demoServices = <Service>[
  Service(
    id: 'svc-men-haircut',
    title: 'Мужская стрижка',
    category: ServiceCategory.barbershop,
    description:
        'Консультация, мытьё головы, стрижка машинкой и ножницами, укладка.',
    duration: Duration(minutes: 45),
    priceKzt: 6000,
    availableSpecialists: [_arman, _daniyar],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-beard',
    title: 'Оформление бороды',
    category: ServiceCategory.barbershop,
    description: 'Моделирование формы бороды, окантовка и уход маслом.',
    duration: Duration(minutes: 30),
    priceKzt: 4000,
    availableSpecialists: [_arman, _daniyar],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-manicure',
    title: 'Маникюр с покрытием',
    category: ServiceCategory.beauty,
    description:
        'Аппаратный маникюр, выравнивание ногтевой пластины и покрытие '
        'гель-лаком в один тон.',
    duration: Duration(minutes: 90),
    priceKzt: 9000,
    availableSpecialists: [_aliya],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-coloring',
    title: 'Окрашивание волос',
    category: ServiceCategory.beauty,
    description:
        'Подбор оттенка, окрашивание в один тон и уходовая процедура '
        'после окрашивания.',
    duration: Duration(hours: 2),
    priceKzt: 25000,
    availableSpecialists: [_madina],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-cleaning',
    title: 'Профессиональная чистка зубов',
    category: ServiceCategory.dentistry,
    description:
        'Ультразвуковая чистка, Air Flow и полировка. Подходит раз в полгода.',
    duration: Duration(hours: 1),
    priceKzt: 18000,
    availableSpecialists: [_erlan],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-dental-consult',
    title: 'Консультация стоматолога',
    category: ServiceCategory.dentistry,
    description: 'Осмотр, план лечения и рекомендации по уходу.',
    duration: Duration(minutes: 30),
    priceKzt: 5000,
    availableSpecialists: [_saule, _erlan],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-therapist',
    title: 'Приём терапевта',
    category: ServiceCategory.clinic,
    description: 'Первичный приём, сбор жалоб и направление на анализы.',
    duration: Duration(minutes: 30),
    priceKzt: 8000,
    availableSpecialists: [_gulnar],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-oil-change',
    title: 'Замена моторного масла',
    category: ServiceCategory.autoService,
    description:
        'Замена масла и масляного фильтра. Расходники можно привезти свои.',
    duration: Duration(minutes: 45),
    priceKzt: 7000,
    availableSpecialists: [_timur],
    artworkVariant: 1,
  ),
  Service(
    id: 'svc-tires',
    title: 'Сезонный шиномонтаж',
    category: ServiceCategory.autoService,
    description: 'Снятие и установка четырёх колёс, балансировка.',
    duration: Duration(hours: 1),
    priceKzt: 12000,
    availableSpecialists: [_ruslan, _timur],
    artworkVariant: 2,
  ),
  Service(
    id: 'svc-math',
    title: 'Занятие по математике',
    category: ServiceCategory.tutoring,
    description: 'Индивидуальное занятие: подготовка к контрольным и ЕНТ.',
    duration: Duration(hours: 1),
    priceKzt: 7000,
    availableSpecialists: [_anna],
    artworkVariant: 0,
  ),
  Service(
    id: 'svc-english',
    title: 'Английский: разговорная практика',
    category: ServiceCategory.tutoring,
    description: 'Разговорное занятие с преподавателем на заданную тему.',
    duration: Duration(hours: 1),
    priceKzt: 6500,
    availableSpecialists: [_dana],
    artworkVariant: 1,
  ),
];

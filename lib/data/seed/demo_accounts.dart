import '../../features/auth/domain/app_user.dart';
import 'demo_catalog.dart';

class DemoAccount {
  const DemoAccount({
    required this.user,
    required this.password,
    required this.scenario,
  });

  final AppUser user;
  final String password;

  final String scenario;
}

const ownerNorthId = 'user-owner-north';
const ownerWhiteLineId = 'user-owner-white-line';
const clientAliyaId = 'user-client-aliya';
const clientDamirId = 'user-client-damir';
const clientZhannaId = 'user-client-zhanna';
const clientIlyaId = 'user-client-ilya';

const demoAccounts = <DemoAccount>[
  DemoAccount(
    user: AppUser(
      id: clientAliyaId,
      login: 'aliya',
      displayName: 'Алия Н.',
      role: UserRole.client,
    ),
    password: 'aliya-demo',
    scenario: 'Клиент с историей визитов: отзывы, избранное, перенос записи',
  ),
  DemoAccount(
    user: AppUser(
      id: clientDamirId,
      login: 'damir',
      displayName: 'Дамир К.',
      role: UserRole.client,
    ),
    password: 'damir-demo',
    scenario: 'Клиент с будущими записями: напоминания, «Я на месте»',
  ),
  DemoAccount(
    user: AppUser(
      id: ownerNorthId,
      login: 'north',
      displayName: 'Ержан Б.',
      role: UserRole.owner,
      organizationId: orgNorth,
    ),
    password: 'north-demo',
    scenario: 'Владелец барбершопа «Северный»: аналитика, услуги, фото',
  ),
  DemoAccount(
    user: AppUser(
      id: ownerWhiteLineId,
      login: 'whiteline',
      displayName: 'Гаухар М.',
      role: UserRole.owner,
      organizationId: orgWhiteLine,
    ),
    password: 'whiteline-demo',
    scenario: 'Владелец стоматологии «Белая линия»: изоляция данных',
  ),
  DemoAccount(
    user: AppUser(
      id: clientZhannaId,
      login: 'zhanna',
      displayName: 'Жанна Т.',
      role: UserRole.client,
    ),
    password: 'zhanna-demo',
    scenario: 'Дополнительный клиент для истории записей',
  ),
  DemoAccount(
    user: AppUser(
      id: clientIlyaId,
      login: 'ilya',
      displayName: 'Илья В.',
      role: UserRole.client,
    ),
    password: 'ilya-demo',
    scenario: 'Дополнительный клиент для истории записей',
  ),
];

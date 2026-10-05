/// All user-facing Russian texts in one place.
///
/// Keeping strings here (instead of inline in widgets) makes it possible to
/// move to ARB files and `flutter gen-l10n` later without touching layouts.
abstract final class AppStrings {
  // General
  static const appName = 'Slotly';
  static const appTagline = 'Запись на услуги без звонков';
  static const appVersion = '0.1.0';
  static const appVersionLabel = 'Версия $appVersion · учебный MVP';
  static const currencySymbol = '₸';
  static const demoDataNotice =
      'Все услуги, специалисты и записи — демонстрационные данные.';

  static const weekdaysShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
  static const monthsGenitive = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  // Service categories
  static const categoryAll = 'Все';
  static const categoryBarbershop = 'Барбершоп';
  static const categoryBeauty = 'Салон красоты';
  static const categoryDentistry = 'Стоматология';
  static const categoryClinic = 'Клиника';
  static const categoryAutoService = 'Автосервис';
  static const categoryTutoring = 'Репетиторы';

  // Navigation
  static const tabServices = 'Услуги';
  static const tabBookings = 'Записи';
  static const tabProfile = 'Профиль';
}

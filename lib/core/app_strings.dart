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

  // Welcome
  static const welcomeDescription =
      'Выберите услугу, специалиста и удобное время. Запись подтверждается '
      'сразу, без ожидания звонка администратора.';
  static const welcomeChooseCategory = 'Что вас интересует?';
  static const welcomeNoCategory = 'Категория не выбрана — покажем все услуги';
  static String welcomeSelectedCategory(String label) =>
      'Выбрано: $label. Каталог откроется с этим фильтром';
  static const welcomeShowServices = 'Посмотреть услуги';

  // Catalog
  static const catalogTitle = 'Услуги';
  static const catalogSearchHint = 'Найти услугу';
  static const catalogClearSearch = 'Очистить поиск';
  static String catalogFoundCount(int count) => 'Найдено: $count';
  static const catalogEmptyTitle = 'Ничего не найдено';
  static const catalogEmptyMessage =
      'Попробуйте изменить запрос или выбрать другую категорию.';
  static const catalogResetFilters = 'Сбросить фильтры';

  // Lifecycle diagnostics
  static const diagnosticsTitle = 'Диагностика';
  static const diagnosticsCurrentState = 'Текущее состояние';
  static const diagnosticsUnknownState = 'Платформа ещё не сообщила состояние';
  static const diagnosticsJournal = 'Журнал жизненного цикла';
  static const diagnosticsClear = 'Очистить журнал';
  static const diagnosticsCleared = 'Журнал очищен';
  static const diagnosticsHint =
      'Сверните приложение, откройте список недавних приложений или '
      'переключитесь на другое приложение, а затем вернитесь сюда.';
  static const diagnosticsEmptyTitle = 'Событий пока нет';
  static const diagnosticsEmptyMessage =
      'Новые события появятся после сворачивания приложения '
      'или возврата в него.';
  static const lifecycleLaunchPrefix = 'Начальное состояние при запуске. ';
  static const lifecycleResumedTitle = 'Активно';
  static const lifecycleInactiveTitle = 'Неактивно';
  static const lifecycleHiddenTitle = 'Скрыто';
  static const lifecyclePausedTitle = 'Приостановлено';
  static const lifecycleDetachedTitle = 'Отсоединено';
  static const lifecycleResumedDescription =
      'Приложение на экране и принимает ввод пользователя.';
  static const lifecycleInactiveDescription =
      'Приложение видно, но не принимает ввод: например, открыт список '
      'недавних приложений или системная шторка.';
  static const lifecycleHiddenDescription =
      'Интерфейс скрыт. На Android Flutter добавляет это промежуточное '
      'состояние между inactive и paused.';
  static const lifecyclePausedDescription =
      'Приложение в фоне и не видно пользователю. Система может завершить '
      'процесс без дополнительных уведомлений.';
  static const lifecycleDetachedDescription =
      'Движок Flutter работает без видимого окна: Activity уничтожена или '
      'приложение закрывается.';

  // Profile
  static const profileTitle = 'Профиль';
  static const profileDemoUserName = 'Алия Н.';
  static const profileDemoUserInitials = 'АН';
  static const profileDemoUserNote = 'Демонстрационный профиль без авторизации';
  static const profileSettingsSection = 'Настройки';
  static const profileDarkTheme = 'Тёмная тема';
  static const profileDarkThemeHint = 'Переключает светлую и тёмную схему';
  static const profileNotifications = 'Демо-уведомления';
  static const profileNotificationsHint =
      'Напоминание о записи в сообщении после бронирования';
  static const profileToolsSection = 'Учебные инструменты';
  static const profileDiagnosticsHint = 'Жизненный цикл приложения';
  static const profileAboutSection = 'О приложении';
  static const profileAbout = 'О Slotly';
  static const profileAboutText =
      'Учебный MVP сервиса онлайн-записи и электронной очереди для '
      'локального бизнеса. $demoDataNotice';

  // Service details
  static const detailsPrice = 'Стоимость';
  static const detailsDuration = 'Длительность';
  static const detailsCategory = 'Категория';
  static const detailsAbout = 'Об услуге';
  static const detailsSpecialists = 'Специалисты';
  static const detailsBook = 'Записаться';

  // Booking form
  static const bookingTitle = 'Новая запись';
  static const bookingSpecialistSection = 'Специалист';
  static const bookingDateSection = 'Дата';
  static const bookingTimeSection = 'Время';
  static const bookingCommentSection = 'Комментарий';
  static const bookingCommentHint = 'Например: нужна парковка рядом';
  static const bookingCommentOptional = 'Необязательно';
  static String bookingCommentTooLong(int max) =>
      'Комментарий должен быть не длиннее $max символов';
  static const bookingToday = 'Сегодня';
  static const bookingTomorrow = 'Завтра';
  static const bookingChooseSpecialistFirst =
      'Сначала выберите специалиста — покажем свободное время.';
  static const bookingNoSlots =
      'На этот день свободного времени нет. Выберите другую дату.';
  static const bookingSlotsLoadError =
      'Не удалось загрузить расписание. Попробуйте ещё раз.';
  static const bookingRetry = 'Повторить';
  static const bookingSlotTaken = 'Занято';
  static const bookingContinue = 'Продолжить';
  static const bookingMissingPrefix = 'Чтобы продолжить, выберите: ';
  static const bookingMissingSpecialist = 'специалиста';
  static const bookingMissingDate = 'дату';
  static const bookingMissingTime = 'время';
  static const bookingSlotNoLongerAvailable =
      'Это время уже заняли. Выберите другое.';

  // Booking confirmation
  static const confirmTitle = 'Подтвердите запись';
  static const confirmService = 'Услуга';
  static const confirmSpecialist = 'Специалист';
  static const confirmDate = 'Дата';
  static const confirmTime = 'Время';
  static const confirmPrice = 'Стоимость';
  static const confirmComment = 'Комментарий';
  static const confirmEdit = 'Изменить';
  static const confirmSubmit = 'Подтвердить';
  static String bookingCreated(String service, String dateTime) =>
      'Вы записаны: $service, $dateTime';
  static const bookingReminderSuffix = '. Напомним за час до визита (демо)';
}

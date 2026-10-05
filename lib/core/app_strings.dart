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

  // My bookings
  static const bookingsTitle = 'Мои записи';
  static String bookingsActiveTab(int count) => 'Активные ($count)';
  static String bookingsCancelledTab(int count) => 'Отменённые ($count)';
  static const bookingsGestureHint =
      'Нажмите для подробностей, удерживайте для действий, '
      'смахните влево, чтобы отменить.';
  static const bookingsEmptyTitle = 'У вас пока нет записей';
  static const bookingsEmptyMessage =
      'Выберите услугу в каталоге — запись появится здесь.';
  static const bookingsBrowseServices = 'Выбрать услугу';
  static const bookingsCancelledEmptyTitle = 'Отменённых записей нет';
  static const bookingsCancelledEmptyMessage =
      'Здесь будут записи, которые вы отменили.';
  static const bookingsLoadErrorTitle = 'Не удалось загрузить записи';
  static const bookingsLoadErrorMessage = 'Проверьте подключение и повторите.';
  static const bookingsSwipeToCancel = 'Отменить';
  static const bookingStatusConfirmed = 'Подтверждена';
  static const bookingStatusCancelled = 'Отменена';
  static const bookingDetailsTitle = 'Детали записи';
  static const bookingDetailsStatus = 'Статус';
  static const bookingDetailsCreatedAt = 'Создана';
  static const bookingActionDetails = 'Подробнее';
  static const bookingActionCancel = 'Отменить запись';
  static const bookingActionsTitle = 'Действия с записью';
  static const cancelDialogTitle = 'Отменить запись?';
  static String cancelDialogMessage(String service, String dateTime) =>
      '$service, $dateTime. Время освободится для других клиентов.';
  static const cancelDialogKeep = 'Не отменять';
  static const cancelDialogConfirm = 'Отменить запись';
  static const bookingCancelled = 'Запись отменена';
  static const bookingCancelFailed = 'Не удалось отменить запись';

  // Gesture Lab
  static const gestureLabTitle = 'Gesture Lab';
  static const gestureLabHint = 'Стандартные жесты Flutter';
  static const gestureLabClearLog = 'Очистить журнал';
  static const gestureLabLogTitle = 'Журнал жестов';
  static const gestureLabLogEmpty =
      'Выполните жест в зоне выше — событие появится здесь.';
  static const gestureZoneTaps = 'Касания';
  static const gestureZoneHorizontal = 'Горизонтальный drag';
  static const gestureZoneVertical = 'Вертикальный drag';
  static const gestureZoneScale = 'Pinch / масштаб';
  static const gestureCardTitle = 'Демо-карточка';
  static const gestureCardHint =
      'Tap — выбрать, double tap — в избранное, long press — меню';
  static const gestureCardSelected = 'Выбрана';
  static const gestureCardNotSelected = 'Не выбрана';
  static const gestureCardFavorite = 'В избранном';
  static const gestureMenuTitle = 'Действия с карточкой';
  static const gestureMenuSelect = 'Выбрать';
  static const gestureMenuUnselect = 'Снять выбор';
  static const gestureMenuFavorite = 'Добавить в избранное';
  static const gestureMenuUnfavorite = 'Убрать из избранного';
  static const gestureMenuReset = 'Сбросить состояние';
  static const gestureHorizontalHint = 'Проведите пальцем влево или вправо';
  static const gestureVerticalHint = 'Проведите пальцем вверх или вниз';
  static const gestureScaleHint =
      'Сведите или разведите два пальца. На эмуляторе: удерживайте Cmd '
      '(macOS) или Ctrl и тяните мышью.';
  static const gestureScaleReset = 'Сбросить масштаб';
  static const gestureDirectionLeft = 'влево';
  static const gestureDirectionRight = 'вправо';
  static const gestureDirectionUp = 'вверх';
  static const gestureDirectionDown = 'вниз';
  static String gestureDirection(String direction) => 'Направление: $direction';
  static String gestureVelocity(int value) => 'Скорость: $value dp/с';
  static String gestureOffset(int value) => 'Смещение: $value dp';
  static String gestureScale(String value) => 'Масштаб: $value×';
  static const gestureLogTap = 'Tap: карточка выбрана';
  static const gestureLogTapUnselect = 'Tap: выбор снят';
  static const gestureLogDoubleTapOn = 'Double tap: добавлено в избранное';
  static const gestureLogDoubleTapOff = 'Double tap: убрано из избранного';
  static const gestureLogLongPress = 'Long press: открыто меню действий';
  static String gestureLogMenuAction(String action) => 'Меню: $action';
  static String gestureLogHorizontal(String direction, int velocity) =>
      'Горизонтальный drag: $direction, $velocity dp/с';
  static String gestureLogVertical(String direction, int distance) =>
      'Вертикальный drag: $direction на $distance dp';
  static String gestureLogScale(String scale) => 'Pinch: масштаб $scale×';
  static const gestureLogScaleReset = 'Масштаб сброшен';

  // Ticket check-in
  static const checkInTitle = 'Ввод талона';
  static const checkInProfileHint = 'Рукописный ввод номера';
  static const checkInTemplates = 'Как рисовать символы';
  static const checkInTemplatesHint =
      'Рисуйте крупно, одним или двумя штрихами. Точка — начало штриха. '
      'Символ S завершает ввод.';
  static const checkInNumberLabel = 'Номер талона';
  static const checkInNumberPlaceholder = '—';
  static const checkInInstructions =
      'Нарисуйте цифру и нажмите «Распознать». После номера нарисуйте S.';
  static const checkInPadHint = 'Рисуйте здесь';
  static const checkInPadLabel = 'Поле для рукописного ввода';
  static const checkInRecognize = 'Распознать';
  static const checkInUndo = 'Отменить штрих';
  static const checkInClearPad = 'Очистить поле';
  static const checkInBackspace = 'Стереть цифру';
  static const checkInReset = 'Новый ввод';
  static String checkInDigitAdded(String digit, int confidence) =>
      'Распознано: $digit (уверенность $confidence%)';
  static String checkInNotRecognized(String? guess, int confidence) =>
      guess == null
      ? 'Жест не распознан: слишком короткий штрих. Попробуйте ещё раз.'
      : 'Жест не распознан. Ближе всего «$guess», но уверенность только '
            '$confidence%. Попробуйте ещё раз.';
  static String checkInTooLong(int max) =>
      'Номер талона не длиннее $max цифр. Нарисуйте S или сотрите цифру.';
  static const checkInNumberEmpty = 'Сначала введите цифры номера, затем S.';
  static const checkInSearching = 'Проверяем талон…';
  static String checkInFound(String number) => 'Талон $number найден';
  static String checkInNotFound(String number) =>
      'Талон $number не найден. Проверьте номер и введите заново.';
  static String checkInPeopleAhead(int count) => 'Перед вами: $count';
  static const ticketWaiting = 'Ожидает вызова';
  static const ticketCalled = 'Вас вызывают';
  static const ticketCompleted = 'Обслуживание завершено';
}

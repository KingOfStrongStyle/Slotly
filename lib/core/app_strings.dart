abstract final class AppStrings {
  static const appName = 'Slotly';
  static const appTagline = 'Запись на услуги без звонков';
  static const appVersion = '0.2.0';
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

  static const categoryAll = 'Все';
  static const categoryBarbershop = 'Барбершоп';
  static const categoryBeauty = 'Салон красоты';
  static const categoryDentistry = 'Стоматология';
  static const categoryClinic = 'Клиника';
  static const categoryAutoService = 'Автосервис';
  static const categoryTutoring = 'Репетиторы';

  static const tabBookings = 'Записи';
  static const tabProfile = 'Профиль';

  static const welcomeDescription =
      'Выберите услугу, специалиста и удобное время. Запись подтверждается '
      'сразу, без ожидания звонка администратора.';
  static const welcomeChooseCategory = 'Что вас интересует?';
  static const welcomeNoCategory = 'Категория не выбрана — покажем все услуги';
  static String welcomeSelectedCategory(String label) =>
      'Выбрано: $label. Каталог откроется с этим фильтром';
  static const welcomeShowServices = 'Продолжить';

  static const catalogClearSearch = 'Очистить поиск';
  static String catalogFoundCount(int count) => 'Найдено: $count';
  static const catalogEmptyTitle = 'Ничего не найдено';
  static const catalogEmptyMessage =
      'Попробуйте изменить запрос или выбрать другую категорию.';
  static const catalogResetFilters = 'Сбросить фильтры';

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

  static const profileTitle = 'Профиль';
  static const profileSettingsSection = 'Настройки';
  static const profileDarkTheme = 'Тёмная тема';
  static const profileDarkThemeHint = 'Переключает светлую и тёмную схему';
  static const profileDiagnosticsHint = 'Жизненный цикл приложения';
  static const profileAboutSection = 'О приложении';
  static const profileAbout = 'О Slotly';
  static const profileAboutText =
      'Учебный MVP сервиса онлайн-записи и электронной очереди для '
      'локального бизнеса. $demoDataNotice';

  static const detailsPrice = 'Стоимость';
  static const detailsDuration = 'Длительность';
  static const detailsCategory = 'Категория';
  static const detailsAbout = 'Об услуге';
  static const detailsSpecialists = 'Специалисты';
  static const detailsBook = 'Записаться';

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
  static String bookingCreatedTicket(String ticket) =>
      '. Талон $ticket — назовите или нарисуйте его по приходу';

  static const bookingsTitle = 'Мои записи';
  static String bookingsActiveTab(int count) => 'Активные ($count)';
  static String bookingsCancelledTab(int count) => 'Отменённые ($count)';
  static String bookingsPastTab(int count) => 'Прошедшие ($count)';
  static const bookingsGestureHint =
      'Нажмите для подробностей, удерживайте для действий. Смахните влево, '
      'чтобы отменить, вправо — чтобы перенести.';
  static const bookingsPastEmptyTitle = 'Завершённых визитов нет';
  static const bookingsPastEmptyMessage =
      'После визита запись появится здесь — можно будет оставить отзыв.';
  static const bookingStatusCompleted = 'Визит состоялся';
  static const bookingReviewed = 'Отзыв оставлен';
  static const bookingDetailsPlace = 'Место';
  static const bookingDetailsPrice = 'Стоимость';
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
  static const bookingStatusCheckedIn = 'Вы на месте';
  static const bookingTicket = 'Талон';
  static String bookingTicketShort(String ticket) => 'Талон $ticket';
  static String bookingCheckedInAt(String time) => 'Вы на месте с $time';
  static String bookingCheckInOpensAt(String time) =>
      'Отметиться о приходе можно с $time';
  static const bookingCheckInAction = 'Я на месте';
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

  static const gestureLabTitle = 'Gesture Lab';
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

  static const checkInTitle = 'Отметка о приходе';
  static const checkInTemplates = 'Как рисовать символы';
  static const checkInTemplatesHint =
      'Рисуйте крупно, одним или двумя штрихами. Точка — начало штриха. '
      'Символ S завершает ввод.';
  static const checkInNumberLabel = 'Номер талона';
  static const checkInNumberPlaceholder = '—';
  static const checkInInstructions =
      'Нарисуйте номер талона по одной цифре и нажмите «Распознать». '
      'В конце нарисуйте S.';
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
  static const checkInSearching = 'Отмечаем приход…';
  static String checkInSuccess(String number) =>
      'Талон $number: приход отмечен';
  static String checkInStartsAt(String time, String specialist) =>
      'Начало в $time. $specialist пригласит вас.';
  static String checkInAlready(String number, String time) =>
      'Талон $number уже отмечен в $time.';
  static String checkInTooEarly(String number, String time) =>
      'Отметиться по талону $number можно с $time — за час до начала.';
  static String checkInExpired(String number) =>
      'Время визита по талону $number уже прошло. Запишитесь заново.';
  static String checkInCancelled(String number) =>
      'Запись по талону $number отменена.';
  static String checkInNotFound(String number) =>
      'Талон $number не найден. Проверьте номер и введите заново.';
  static const checkInFailed =
      'Не удалось отметить приход. Попробуйте ещё раз.';

  static const signInTitle = 'Вход';
  static const signInSubtitle =
      'Войдите как клиент, чтобы записываться, или как владелец, чтобы '
      'управлять организацией.';
  static const signInLogin = 'Логин';
  static const signInPassword = 'Пароль';
  static const signInShowPassword = 'Показать пароль';
  static const signInHidePassword = 'Скрыть пароль';
  static const signInSubmit = 'Войти';
  static const signInLoginRequired = 'Введите логин';
  static const signInPasswordRequired = 'Введите пароль';
  static const signInInvalid = 'Неверный логин или пароль';
  static const signInDemoNotice =
      'Демо-вход: аккаунты и пароли публичные, данные хранятся только на '
      'этом устройстве. Это не защищённая авторизация.';
  static const signInDemoAccounts = 'Демо-аккаунты';
  static const roleClient = 'Клиент';
  static const roleOwner = 'Владелец';
  static const signOut = 'Выйти';
  static const signOutConfirmTitle = 'Выйти из аккаунта?';
  static const signOutConfirmMessage =
      'Напоминания о записях на этом устройстве будут отключены до '
      'следующего входа.';
  static const signOutCancel = 'Остаться';

  static const tabCatalog = 'Каталог';
  static const tabFavorites = 'Избранное';

  static const catalogOrganizations = 'Места';
  static const catalogServices = 'Услуги';
  static const catalogSearchOrganizationsHint = 'Найти место или услугу';
  static const ratingNoReviews = 'Нет отзывов';
  static String ratingLabel(String average, int count) =>
      'Рейтинг $average из 5, ${reviewsCount(count)}';
  static String reviewsCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    final word = mod10 == 1 && mod100 != 11
        ? 'отзыв'
        : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
        ? 'отзыва'
        : 'отзывов';
    return '$count $word';
  }

  static const favoriteAdd = 'Добавить в избранное';
  static const favoriteRemove = 'Убрать из избранного';
  static const favoriteAdded = 'Добавлено в избранное';
  static const favoriteRemoved = 'Убрано из избранного';
  static const favoriteDoubleTapHint = 'Двойное касание — в избранное';
  static const favoritesTitle = 'Избранное';
  static const favoritesEmptyTitle = 'Здесь пока пусто';
  static const favoritesEmptyMessage =
      'Нажмите на сердце или дважды коснитесь карточки места, чтобы '
      'сохранить его здесь.';
  static const organizationServices = 'Услуги и цены';
  static const organizationSpecialists = 'Специалисты';
  static const organizationReviews = 'Отзывы';
  static const organizationAddress = 'Адрес';
  static const organizationPhone = 'Телефон';
  static const organizationAllReviews = 'Все отзывы';
  static const organizationNoServices = 'Сейчас нет доступных услуг.';
  static const organizationLoadError = 'Не удалось загрузить данные места.';
  static String priceFrom(String price) => 'от $price';
  static String specialistRating(String average, int count) =>
      '★ $average · ${reviewsCount(count)}';
  static const specialistFewReviews = 'Мало отзывов для рейтинга';
  static String galleryPosition(int index, int total) => '$index из $total';
  static const galleryClose = 'Закрыть';
  static const galleryResetZoom = 'Сбросить масштаб';
  static const galleryHint =
      'Разведите пальцы, чтобы приблизить. Смахните вниз, чтобы закрыть.';
  static const photoUnavailable = 'Фото недоступно';
  static String photoLabel(String organization, int index) =>
      'Фото $index, $organization';

  static const reviewsEmptyTitle = 'Отзывов пока нет';
  static const reviewsEmptyMessage =
      'Отзыв может оставить клиент после завершённого визита.';
  static const reviewsSortNewest = 'Сначала новые';
  static const reviewsSortHighest = 'Сначала высокие оценки';
  static const reviewsSortLowest = 'Сначала низкие оценки';
  static const reviewsSort = 'Сортировка';
  static String starsCountLabel(int stars, int count) =>
      '$stars звезд: ${reviewsCount(count)}';
  static const reviewEdited = 'изменён';
  static const reviewOwnerReply = 'Ответ владельца';
  static const reviewYours = 'Ваш отзыв';
  static const reviewWrite = 'Оставить отзыв';
  static const reviewEdit = 'Изменить отзыв';
  static const reviewDelete = 'Удалить отзыв';
  static const reviewActions = 'Действия с отзывом';
  static const reviewFormTitle = 'Ваш отзыв';
  static const reviewFormRating = 'Оценка';
  static const reviewFormRatingRequired = 'Поставьте оценку от 1 до 5';
  static const reviewFormText = 'Что понравилось или нет';
  static const reviewFormTextHint = 'Необязательно';
  static String reviewFormTextTooLong(int max) =>
      'Отзыв должен быть не длиннее $max символов';
  static const reviewFormSubmit = 'Опубликовать';
  static const reviewFormSave = 'Сохранить';
  static String reviewStarSemantics(int stars) => 'Оценка $stars из 5';
  static const reviewPublished = 'Отзыв опубликован';
  static const reviewUpdated = 'Отзыв изменён';
  static const reviewDeleted = 'Отзыв удалён';
  static const reviewDeleteConfirmTitle = 'Удалить отзыв?';
  static const reviewDeleteConfirmMessage =
      'Отзыв исчезнет со страницы места, рейтинг пересчитается.';
  static const reviewDeleteConfirm = 'Удалить';
  static const reviewKeep = 'Оставить';
  static const reviewNotAllowed =
      'Отзыв можно оставить только один раз и только после завершённого '
      'визита.';
  static const reviewFailed = 'Не удалось сохранить отзыв';

  static const bookingPriceSection = 'Вариант';
  static const bookingMissingPriceOption = 'вариант услуги';
  static const rescheduleTitle = 'Перенос записи';
  static const rescheduleSubmit = 'Перенести';
  static const rescheduleConfirmTitle = 'Перенести запись?';
  static String rescheduleConfirmMessage(String from, String to) =>
      'Было: $from\nСтанет: $to';
  static String rescheduled(String dateTime) =>
      'Запись перенесена на $dateTime';
  static const rescheduleCurrent = 'Сейчас';
  static const bookingActionReschedule = 'Перенести';
  static const bookingsSwipeToReschedule = 'Перенести';
  static const bookingLocked =
      'Запись уже нельзя изменить: визит начался или вы отметились.';
  static const bookingChangeFailed = 'Не удалось изменить запись';

  static const ownerTabDashboard = 'Обзор';
  static const ownerTabBookings = 'Записи';
  static const ownerTabServices = 'Услуги';
  static const ownerTabReviews = 'Отзывы';
  static const ownerTabOrganization = 'Организация';

  static const dashboardTitle = 'Обзор';
  static const periodLabel = 'Период';
  static String periodDays(int days) => '$days дней';
  static const kpiBookings = 'Записи';
  static const kpiCompleted = 'Состоялись';
  static const kpiCancelled = 'Отмены';
  static String kpiCancellationRate(String percent) => '$percent от всех';
  static const kpiRating = 'Рейтинг за период';
  static String kpiOverallRating(String value) => 'за всё время $value';
  static const kpiNewReviews = 'Новые отзывы';
  static const kpiFavorites = 'В избранное';
  static const kpiNoData = '—';
  static const kpiTopSpecialist = 'Самый востребованный специалист';
  static const kpiTopService = 'Самая популярная услуга';
  static String kpiTopValue(String name, int count) => '$name · $count';
  static const chartBookingsDaily = 'Записи по дням';
  static const chartBookingsWeekly = 'Записи по неделям';
  static const chartStatuses = 'Статусы записей';
  static const chartBySpecialist = 'Записи по специалистам';
  static const chartByService = 'Популярность услуг';
  static const chartReviews = 'Новые отзывы';
  static const chartFavorites = 'Добавления в избранное';
  static const chartShowTable = 'Показать таблицей';
  static const chartShowChart = 'Показать графиком';
  static const chartTapHint = 'Коснитесь столбца, чтобы увидеть значение';
  static const chartNoData = 'Нет данных за период';
  static String chartSummary(String title, int total, String max) =>
      '$title: всего $total, максимум $max';
  static String chartBarValue(String label, num value) => '$label: $value';
  static const chartColumnPeriod = 'Период';
  static const chartColumnValue = 'Значение';
  static const chartOther = 'Остальные';
  static const statusConfirmed = 'Ожидаются';
  static const statusCompleted = 'Состоялись';
  static const statusCancelled = 'Отменены';
  static const dashboardEmptyTitle = 'За этот период данных нет';
  static const dashboardEmptyMessage =
      'Выберите период подлиннее или дождитесь первых записей.';
  static const dashboardLoadError = 'Не удалось загрузить аналитику';
  static const dashboardFormulaNote =
      'Показатели рассчитываются из записей, отзывов и избранного вашей '
      'организации. Отмены не учитываются в рейтинге специалистов и услуг.';

  static const ownerBookingsTitle = 'Записи организации';
  static const ownerBookingsToday = 'Сегодня';
  static const ownerBookingsUpcoming = 'Предстоящие';
  static const ownerBookingsPast = 'Прошедшие';
  static const ownerBookingsEmpty = 'Записей нет';
  static const ownerBookingsEmptyMessage = 'Здесь появятся записи клиентов.';
  static const ownerBookingComplete = 'Визит состоялся';
  static const ownerBookingCompleted = 'Визит отмечен как состоявшийся';
  static const ownerCheckIn = 'Отметить приход по талону';
  static String ownerBookingClient(String name) => 'Клиент: $name';
  static const ownerBookingsHint =
      'Нажмите на запись для подробностей. Отметьте визит, когда клиент '
      'ушёл, — после этого он сможет оставить отзыв.';

  static const ownerServicesTitle = 'Услуги и цены';
  static const ownerServiceAdd = 'Добавить услугу';
  static const ownerServiceEdit = 'Изменить';
  static const ownerServiceHide = 'Скрыть от клиентов';
  static const ownerServiceShow = 'Показывать клиентам';
  static const ownerServiceHidden = 'Скрыта';
  static const ownerServiceHiddenSnack = 'Услуга скрыта';
  static const ownerServiceShownSnack = 'Услуга снова видна клиентам';
  static const ownerServiceActions = 'Действия с услугой';
  static const ownerServicesHint =
      'Удерживайте услугу или нажмите «⋮», чтобы изменить или скрыть её.';
  static const serviceEditorNew = 'Новая услуга';
  static const serviceEditorEdit = 'Редактирование услуги';
  static const serviceFieldTitle = 'Название';
  static const serviceFieldDescription = 'Описание';
  static const serviceFieldDuration = 'Длительность';
  static const serviceFieldPrice = 'Базовая цена, ₸';
  static const serviceFieldPriceHint = 'Используется, если нет вариантов цены';
  static const serviceFieldOptions = 'Варианты цены';
  static const serviceFieldOptionsHint =
      'Например, «Короткие волосы» и «Длинные волосы». Клиент выберет '
      'вариант при записи.';
  static const serviceOptionLabel = 'Вариант';
  static const serviceOptionPrice = 'Цена, ₸';
  static const serviceOptionAdd = 'Добавить вариант';
  static const serviceOptionRemove = 'Удалить вариант';
  static const serviceFieldSpecialists = 'Кто оказывает услугу';
  static const serviceFieldHidden = 'Скрыть от клиентов';
  static const serviceSave = 'Сохранить';
  static const serviceSaved = 'Услуга сохранена';
  static String serviceTitleLength(int min, int max) =>
      'От $min до $max символов';
  static String serviceDescriptionTooLong(int max) =>
      'Не длиннее $max символов';
  static const servicePriceInvalid = 'Введите цену от 1 до 1 000 000 ₸';
  static const serviceOptionLabelEmpty = 'Назовите вариант';
  static const serviceOptionLabelDuplicate = 'Названия вариантов повторяются';
  static String serviceTooManyOptions(int max) => 'Не больше $max вариантов';
  static const serviceNoSpecialists = 'Выберите хотя бы одного специалиста';

  static const ownerReviewsTitle = 'Отзывы клиентов';
  static const ownerReviewReply = 'Ответить';
  static const ownerReplyTitle = 'Ответ на отзыв';
  static const ownerReplyHint = 'Ответ увидят все клиенты';
  static const ownerReplySend = 'Опубликовать ответ';
  static const ownerReplySent = 'Ответ опубликован';
  static const ownerReplyEmpty = 'Напишите ответ';
  static String ownerReplyTooLong(int max) => 'Не длиннее $max символов';
  static const ownerReviewsNote =
      'Владелец может ответить на отзыв, но не может изменить или удалить '
      'его.';

  static const businessTitle = 'Организация';
  static const businessProfileSection = 'Профиль';
  static const businessFieldName = 'Название';
  static const businessFieldDescription = 'Описание';
  static const businessFieldAddress = 'Адрес (демо)';
  static const businessFieldPhone = 'Телефон (демо)';
  static const businessSave = 'Сохранить изменения';
  static const businessSaved = 'Профиль организации сохранён';
  static const businessNameLength = 'От 3 до 60 символов';
  static const businessDescriptionTooLong = 'Не длиннее 600 символов';
  static const businessAddressEmpty = 'Укажите адрес';
  static const businessPhoneInvalid =
      'Номер из 7–20 цифр, можно +, пробелы, скобки и дефисы';
  static const businessPhotosSection = 'Фотографии';
  static String businessPhotosCount(int count, int max) =>
      '$count из $max. Первое фото — обложка в каталоге.';
  static const businessPhotoAdd = 'Добавить фото';
  static const businessPhotoRemove = 'Удалить фото';
  static const businessPhotoMoveLeft = 'Переместить выше';
  static const businessPhotoMoveRight = 'Переместить ниже';
  static const businessPhotoRemoveTitle = 'Удалить фото?';
  static const businessPhotoRemoveMessage =
      'Фото исчезнет из галереи организации.';
  static const businessPhotoAdded = 'Фото добавлено';
  static const businessPhotoRemoved = 'Фото удалено';
  static const businessPhotoLimit = 'Можно добавить не больше 5 фотографий';
  static const businessPhotoFormat = 'Поддерживаются JPG, PNG, WEBP и HEIC';
  static const businessPhotoTooLarge = 'Файл больше 8 МБ';
  static const businessPhotoFailed = 'Не удалось добавить фото';
  static const businessPreview = 'Как видят клиенты';
  static const businessSettingsSection = 'Настройки';

  static const profileReminders = 'Напоминания о записях';
  static const profileRemindersHint = 'Накануне, утром в день визита и за час';
  static const profileDevSection = 'Для разработчиков';
  static const profileGestureLabHint = 'Песочница жестов для ЛР №3';
  static const profileSignedInAs = 'Логин';
  static const profileDemoAccountNote =
      'Демо-аккаунт: данные хранятся только на этом устройстве';

  static const remindersTitle = 'Напоминания';
  static const remindersEnabled = 'Напоминать о записях';
  static const remindersEnabledHint =
      'Накануне в 18:00, утром в день визита в 08:00 и за час до начала';
  static const remindersPermission = 'Разрешение на уведомления';
  static const remindersPermissionGranted = 'Разрешено';
  static const remindersPermissionDenied =
      'Запрещено. Напоминания запланированы, но Android их не покажет. '
      'Разрешите уведомления для Slotly в настройках телефона.';
  static const remindersPermissionUnknown = 'Ещё не запрашивалось';
  static const remindersRequestPermission = 'Разрешить уведомления';
  static const remindersPlanned = 'Запланировано';
  static const remindersPlannedEmpty =
      'Нет будущих напоминаний: нет предстоящих записей или все моменты '
      'уже прошли.';
  static String remindersPendingInSystem(int count) =>
      'В системе Android запланировано: $count';
  static const remindersLocalNote =
      'Это локальные напоминания: их планирует само приложение на этом '
      'телефоне, без сервера. Они не придут на другое устройство и '
      'пропадут после переустановки. Push-уведомления от сервера — в плане '
      'развития.';
  static const reminderKindDayBefore = 'Накануне';
  static const reminderKindMorning = 'Утром в день визита';
  static const reminderKindHourBefore = 'За час';
  static String reminderTitle(String service) => 'Запись: $service';
  static String reminderDayBefore(String place, String time) =>
      'Завтра в $time — $place. Талон в приложении.';
  static String reminderMorning(String place, String time) =>
      'Сегодня в $time — $place.';
  static String reminderHourBefore(String place, String time) =>
      'Через час, в $time — $place. По приходу нажмите «Я на месте».';
}

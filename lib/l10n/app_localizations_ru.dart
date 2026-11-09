// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get language => 'Язык';

  @override
  String get languageSaveFailed =>
      'Не удалось сохранить язык. Попробуйте ещё раз.';

  @override
  String get uiAcademicProgress => 'Успеваемость';

  @override
  String get uiPointsGradesAndPassResultsOrganisedBySemester =>
      'Баллы, оценки и зачёты по семестрам — в одном месте.';

  @override
  String get uiSignInWithYourUniversityAccountToView =>
      'Войдите с учётной записью университета, чтобы увидеть свою успеваемость.';

  @override
  String get uiCouldNotLoadAcademicProgress => 'Не удалось загрузить зачётку';

  @override
  String get uiTryAgain => 'Повторить';

  @override
  String get uiCouldNotRetrieveAcademicProgress =>
      'Не удалось получить зачётку';

  @override
  String get uiNoDataYet => 'Пока нет данных';

  @override
  String get uiPullDownToRefresh => 'Потяните вниз, чтобы обновить.';

  @override
  String get uiVgspuPortal => 'Портал ВГСПУ';

  @override
  String get uiPointsAbsencesAndSubjectResults =>
      'Баллы, пропуски и результаты по предметам.';

  @override
  String get uiNoSemester => 'Без семестра';

  @override
  String uiSemester(String p0) {
    return '$p0 семестр';
  }

  @override
  String get uiEachCheckpointShowsCumulativePointsAndHoursMissed =>
      'В каждом срезе указаны накопленные баллы и пропущенные часы. Значения взяты с портала и не складываются между срезами.';

  @override
  String get uiSchedule => 'Расписание';

  @override
  String get uiUniversity => 'Университет';

  @override
  String get uiSettings => 'Настройки';

  @override
  String get uiCouldNotReadTheDocumentsPleaseReopenThis =>
      'Не удалось прочитать документы. Откройте экран ещё раз.';

  @override
  String get uiYourChoiceHasBeenSaved => 'Выбор сохранён.';

  @override
  String get uiAnalyticsIsOffPreviouslySharedDataIsNot =>
      'Аналитика отключена. Ранее переданные данные не удаляются автоматически: unio.support@gmail.com.';

  @override
  String uiTheServerRecordWillBeSentAgainWhen(String p0) {
    return '$p0 Серверная запись будет повторно отправлена при открытии приложения.';
  }

  @override
  String get uiCouldNotCompleteTheChangePleaseTryAgain =>
      'Не удалось завершить изменение. Повторите действие.';

  @override
  String get uiCouldNotSaveYourChoicePleaseTryAgain =>
      'Не удалось сохранить выбор. Попробуйте ещё раз.';

  @override
  String get uiDeleteAccountAndData => 'Удалить аккаунт и данные?';

  @override
  String get uiThisDeletesYourUnioServerAccountLocalSign =>
      'Будут удалены аккаунт UNIO на сервере, локальные средства входа, заметки и их фотографии, кеши и история согласий. Обработка на основании согласия прекратится.\n\nПри отсутствии сети удаление на сервере останется в очереди. До подтверждения в защищённом хранилище останется только токен для выполнения запроса. Откройте приложение с интернетом до его удаления.\n\nДокументы в ВГСПУ, оригиналы фото, экспортированные файлы, резервные копии сервера и ранее отправленные данные MyTracker не удаляются этой кнопкой. Для обращения: unio.support@gmail.com.';

  @override
  String get uiCancel => 'Отмена';

  @override
  String get uiDelete => 'Удалить';

  @override
  String get uiDocumentsAndData => 'Документы и данные';

  @override
  String get uiYourChoices => 'Ваш выбор';

  @override
  String get uiDataManagement => 'Управление данными';

  @override
  String get uiAnalyticsIsOptionalDecliningDoesNotLimitUnio =>
      'Аналитика добровольна. Отказ от неё не ограничивает функции UNIO.';

  @override
  String get uiIAcceptTheUserAgreement =>
      'Принимаю пользовательское соглашение';

  @override
  String get uiIConsentToUnioProcessingMyPersonalData =>
      'Даю согласие на обработку персональных данных UNIO';

  @override
  String get uiSeparateConsentThePolicyAndFullTextAre =>
      'Отдельное согласие. Политика и полный текст доступны выше.';

  @override
  String get uiMytrackerIsNotUsedInTheWebApp =>
      'MyTracker в веб-версии не используется. Локальные данные хранятся в браузере; очистка данных сайта удалит заметки и вход. Перед очисткой дождитесь подтверждения удаления аккаунта на сервере.';

  @override
  String get uiIGiveSeparateConsentToMytracker =>
      'Даю отдельное согласие на MyTracker';

  @override
  String get uiOptionalYouCanWithdrawConsentHereAtAny =>
      'Необязательно. Можно отозвать здесь в любой момент.';

  @override
  String get uiSaving => 'Сохраняем…';

  @override
  String get uiContinue => 'Продолжить';

  @override
  String get uiSignOutWithoutAccepting => 'Выйти без принятия';

  @override
  String get uiWithdrawConsentAndDeleteData =>
      'Отозвать согласие и удалить данные';

  @override
  String get uiNotesAreKeptUntilYouDeleteThemInactive =>
      'Заметки хранятся до удаления вами. Неактивные серверные аккаунты удаляются через 90 дней. Для запросов о данных: unio.support@gmail.com.';

  @override
  String get uiCouldNotOpenThisNoteOnYourDevice =>
      'Не удалось открыть заметку на устройстве. Попробуйте ещё раз.';

  @override
  String get uiCouldNotSaveTheNoteCheckAvailableStorage =>
      'Не удалось сохранить заметку. Проверьте свободное место и попробуйте ещё раз.';

  @override
  String get uiSavedOnThisDevice => 'Сохранено на устройстве';

  @override
  String get uiCouldNotReadThePhotoChooseAnotherImage =>
      'Не удалось прочитать фото. Выберите другое изображение.';

  @override
  String get uiCouldNotOpenPhotosCheckAppPermissionsAnd =>
      'Не удалось открыть фотографии. Проверьте разрешения приложения и попробуйте ещё раз.';

  @override
  String get uiDeleteNote => 'Удалить заметку?';

  @override
  String get uiThisClassNoteAndItsAttachedPhotosWill =>
      'Текст и прикреплённые фото этой пары будут удалены из приложения. Оригиналы в галерее останутся.';

  @override
  String get uiNoteDeleted => 'Заметка удалена';

  @override
  String get uiCouldNotDeleteTheNotePleaseTryAgain =>
      'Не удалось удалить заметку. Попробуйте ещё раз.';

  @override
  String get uiSaveChanges => 'Сохранить изменения?';

  @override
  String get uiThisNoteHasUnsavedChanges =>
      'В заметке есть несохранённые изменения.';

  @override
  String get uiKeepEditing => 'Продолжить редактирование';

  @override
  String get uiDiscardChanges => 'Не сохранять';

  @override
  String get uiSave => 'Сохранить';

  @override
  String get uiAddHomework => 'Записать ДЗ';

  @override
  String get uiFromGallery => 'Из галереи';

  @override
  String get uiTakeAPhoto => 'Снять фото';

  @override
  String get uiHomeworkAndNotes => 'ДЗ и заметки';

  @override
  String get uiDeleteNote59 => 'Удалить заметку';

  @override
  String get uiNoteUnavailable => 'Заметка недоступна';

  @override
  String get uiClassNote => 'Заметка к паре';

  @override
  String get uiWhatIsTheAssignmentWriteDownHomeworkOr =>
      'Что задали?\nЗапиши задание или важную мысль…';

  @override
  String get uiPhotos => 'Фотографии';

  @override
  String get uiAddAssignmentPhotosFromYourGalleryOrCamera =>
      'Фото задания можно добавить из галереи или с камеры.';

  @override
  String get uiNotesAndPhotosAreStoredOnlyOnThis =>
      'Заметки и фото хранятся только на этом устройстве и доступны без интернета. При удалении приложения или его данных они будут потеряны.';

  @override
  String get uiUniversityNews => 'Новости университета';

  @override
  String get uiCouldNotLoadThisArticle => 'Не удалось загрузить новость';

  @override
  String get uiArticleNotFound => 'Новость не найдена';

  @override
  String get uiThisArticleIsNoLongerAvailable => 'Материал больше недоступен.';

  @override
  String get uiJanuary => 'января';

  @override
  String get uiFebruary => 'февраля';

  @override
  String get uiMarch => 'марта';

  @override
  String get uiApril => 'апреля';

  @override
  String get uiMay => 'мая';

  @override
  String get uiJune => 'июня';

  @override
  String get uiJuly => 'июля';

  @override
  String get uiAugust => 'августа';

  @override
  String get uiSeptember => 'сентября';

  @override
  String get uiOctober => 'октября';

  @override
  String get uiNovember => 'ноября';

  @override
  String get uiDecember => 'декабря';

  @override
  String get uiNews => 'Новости';

  @override
  String get uiCouldNotLoadNews => 'Не удалось загрузить новости';

  @override
  String get uiNoNewsYet => 'Пока нет новостей';

  @override
  String get uiCheckBackALittleLater => 'Загляните сюда чуть позже.';

  @override
  String get uiUnioNews => 'UNIO · Новости';

  @override
  String get uiOnCampus => 'В университете';

  @override
  String get uiUniversityEventsAndAnnouncements =>
      'События и объявления университета';

  @override
  String get uiNoDate => 'Без даты';

  @override
  String get uiToday => 'Сегодня';

  @override
  String get uiYesterday => 'Вчера';

  @override
  String get uiLatest => 'ПОСЛЕДНЕЕ';

  @override
  String get uiOpenTheFullArticleToReadThisStory =>
      'Открой полную статью, чтобы прочитать новость.';

  @override
  String get uiVgspuNews => 'Новости ВГСПУ';

  @override
  String get uiCloseStory => 'Закрыть новость';

  @override
  String get uiReadFullArticle => 'Читать полностью';

  @override
  String uiEnterYourPortalUsernameAndPassword(String p0) {
    return 'Введите логин и пароль от портала $p0';
  }

  @override
  String uiSignInViaThePortal(String p0) {
    return 'Вход через портал $p0';
  }

  @override
  String get uiUseYourUniversityPortalUsernameAndPassword =>
      'Используй логин и пароль от портала университета.';

  @override
  String get uiPortalUsername => 'Логин от портала';

  @override
  String get uiPortalPassword => 'Пароль от портала';

  @override
  String get uiSignIn => 'Войти';

  @override
  String get uiYourPasswordIsNotSavedInTheBrowser =>
      'Пароль не сохраняется в браузере. Вход остаётся активным после закрытия UNIO.';

  @override
  String get uiYourUsernameAndPasswordAreStoredEncryptedOn =>
      'Логин и пароль хранятся зашифрованно на устройстве.';

  @override
  String get uiPortalTemporarilyUnavailable => 'Портал пока недоступен';

  @override
  String get uiCheckYourVgspuPortalAccount => 'Проверьте личный кабинет ВГСПУ';

  @override
  String get uiCouldNotLoadApplications => 'Не удалось загрузить заявления';

  @override
  String uiApplicationStatusEditingIsCurrentlyUnavailable(String p0) {
    return 'Статус заявления: $p0. Заполнение сейчас недоступно.';
  }

  @override
  String get uiApplicationCreatedThePortalIsPreparingTheForm =>
      'Заявление создано. Подождите немного — портал готовит форму. Обновите список чуть позже.';

  @override
  String get uiCertificatesAndApplications => 'Справки и заявления';

  @override
  String get uiRefreshStatuses => 'Обновить статусы';

  @override
  String get uiCreatingApplication => 'Создаём заявление…';

  @override
  String get uiSubmitAnApplication => 'Подать заявление';

  @override
  String get uiMyApplications => 'Мои заявления';

  @override
  String uiCheckedAtPullDownToRefresh(String p0) {
    return 'Проверено в $p0 · потяните вниз, чтобы обновить';
  }

  @override
  String uiCouldNotRefreshStatusesShowingPreviousData(String p0) {
    return 'Не удалось обновить статусы. Показаны предыдущие данные.\n$p0';
  }

  @override
  String get uiNoApplicationsYet => 'Заявлений пока нет';

  @override
  String get uiChooseTheDocumentYouNeedUsingTheButton =>
      'Выберите нужный документ кнопкой ниже.';

  @override
  String get uiNewApplication => 'Новое заявление';

  @override
  String get uiWhichDocumentDoYouNeed => 'Какой документ нужен?';

  @override
  String get uiChooseACategoryAndApplicationTypeFromThe =>
      'Выберите категорию и вид заявления из списка университета.';

  @override
  String get uiCategory => 'Категория';

  @override
  String get uiRetryLoading => 'Повторить загрузку';

  @override
  String get uiNoApplicationsAvailableInThisCategory =>
      'В этой категории нет доступных заявлений.';

  @override
  String get uiApplicationType => 'Вид заявления';

  @override
  String get uiCreateApplication => 'Создать заявление';

  @override
  String get uiADraftWillBeCreatedOnThePortal =>
      'На портале будет создан черновик. На обработку вы отправите его после проверки данных.';

  @override
  String get uiComingSoon => 'Скоро здесь';

  @override
  String get uiThisSectionIsStillBeingDeveloped => 'Раздел ещё дорабатывается.';

  @override
  String get uiCouldNotOpenTheBrowser => 'Не удалось открыть браузер.';

  @override
  String get uiTemplateSavedFillItOutInADocument =>
      'Шаблон сохранён. Заполните его в редакторе документов и прикрепите к заявлению.';

  @override
  String get uiCouldNotSaveTheTemplateTryAgainAnd =>
      'Не удалось сохранить шаблон. Попробуйте ещё раз и выберите доступную папку.';

  @override
  String get uiApplication => 'Заявление';

  @override
  String get uiChooseAFileInOneOfTheListed =>
      'Выберите файл в одном из указанных форматов.';

  @override
  String get uiChooseAFileUpToMb => 'Выберите файл размером до 20 МБ.';

  @override
  String get uiTheSelectedFileIsEmpty => 'Выбран пустой файл.';

  @override
  String get uiCouldNotReadTheFilePleaseSelectIt =>
      'Не удалось прочитать файл. Попробуйте выбрать его ещё раз.';

  @override
  String get uiAttachYourApplication => 'Прикрепите заявление';

  @override
  String get uiFileAlreadyUploadedToThePortal => 'Файл уже загружен на портал';

  @override
  String get uiAttachADocumentConfirmingYourSelectedCategory =>
      'Прикрепите документ, подтверждающий выбранную категорию.';

  @override
  String get uiFillOutTheTemplateAndAttachYourApplication =>
      'Заполните шаблон и прикрепите файл заявления.';

  @override
  String uiUpToMb(String p0) {
    return '$p0 · до 20 МБ';
  }

  @override
  String get uiChooseFile => 'Выбрать файл';

  @override
  String get uiReplaceFile => 'Заменить файл';

  @override
  String get uiTheFileWillBeUploadedWhenYouSubmit =>
      'Файл будет загружен на портал при отправке заявления.';

  @override
  String get uiRemoveSelectedFile => 'Убрать выбранный файл';

  @override
  String get uiSubmitApplication => 'Отправить заявление?';

  @override
  String get uiCheckYourDetailsAndAttachmentsYourApplicationWill =>
      'Проверьте заполненные данные и вложения. Заявление поступит на обработку в университет.';

  @override
  String get uiReviewAgain => 'Проверить ещё раз';

  @override
  String get uiSubmit => 'Отправить';

  @override
  String get uiSubmissionCouldNotBeConfirmedCheckTheApplication =>
      'Не удалось подтвердить отправку. Проверьте статус в списке заявлений перед повторной попыткой — портал мог уже получить данные.';

  @override
  String get uiEmailAddress => 'Электронная почта';

  @override
  String get uiPostalAddress => 'Почтовый адрес';

  @override
  String get uiStartOfPeriod => 'Начало периода';

  @override
  String get uiEndOfPeriod => 'Конец периода';

  @override
  String get uiNumberOfCopies => 'Количество справок';

  @override
  String get uiDdMmYyyy => 'ДД.ММ.ГГГГ';

  @override
  String get uiChooseDate => 'Выбрать дату';

  @override
  String get uiPleaseConfirmYourConsent => 'Подтвердите согласие';

  @override
  String uiApplication160(String p0) {
    return 'Заявление №$p0';
  }

  @override
  String get uiFormNotAvailableYet => 'Форма пока недоступна';

  @override
  String get uiCouldNotOpenApplication => 'Не удалось открыть заявление';

  @override
  String get uiBackToApplications => 'К списку заявлений';

  @override
  String get uiFillInYourDetails => 'Заполните данные';

  @override
  String get uiApplicationOnThePortal => 'Заявление на портале';

  @override
  String get uiFieldsMarkedWithAnAsteriskAreRequiredYou =>
      'Поля со звёздочкой обязательны. Перед отправкой вы сможете проверить данные.';

  @override
  String get uiThisApplicationCannotBeEditedItsCurrentStatus =>
      'Редактирование этой заявки недоступно. Актуальный статус указан в списке заявлений.';

  @override
  String get uiSaving168 => 'Сохранение…';

  @override
  String get uiDownloadWordTemplate => 'Скачать шаблон Word';

  @override
  String get uiOpenTemplateOnThePortal => 'Открыть шаблон на портале';

  @override
  String get uiSomeAttachmentsOrFieldsInThisFormAre =>
      'Эта форма содержит вложения или поля, которые пока доступны только на портале. Продолжите заполнение в браузере.';

  @override
  String get uiSubmitForProcessing => 'Отправить на обработку';

  @override
  String get uiCheckApplicationStatus => 'Проверить статус заявления';

  @override
  String get uiOpenOnTheVgspuPortal => 'Открыть на портале ВГСПУ';

  @override
  String get uiClassPhotosRecoveredAndSaved =>
      'Фотографии к паре восстановлены и сохранены';

  @override
  String get uiCouldNotRecoverTheSelectedPhotosOpenThe =>
      'Не удалось восстановить выбранные фото. Откройте заметку и добавьте их ещё раз.';

  @override
  String get uiNextWeek => 'Следующая неделя';

  @override
  String get uiThisWeek => 'Эта неделя';

  @override
  String get uiCouldNotLoadSchedule => 'Не удалось загрузить расписание';

  @override
  String get uiCheckYourInternetConnectionAndTryAgain =>
      'Проверьте подключение к интернету и попробуйте ещё раз';

  @override
  String get uiNoScheduleFoundForThisWeek =>
      'На выбранную неделю расписание не найдено';

  @override
  String get uiEndGuestSession => 'Завершить гостевой сеанс';

  @override
  String get uiSignOut => 'Выйти из аккаунта';

  @override
  String get uiYouWillNeedToChooseAGroupAgain =>
      'Для нового гостевого сеанса потребуется снова выбрать группу.';

  @override
  String get uiYouWillNeedToSignInAgainTo =>
      'Для доступа к аккаунту потребуется войти снова.';

  @override
  String get uiEndSession => 'Завершить';

  @override
  String get uiSignOut187 => 'Выйти';

  @override
  String get uiAccountAndAppPreferences => 'Аккаунт и параметры приложения';

  @override
  String get uiTeacher => 'Преподаватель';

  @override
  String get uiPersonalAccount => 'Личный аккаунт';

  @override
  String uiGroup(String p0) {
    return 'Группа $p0';
  }

  @override
  String uiPortal(String p0) {
    return 'Портал $p0';
  }

  @override
  String get uiGuestAccess => 'Гостевой доступ';

  @override
  String uiScheduleForGroup(String p0) {
    return 'Расписание группы $p0';
  }

  @override
  String get uiChangeGroup => 'Сменить группу';

  @override
  String get uiSignInToThePortalAgain => 'Повторить вход через портал';

  @override
  String uiSignInViaThePortal198(String p0) {
    return 'Войти через портал $p0';
  }

  @override
  String get uiPreferences => 'Параметры';

  @override
  String get uiDarkTheme => 'Тёмная тема';

  @override
  String get uiPushNotifications => 'Пуш-уведомления';

  @override
  String get uiNotificationsAreCurrentlyUnavailableOnIphoneAddUnio =>
      'Уведомления пока недоступны. На iPhone добавьте UNIO на главный экран.';

  @override
  String get uiScheduleWidget => 'Виджет расписания';

  @override
  String get uiYourNextClassOnTheHomeScreen =>
      'Ближайшая пара на рабочем столе';

  @override
  String get uiPrivacy => 'Конфиденциальность';

  @override
  String get uiConsentAnalyticsAndDeletion => 'Согласия, аналитика и удаление';

  @override
  String get uiInstallUnio => 'Установить UNIO';

  @override
  String get uiAddToHomeScreenWebBeta => 'На главный экран · веб-бета';

  @override
  String get uiNotesAreStoredInThisBrowserClearingSite =>
      'Заметки хранятся в этом браузере. Очистка данных сайта удаляет их. Пароль портала в веб-версии не сохраняется.';

  @override
  String get uiSigningOut => 'Выход…';

  @override
  String uiUnioVersion(String p0) {
    return 'UNIO · Версия $p0';
  }

  @override
  String get uiCouldNotSignOutPleaseTryAgain =>
      'Не удалось выйти. Попробуйте ещё раз.';

  @override
  String get uiClass => 'Занятие';

  @override
  String get uiClassDetailsAndTeachingTools =>
      'Детали занятия и инструменты преподавателя.';

  @override
  String get uiRoomNotSpecified => 'Аудитория не указана';

  @override
  String uiRoom(String p0) {
    return 'Аудитория $p0';
  }

  @override
  String get uiFindAnAvailableRoom => 'Найти свободную аудиторию';

  @override
  String get uiBackToSchedule => 'К расписанию';

  @override
  String get uiAvailableRooms => 'Свободные аудитории';

  @override
  String get uiCouldNotFindRooms => 'Не удалось найти аудитории';

  @override
  String get uiForTeachers => 'Для преподавателя';

  @override
  String get uiARoomForYourClass => 'Место для пары';

  @override
  String get uiNoAvailableRoomsFoundInTheKnownSchedules =>
      'По известным расписаниям свободных аудиторий не найдено.';

  @override
  String uiRoom224(String p0) {
    return 'Ауд. $p0';
  }

  @override
  String get uiTodaySSchedule => 'Сегодня по расписанию';

  @override
  String get uiPartOfTheScheduleIsUnavailableShowingKnown =>
      'Часть расписания недоступна. Показаны известные занятия.';

  @override
  String uiNow(String p0, String p1) {
    return 'Сейчас · $p0–$p1';
  }

  @override
  String get uiCouldNotDetermineWhetherThereIsAClass =>
      'Не удалось определить, есть ли занятие сейчас.';

  @override
  String get uiNoClassesScheduledRightNow =>
      'Сейчас занятий по расписанию нет.';

  @override
  String uiNext(String p0) {
    return 'Следующая · $p0';
  }

  @override
  String get uiTimesForUpcomingClassesAreNotSpecified =>
      'Время следующих занятий не указано.';

  @override
  String get uiNoMoreClassesToday => 'Следующих занятий сегодня нет.';

  @override
  String get uiTheScheduleShowsPlannedClassesNotAPerson =>
      'Расписание показывает запланированные занятия, а не фактическое присутствие в вузе.';

  @override
  String get uiSavedDataNotConfirmedWithTheServer =>
      'Есть сохранённые данные · без актуального подтверждения с сервера';

  @override
  String get uiTodaySScheduleHasNotLoadedRefreshTo =>
      'Расписание на сегодня не загружено. Обновите экран, чтобы повторить.';

  @override
  String get uiRefreshSchedule => 'Обновить расписание';

  @override
  String get uiClassesAndRoomsFromTheUniversitySchedule =>
      'Занятия и аудитории по расписанию университета.';

  @override
  String get uiClassSchedule => 'Расписание занятий';

  @override
  String get uiPreviousDay => 'Предыдущий день';

  @override
  String uiToday240(String p0) {
    return 'Сегодня · $p0';
  }

  @override
  String get uiNextDay => 'Следующий день';

  @override
  String get uiBackToToday => 'Вернуться к сегодня';

  @override
  String get uiCouldNotLoadClasses => 'Не удалось загрузить занятия';

  @override
  String get uiTheScheduleHasNotLoadedCompletely =>
      'Расписание загружено не полностью.';

  @override
  String get uiShowingSavedSchedule => 'Показано сохранённое расписание.';

  @override
  String get uiNoKnownClassesForThisDayTheFull =>
      'Известных занятий на этот день нет. Полное расписание пока недоступно.';

  @override
  String get uiViewClassesAndRooms => 'Посмотреть занятия и аудитории';

  @override
  String get uiFindATeacher => 'Найти преподавателя';

  @override
  String get uiRefreshDirectory => 'Обновить справочник';

  @override
  String get uiSurnameOrPartOfAName => 'Фамилия или часть ФИО';

  @override
  String get uiClearSearch => 'Очистить поиск';

  @override
  String get uiSearchingTheSavedDirectory =>
      'Поиск по сохранённому справочнику';

  @override
  String get uiDirectoryCurrentlyUnavailable => 'Справочник пока недоступен';

  @override
  String get uiRecentlyViewed => 'Недавно смотрели';

  @override
  String get uiClear => 'Очистить';

  @override
  String get uiWhoAreYouLookingFor => 'Кого ищем?';

  @override
  String get uiEnterAtLeastTwoLettersOfASurname =>
      'Введите хотя бы две буквы фамилии. Полное ФИО знать не обязательно.';

  @override
  String get uiNoMatches => 'Совпадений нет';

  @override
  String get uiCheckTheSurnameOrTryFewerLetters =>
      'Проверьте фамилию или попробуйте ввести меньше букв.';

  @override
  String get uiChooseATeacher => 'Выберите преподавателя';

  @override
  String get uiMoreMatchesAvailableRefineTheSurname =>
      'Есть ещё совпадения — уточните фамилию.';

  @override
  String get uiUniversityEventsAnnouncementsAndCampusLife =>
      'События, объявления и жизнь университета';

  @override
  String get uiCertificatesFormsAndPortalResponses =>
      'Справки, формы и ответы портала';

  @override
  String get uiTeachers => 'Преподаватели';

  @override
  String get uiSearchBySurnameClassesAndRooms =>
      'Поиск по фамилии, занятия и аудитории';

  @override
  String get uiUnioUniversity => 'UNIO · Университет';

  @override
  String get uiForYourStudies => 'Всё для учёбы';

  @override
  String get uiNewsApplicationsAndTeacherSearchInOnePlace =>
      'Новости, заявления и поиск преподавателей — в одном месте.';

  @override
  String get uiApplications => 'Заявления';

  @override
  String get uiUseYourUniversityAccountYourApplicationsWillAppear =>
      'Используйте учётную запись университета. После входа откроется список заявлений.';

  @override
  String get uiBack => 'Назад';

  @override
  String get uiSkip => 'Пропустить';

  @override
  String uiPageOf(String p0, String p1) {
    return 'Страница $p0 из $p1';
  }

  @override
  String uiPage(String p0) {
    return 'Страница $p0';
  }

  @override
  String get uiGetStarted => 'Начать';

  @override
  String get uiNext276 => 'Дальше';

  @override
  String get uiLetSGetAcquainted => 'ДАВАЙ ЗНАКОМИТЬСЯ';

  @override
  String get uiChooseYourRole => 'Выбери\nсвою роль';

  @override
  String get uiStudentsAndTeachersHaveAccessToDifferentSections =>
      'Для студентов и преподавателей доступны разные разделы.';

  @override
  String get uiDoYouStudyOrTeach => 'Ты учишься или преподаёшь?';

  @override
  String get uiIMAStudent => 'Я студент';

  @override
  String get uiClassesGradesAndApplications => 'Пары, зачётка и заявления';

  @override
  String get uiIMATeacher => 'Я преподаватель';

  @override
  String get uiScheduleAndAvailableRooms => 'Расписание и свободные аудитории';

  @override
  String get uiYouCanChangeYourRoleBySigningOut =>
      'Можно сменить роль, выйдя из аккаунта.';

  @override
  String get uiForStudents => 'СТУДЕНТАМ';

  @override
  String get uiHowWouldYouLikeToSignIn => 'Как хочешь\nвойти?';

  @override
  String get uiConnectYourPortalAccountOrStartWithYour =>
      'Подключи портал или начни с расписания своей группы.';

  @override
  String get uiWhatWorksForYou => 'Как тебе удобнее?';

  @override
  String get uiScheduleGradesAndApplications =>
      'Расписание, зачётка, заявления';

  @override
  String get uiContinueAsAGuest => 'Продолжить как гость';

  @override
  String get uiStartWithYourGroupCodeYouCanConnect =>
      'Начни с номера группы. Портал можно подключить позже.';

  @override
  String get uiWelcomeToUnio => 'ПРИВЕТ, ЭТО UNIO';

  @override
  String get uiHiThisIsUnio => 'Привет! Это UNIO.';

  @override
  String get uiAnAppForYourStudies => 'Приложение для учёбы.';

  @override
  String get uiViewYourScheduleSaveAssignmentsAndRequestCertificates =>
      'Здесь можно смотреть расписание, записывать задания и заказывать справки.';

  @override
  String get uiSchedule297 => 'РАСПИСАНИЕ';

  @override
  String get uiYourClassSchedule => 'Расписание занятий.';

  @override
  String get uiForTodayAndTheWeek => 'На сегодня и неделю.';

  @override
  String get uiChooseADayToViewClassesTimesAnd =>
      'Выбери день и посмотри пары, время и аудитории. Сохранённое расписание работает без интернета.';

  @override
  String get uiCertificatesAndApplications301 => 'СПРАВКИ И ЗАЯВЛЕНИЯ';

  @override
  String get uiNeedACertificate => 'Нужна справка?';

  @override
  String get uiRequestItInTheApp => 'Закажи в приложении.';

  @override
  String get uiRequestCertificatesViaThePortalTrackTheirStatus =>
      'Заказывай справки через портал, следи за статусом и получай уведомления о готовности.';

  @override
  String get uiMoreFeatures => 'ДРУГИЕ РАЗДЕЛЫ';

  @override
  String get uiNewsAndTeachers => 'Новости и преподаватели.';

  @override
  String get uiHomeworkAndNotes307 => 'Задания и заметки.';

  @override
  String get uiFindTeachersAndTheirClassesReadUniversityNews =>
      'Ищи преподавателей и их занятия, читай новости вуза и оставляй заметки к своим парам.';

  @override
  String get uiEnterYourFullNameCharacters =>
      'Введите ФИО (от 3 до 255 символов)';

  @override
  String get uiEnterYourVgspuPortalUsernameAndPassword =>
      'Введите логин и пароль от портала ВГСПУ';

  @override
  String get uiEnterYourGroupUsernameAndPassword =>
      'Заполните группу, логин и пароль';

  @override
  String get uiEnterYourGroupCode => 'Введите номер группы';

  @override
  String get uiCouldNotSignInCheckYourConnectionAnd =>
      'Не удалось войти. Проверьте соединение и попробуйте ещё раз.';

  @override
  String get uiForTeachers314 => 'ПРЕПОДАВАТЕЛЯМ';

  @override
  String get uiYourAccount => 'ЛИЧНЫЙ КАБИНЕТ';

  @override
  String get uiQuickStart => 'БЫСТРЫЙ СТАРТ';

  @override
  String get uiTeacherSchedule => 'Расписание\nпреподавателя';

  @override
  String get uiSignInViaThePortal318 => 'Вход\nчерез портал';

  @override
  String get uiChooseYourGroup => 'Укажи\nсвою группу';

  @override
  String get uiSignInWithYourVgspuPortalAccountYour =>
      'Войди с аккаунтом портала ВГСПУ. ФИО нужно, чтобы найти твоё расписание.';

  @override
  String uiUseYourPortalUsernameAndPassword(String p0) {
    return 'Используй свой логин и пароль от портала $p0.';
  }

  @override
  String get uiChooseAGroupAndPlanYourDayNo =>
      'Выбери группу — и можно планировать день. Пароль университета не нужен.';

  @override
  String get uiEnterYourGroupCodeAndPlanYourDay =>
      'Укажи номер группы — и можно планировать день. Подключить портал получится позже.';

  @override
  String get uiTeacherSignIn => 'Вход преподавателя';

  @override
  String get uiFullName => 'Фамилия, имя и отчество';

  @override
  String get uiShowPassword => 'Показать пароль';

  @override
  String get uiHidePassword => 'Скрыть пароль';

  @override
  String get uiYourUsernameAndPasswordAreStoredSecurelyOn =>
      'Логин и пароль сохраняются защищённо на этом устройстве.';

  @override
  String get uiNoPortalUsernameOrPasswordNeeded =>
      'Без логина и пароля от портала.';

  @override
  String get uiToday330 => 'СЕГОДНЯ';

  @override
  String get uiToday331 => '· Сегодня';

  @override
  String get uiNoClasses => 'Пар нет';

  @override
  String get uiNoClassesTakeABreak => 'Пар нет — можно выдохнуть';

  @override
  String get uiChooseAnotherDayToViewItsSchedule =>
      'Выберите другой день, чтобы посмотреть расписание.';

  @override
  String get uiGroupListCurrentlyUnavailable => 'Список групп пока недоступен';

  @override
  String get uiCouldNotCheckTheGroupListPleaseTry =>
      'Не удалось проверить список групп. Попробуйте ещё раз.';

  @override
  String get uiGroupCode => 'Номер группы';

  @override
  String get uiStartTypingAGroupCodeOrNumber => 'Начните вводить код или номер';

  @override
  String get uiLoadingGroups => 'Загружаем группы…';

  @override
  String uiTryAgain340(String p0) {
    return '$p0. Повторить';
  }

  @override
  String get uiGroupNotFoundCheckTheCodeOrEnter =>
      'Группа не найдена. Проверьте код или введите только номер.';

  @override
  String get uiHowToViewYourSchedule => 'Как смотреть\nрасписание';

  @override
  String get uiChooseADayOnTheScheduleTimesAre =>
      'Выбирай день в карточке расписания. Время — слева, рядом — предмет и аудитория. Нажми на пару, чтобы открыть её.';

  @override
  String get uiHowToSwitchWeeks => 'Как сменить\nнеделю';

  @override
  String get uiSwipeLeftForNextWeekAndRightFor =>
      'Свайп влево открывает следующую неделю, вправо — возвращает текущую. Кнопка над расписанием делает то же самое. Сохранённые пары доступны без сети.';

  @override
  String get uiHowToAddHomework => 'Как записать ДЗ';

  @override
  String get uiOpenAClassWriteDownHomeworkOrAn =>
      'Открой пару, запиши домашнее задание или важную мысль и нажми «Сохранить». Запись привязана к этому занятию.';

  @override
  String get uiHowToAddPhotos => 'Как добавить фото';

  @override
  String get uiScrollTheActionBarToAddPhotosFrom =>
      'Листай панель действий, чтобы добавить фото из галереи или с камеры. Заметки и фотографии хранятся на устройстве: удаление приложения удалит и их.';

  @override
  String get uiHowToRequestACertificate => 'Как заказать справку';

  @override
  String get uiOpenUniversitySubmitAnApplicationAndSignIn =>
      'Открой «Университет» → «Подать заявление» и войди через портал. Выбери документ. Пока статус «Новое», портал ещё готовит форму.';

  @override
  String get uiFillingOutAnApplication => 'Заполнение заявления';

  @override
  String get uiWhenOpenFormAppearsOpenTheApplicationAfter =>
      'Когда появится «Перейти к заполнению», открой форму. После отправки проверяй статус здесь. Пуш-уведомления можно включить в настройках; проверка бывает с задержкой.';

  @override
  String get uiRooms => 'Аудитории';

  @override
  String get uiFindARoom => 'Поиск аудитории';

  @override
  String get uiOpenAClassAndSelectFindAnAvailable =>
      'Открой занятие и выбери «Найти свободную аудиторию» в панели действий. Поиск использует дату и время этой пары.';

  @override
  String get uiWhatTheSearchShows => 'Что показывает поиск';

  @override
  String get uiUnioOnlyChecksTheSchedulesItKnowsA =>
      'UNIO проверяет только известные ему расписания. Найденная аудитория не забронирована: перед занятием уточни, свободна ли она на самом деле.';

  @override
  String get uiTeacherSearch => 'Поиск преподавателя';

  @override
  String get uiOpenTeachersInTheUniversityTabEnterAt =>
      'Во вкладке «Университет» открой «Преподаватели». Введи хотя бы две буквы фамилии и выбери нужное полное имя.';

  @override
  String get uiClassesAndRooms => 'Занятия и аудитории';

  @override
  String get uiATeacherSCardShowsClassesAndRooms =>
      'В карточке преподавателя есть занятия и аудитории. Это план, а не отслеживание человека: расписание не подтверждает его присутствие в вузе.';

  @override
  String get uiGettingStarted => 'Первое знакомство';

  @override
  String get uiCloseGuide => 'Закрыть гайд';

  @override
  String get uiAppGuide => 'ГАЙД ПО ПРИЛОЖЕНИЮ';

  @override
  String get uiGotIt => 'Понятно';

  @override
  String uiExample(String p0) {
    return 'ПРИМЕР · $p0';
  }

  @override
  String get uiMon => 'ПН';

  @override
  String get uiTue => 'ВТ';

  @override
  String get uiWed => 'СР';

  @override
  String get uiThu => 'ЧТ';

  @override
  String get uiFri => 'ПТ';

  @override
  String get uiForeignLanguage => '10:10 · Иностранный язык';

  @override
  String get uiRoom374 => 'Аудитория 314';

  @override
  String get uiPedagogy => '11:50 · Педагогика';

  @override
  String get uiRoom376 => 'Аудитория 208';

  @override
  String get uiSwipeLeft => 'Свайп влево';

  @override
  String get uiReadChapter => 'Прочитать главу 3';

  @override
  String get uiAssignmentForTheNextClass => 'Задание к следующей паре';

  @override
  String get uiNew => 'Новое';

  @override
  String get uiThePortalIsPreparingTheForm => 'Портал готовит форму';

  @override
  String get uiOpenForm => 'Перейти к заполнению';

  @override
  String get uiYouCanOpenTheApplication => 'Можно открыть заявление';

  @override
  String get uiUniversityResponse => 'Ответ университета';

  @override
  String get uiTheStatusWillAppearInTheList => 'Статус появится в списке';

  @override
  String get uiSelectedClassTime => 'Время выбранного занятия';

  @override
  String get uiBasedOnKnownSchedules => 'По известным расписаниям';

  @override
  String get uiSearchBySurname => 'Поиск по фамилии';

  @override
  String get uiChooseTheFullName => 'Выбери полное имя';

  @override
  String get uiTeacherDetails => 'Карточка преподавателя';

  @override
  String get uiTodayAndOtherDays => 'Сегодня и другие дни';

  @override
  String get uiRoomAndTime => 'Аудитория и время';

  @override
  String get uiFromTheClassSchedule => 'По плану занятий';

  @override
  String get uiConfirmInTheAndroidDialogTheWidgetWill =>
      'Подтверди добавление в окне Android. Виджет появится на рабочем столе.';

  @override
  String get uiTouchAndHoldAnEmptyAreaOnYour =>
      'Зажми пустое место на рабочем столе → «Виджеты» → UNIO.';

  @override
  String get uiYourScheduleAtHand => 'Расписание под рукой';

  @override
  String get uiYourNextClassAndRoomRightOnYour =>
      'Ближайшая пара и аудитория — прямо на рабочем столе.';

  @override
  String get uiNextClassToday => 'СЛЕДУЮЩАЯ ПАРА · СЕГОДНЯ';

  @override
  String get uiForeignLanguage399 => 'Иностранный язык';

  @override
  String get uiPracticalRoom => 'Практика · Ауд. 0439';

  @override
  String get uiYourDayYourPace => 'Твой день — в твоём ритме';

  @override
  String get uiDesignPreviewTheWidgetWillShowYourSelected =>
      'Пример оформления. Виджет покажет выбранное расписание и будет открывать UNIO по нажатию.';

  @override
  String get uiAddToHomeScreen => 'Добавить на рабочий стол';

  @override
  String uiRoom404(String p0) {
    return '  •  Ауд. $p0';
  }

  @override
  String uiGroup405(String p0) {
    return 'Группа: $p0';
  }

  @override
  String get uiLoadingTodaySClasses => 'Загружаем пары на сегодня…';

  @override
  String get uiTodaySScheduleHasNotLoaded =>
      'Расписание на сегодня не загружено';

  @override
  String get uiTapToTryAgain => 'Нажмите, чтобы повторить';

  @override
  String get uiNoScheduleFoundForThisWeek409 =>
      'Расписание на эту неделю не найдено';

  @override
  String get uiTapToRefresh => 'Нажмите, чтобы обновить';

  @override
  String get uiTimesForUpcomingClassesAreNotSpecified411 =>
      'Время следующих пар не указано';

  @override
  String get uiNoMoreClassesToday412 => 'Следующих пар сегодня нет';

  @override
  String get uiNoClassesTodayEnjoyYourBreak => 'Сегодня без пар — отдыхай ☕';

  @override
  String uiNextClassTodayGoToThisClassIn(
      String p0, String p1, String p2, String p3) {
    return 'Следующая пара сегодня: $p0, $p1–$p2$p3. Перейти к паре в расписании.';
  }

  @override
  String get uiNextClassToday415 => 'Следующая пара · сегодня';

  @override
  String get uiStartsIn => 'До начала';

  @override
  String get uiYourDay => 'Твой день';

  @override
  String get uiTheScheduleForOtherDaysIsBelow =>
      'Расписание на другие дни — ниже.';

  @override
  String get uiClassPhotos => 'Фото к паре';

  @override
  String get uiPreviousPhoto => 'Предыдущее фото';

  @override
  String get uiNextPhoto => 'Следующее фото';

  @override
  String get uiCouldNotOpenPhoto => 'Не удалось открыть фотографию';

  @override
  String uiPhoto(String p0) {
    return 'Фото $p0';
  }

  @override
  String get uiRemovePhoto => 'Убрать фото';

  @override
  String get uiUniversityServices => 'Сервисы университета';

  @override
  String uiViaThePortalRightInUnio(String p0, String p1) {
    return '$p0 через портал $p1 — прямо в UNIO.';
  }

  @override
  String get uiPortalSignInRequired => 'Нужен вход через портал';

  @override
  String get uiUseYourUniversityAccountToOpenThisSection =>
      'Используйте учётную запись университета, чтобы открыть этот раздел.';

  @override
  String uiAvailableAfterSigningInViaThePortalGuest(String p0) {
    return 'Доступно после входа через портал $p0 — в гостевом режиме доступно только расписание';
  }

  @override
  String get uiUnioOnYourHomeScreen => 'UNIO на главном экране';

  @override
  String get uiOnIphoneOpenUnioInSafariTapShare =>
      'На iPhone: откройте UNIO в Safari, нажмите «Поделиться» → «На экран Домой». Если есть переключатель «Открывать как веб-приложение», включите его.\n\nНа Android и компьютере: откройте меню браузера и выберите «Установить приложение» или «Добавить на главный экран».\n\nПосле первой загрузки доступны сохранённые расписания и заметки. Для новых данных нужен интернет. Очистка данных сайта удаляет локальные заметки и вход.';

  @override
  String get uiThePortalIsPreparingYourForm =>
      'Портал готовит форму для заполнения';

  @override
  String get uiSubjects => 'Предметы';

  @override
  String uiSemester445(String p0) {
    return 'Семестр $p0';
  }

  @override
  String get uiNoResultYet => 'Результат пока не указан';

  @override
  String uiPts(String p0) {
    return '$p0 б.';
  }

  @override
  String get uiCheckpointsAndAbsences => 'Срезы и пропуски';

  @override
  String uiCheckpoint(String p0) {
    return '$p0 срез';
  }

  @override
  String uiMissedH(String p0) {
    return 'Пропуски: $p0 ч.';
  }

  @override
  String get uiLoading => 'Загрузка';

  @override
  String get uiRefreshing => 'Обновление';

  @override
  String get uiSat => 'СБ';

  @override
  String get uiSun => 'ВС';

  @override
  String get uiPullDownToRefreshTheSchedule =>
      'Потяните вниз, чтобы обновить расписание.';

  @override
  String get uiClassesForTheWeek => 'Пары на неделю';

  @override
  String get uiAlwaysNearby => 'Всегда рядом';

  @override
  String get uiForYourStudies470 => 'Для учёбы';

  @override
  String get uiYourDay471 => 'ТВОЙ ДЕНЬ';

  @override
  String get uiPedagogy472 => 'Педагогика';

  @override
  String get uiEvenOffline => 'Даже без сети';

  @override
  String get uiEnrolmentCertificate => 'Справка об обучении';

  @override
  String get uiApplicationSubmitted => 'Заявление отправлено';

  @override
  String get uiSubmittedInProgressReady => 'Отправлено → В работе → Готово';

  @override
  String get uiCertificateReady => 'Справка готова';

  @override
  String get uiReadyToCollect => 'Можно забирать';

  @override
  String get uiTeacherClassSchedule => 'Преподаватель\nРасписание занятий';

  @override
  String get uiNextClassRoom => 'Следующая пара · ауд. 314';

  @override
  String get uiEssentialsAtHand => 'Важное — под рукой';

  @override
  String get uiClassNotes => 'Заметки к занятиям';

  @override
  String get uiTheServerHasConfirmedDeletionAndSignOut =>
      'Запросы удаления и выхода подтверждены сервером.';

  @override
  String get uiTheServerRequestIsStillWaitingForA =>
      'Запрос к серверу ещё ожидает сети. Не удаляйте приложение до подтверждения.';

  @override
  String get uiPleaseAcceptTheDocumentsToSignInAnalytics =>
      'Для входа нужно принять документы. Аналитика необязательна.';

  @override
  String get uiCleanupIsIncompleteWeWillRetryOnThe =>
      'Очистка не завершена. Повторим при следующем запуске. Не удаляйте приложение до подтверждения.';

  @override
  String get uiYouAreSignedOutTheServerRequestIs =>
      'Вы вышли. Запрос на сервер ожидает сети — откройте приложение с интернетом.';

  @override
  String get uiYourUnioAccountAndLocalDataHaveBeen =>
      'Аккаунт UNIO и локальные данные удалены.';

  @override
  String get uiYouHaveSignedOut => 'Вы вышли из аккаунта.';

  @override
  String get uiMonday => 'Понедельник';

  @override
  String get uiTuesday => 'Вторник';

  @override
  String get uiWednesday => 'Среда';

  @override
  String get uiThursday => 'Четверг';

  @override
  String get uiFriday => 'Пятница';

  @override
  String get uiSaturday => 'Суббота';

  @override
  String get uiSunday => 'Воскресенье';

  @override
  String get uiClass497 => 'пара';

  @override
  String get uiClasses => 'пары';

  @override
  String get uiClasses499 => 'пар';

  @override
  String get uiCouldNotConnectCheckYourInternetConnectionAnd =>
      'Не удалось подключиться. Проверьте интернет и попробуйте ещё раз.';

  @override
  String get uiTheServiceIsTemporarilyUnavailablePleaseTryAgain =>
      'Сервис временно недоступен. Попробуйте чуть позже.';

  @override
  String get uiCouldNotCompleteThisActionPleaseTryAgain =>
      'Не удалось выполнить действие. Попробуйте ещё раз.';

  @override
  String get uiSignInAgainAndRetryThisAction =>
      'Войдите в аккаунт заново и повторите действие.';

  @override
  String get uiThisActionIsCurrentlyUnavailableForYourAccount =>
      'Это действие сейчас недоступно для вашего аккаунта.';

  @override
  String get uiCouldNotFindTheRequestedDataTryRefreshing =>
      'Не удалось найти запрошенные данные. Попробуйте обновить экран.';

  @override
  String get uiCheckYourDetailsAndTryAgain =>
      'Проверьте заполненные данные и попробуйте ещё раз.';

  @override
  String get uiTheResponseIsTakingLongerThanExpectedPlease =>
      'Ответ задерживается. Попробуйте ещё раз чуть позже.';

  @override
  String get uiTooManyAttemptsPleaseWaitALittleAnd =>
      'Слишком много попыток. Подождите немного и повторите.';

  @override
  String get uiThePortalHasRestrictedAccessTryAnotherNetwork =>
      'Портал ограничил доступ. Попробуйте другую сеть или откройте портал в браузере. Код REQ_ACCESS.';

  @override
  String get uiCouldNotLoadTheListTryRefreshingIt =>
      'Не удалось загрузить список. Попробуйте обновить его позже. Код REQ_EMPTY.';

  @override
  String get uiOpenYourVgspuPortalAccountAnActionMay =>
      'Откройте личный кабинет ВГСПУ: возможно, там требуется действие. Если раздел заявлений доступен, сообщите поддержке код REQ_PAGE.';

  @override
  String get uiCouldNotOpenThePageSecurelyPleaseTry =>
      'Не удалось безопасно открыть страницу. Попробуйте позже.';

  @override
  String get storyViewed => 'Просмотрено';

  @override
  String get open => 'Открыть';

  @override
  String get draft => 'Проект';

  @override
  String get accepted => 'Принято';

  @override
  String get withdrawn => 'Отозвано';

  @override
  String get waitingForForm =>
      'Подождите ещё немного — получаем информацию от портала. Когда форма будет готова, появится «Перейти к заполнению». Обновите список чуть позже.';

  @override
  String get noStatus => 'Статус не указан';

  @override
  String get lecture => 'Лекция';

  @override
  String get practice => 'Практика';

  @override
  String get lab => 'Лабораторная';

  @override
  String get seminar => 'Семинар';

  @override
  String get consultation => 'Консультация';

  @override
  String get exam => 'Экзамен';

  @override
  String get credit => 'Зачёт';

  @override
  String get documentsOriginalLanguage =>
      'Документы опубликованы на русском языке. Выбор языка интерфейса не меняет их текст.';

  @override
  String get notesSignIn =>
      'Войдите в студенческий аккаунт, чтобы открыть заметки.';

  @override
  String get notesNoDate => 'У этой пары не указана дата. Обновите расписание.';

  @override
  String get notesWrongOwner => 'Заметка относится к другому аккаунту.';

  @override
  String get notesReadFailed => 'Не удалось прочитать сохранённую заметку.';

  @override
  String get notesPhotosFailed => 'Не удалось прочитать фотографии заметки.';

  @override
  String get photoTooLarge =>
      'Фото слишком большое. Выберите изображение до 10 МБ.';

  @override
  String get photoAddFailed =>
      'Не удалось добавить фото. Максимальный размер — 10 МБ.';

  @override
  String get notesTextLimit => 'Можно сохранить до 20 000 символов.';

  @override
  String get photoReadFailed => 'Не удалось прочитать фотографию.';

  @override
  String get photoUnavailable => 'Фотография недоступна. Добавьте её ещё раз.';

  @override
  String get photosRecoveryFailed =>
      'Не удалось восстановить выбранные фото. Добавьте их ещё раз.';

  @override
  String get portalCheckCredentials =>
      'Проверьте логин и пароль портала ВГСПУ.';

  @override
  String get portalReauthenticate =>
      'Портал ВГСПУ завершил авторизацию. Повторите вход через портал в настройках UNIO.';

  @override
  String get webSignInEnded =>
      'Вход в веб-версию завершён. Войдите через портал повторно.';

  @override
  String get webConfigMissing =>
      'Веб-доступ к порталу ещё не настроен. Сообщите поддержке код WEB_CONFIG.';

  @override
  String get attachmentLimit => 'Выберите вложение размером до 20 МБ.';

  @override
  String get chooseSuggestedGroup => 'Выберите группу из подсказок.';

  @override
  String get tooManyRequests =>
      'Слишком много запросов. Попробуйте немного позже.';

  @override
  String get portalConnectionFailed =>
      'Не удалось связаться с порталом. Попробуйте ещё раз.';

  @override
  String get checkInternet => 'Не удалось подключиться. Проверьте интернет.';

  @override
  String get refreshSignInFailed =>
      'Не удалось обновить вход. Повторите действие.';

  @override
  String get portalOtherSite => 'Портал предложил переход на другой сайт.';

  @override
  String get portalNoRedirect => 'Портал не вернул адрес перехода.';

  @override
  String get portalUploadRedirect =>
      'Портал перенаправил загрузку файла. Обновите заявление и проверьте вложение.';

  @override
  String get portalTooManyRedirects => 'Слишком много перенаправлений портала.';

  @override
  String get operationSignIn => 'Вход в портал';

  @override
  String get operationDraft => 'Создание черновика';

  @override
  String get operationTypes => 'Загрузка видов заявлений';

  @override
  String get operationRequests => 'Загрузка списка заявлений';

  @override
  String get operationSubmit => 'Отправка заявления';

  @override
  String get operationForm => 'Открытие формы';

  @override
  String get operationPortal => 'Загрузка страницы портала';

  @override
  String get portalCsrfRejected => 'портал не принял защитный токен формы';

  @override
  String get portalNeedsSignIn => 'портал требует повторного входа';

  @override
  String get portalDenied => 'портал отказал в доступе';

  @override
  String get portalNoResponse => 'ответ не получен; проверьте соединение';

  @override
  String get portalError => 'портал вернул ошибку';

  @override
  String get portalSessionExpired =>
      'Сессия портала истекла. Войдите через портал заново.';

  @override
  String get portalSignInFailed =>
      'Не удалось войти в портал. Проверьте логин и пароль; возможно, портал требует дополнительного подтверждения.';

  @override
  String get portalSignInRequired =>
      'Войдите через портал ВГСПУ, чтобы продолжить.';

  @override
  String get tooManyRequestPages =>
      'Слишком много страниц заявлений. Откройте портал для полного списка.';

  @override
  String get typesNotReturned =>
      'Портал не вернул типы заявлений. Попробуйте войти заново.';

  @override
  String get typesLoadFailed => 'Не удалось загрузить типы заявлений.';

  @override
  String get invalidRequestId => 'Некорректный номер заявления.';

  @override
  String get formNotFillable =>
      'Заполнение сейчас недоступно. Вернитесь к списку и обновите статус заявления.';

  @override
  String get typeNoLongerAvailable =>
      'Этот тип заявления больше недоступен. Выберите другой.';

  @override
  String get draftNotConfirmed =>
      'Портал не подтвердил создание. Обновите список перед повторной попыткой.';

  @override
  String get fieldRequired => 'Заполните это поле';

  @override
  String get emailInvalid => 'Проверьте адрес электронной почты';

  @override
  String get dateInvalid => 'Укажите дату в формате ДД.ММ.ГГГГ';

  @override
  String get periodInvalid => 'Конец периода должен быть не раньше начала';

  @override
  String get positiveIntegerRequired => 'Укажите целое число больше нуля';

  @override
  String get formPortalOnly =>
      'Эту форму нельзя отправить из приложения. Откройте её на портале.';

  @override
  String get checkFields => 'Проверьте заполнение';

  @override
  String get checkAttachments => 'Проверьте вложения';

  @override
  String get fileRejected =>
      'Файл не принят порталом. Заявление не отправлено.';

  @override
  String get checkAttachmentFormat =>
      'Проверьте формат и размер вложения и повторите попытку.';

  @override
  String get portalCorrectForm => 'Портал просит исправить заявление';

  @override
  String get submissionPending =>
      'Запрос отправлен, но портал пока не подтвердил новый статус. Обновите список заявлений перед повторной отправкой.';

  @override
  String get groupNotInCatalog =>
      'Такой группы нет в каталоге. Выберите свою группу из подсказок.';

  @override
  String get groupCheckConnection =>
      'Не удалось проверить список групп. Проверьте соединение и попробуйте ещё раз.';

  @override
  String get groupNotInCatalogShort =>
      'Такой группы нет в каталоге. Выберите группу из подсказок.';

  @override
  String get groupCheckFailed =>
      'Не удалось проверить список групп. Попробуйте ещё раз.';

  @override
  String get signInIncomplete =>
      'Не удалось завершить вход. Попробуйте ещё раз.';

  @override
  String get fullNameRequired => 'Введите ФИО (от 3 до 255 символов)';

  @override
  String get credentialsRequired => 'Введите логин и пароль от портала ВГСПУ';

  @override
  String semanticRoomSuffix(String p0) {
    return ', аудитория $p0';
  }

  @override
  String checkNamedField(String p0) {
    return 'Проверьте поле «$p0».';
  }

  @override
  String invalidNamedFile(String p0) {
    return 'Недопустимый файл: $p0.';
  }

  @override
  String portalStatus(String p0) {
    return 'Статус на портале: $p0';
  }

  @override
  String get aiTitle => 'UNIO AI';

  @override
  String get aiSubtitle => 'Расписание и документы вуза';

  @override
  String get aiWelcome => 'Чем могу помочь?';

  @override
  String get aiIntro =>
      'Найду пары на нужный день и помогу разобраться в документах университета. Ответы по документам — со ссылками на источники.';

  @override
  String get aiTomorrow => 'Какое у меня завтра расписание?';

  @override
  String get aiScholarship => 'Как получить социальную стипендию?';

  @override
  String get aiDorm => 'Как заселиться в общежитие?';

  @override
  String get aiHint =>
      'Не отправляй пароли, документы и личные сведения. Диалог хранится только в памяти приложения до выхода из аккаунта или перезапуска.';

  @override
  String get aiInput => 'Сообщение…';

  @override
  String get aiSend => 'Отправить';

  @override
  String get aiClear => 'Очистить диалог и сбросить разрешение';

  @override
  String get aiThinking => 'Проверяю расписание и источники…';

  @override
  String get aiPrivacyTitle => 'Перед первым вопросом к документам';

  @override
  String get aiPrivacyBody =>
      'Для подготовки ответа UNIO передаст внешнему сервису ИИ текст вопроса, предыдущий вопрос при уточнении и фрагменты публичных материалов. Логин, пароль, токен аккаунта и успеваемость не передаются. Расписание, новости и оценки не требуют обращения к модели. Не вводи персональные данные. Разрешение действует до очистки диалога или выхода; уже переданный вопрос этим не удаляется у получателя.';

  @override
  String get aiAllow => 'Разрешить и отправить вопрос';

  @override
  String get aiNotNow => 'Не сейчас';

  @override
  String get aiOffTopic =>
      'Я помогаю с расписанием и документами университета. Спроси, например, о стипендии или общежитии.';

  @override
  String get aiSensitive =>
      'В вопросе могут быть личные данные или секретные значения. Удали их и задай вопрос в общем виде.';

  @override
  String get aiInsufficient =>
      'В проверенных документах пока недостаточно сведений. Уточни вопрос; если нужный документ ещё не добавлен, ответ лучше проверить в вузе.';

  @override
  String get aiNotConfigured =>
      'Помощник ещё подключается на сервере. Попробуй позже.';

  @override
  String get aiChooseDate =>
      'На какой день показать пары? Напиши «сегодня», «завтра», день недели или дату ГГГГ-ММ-ДД.';

  @override
  String get aiDateRange =>
      'Сейчас можно проверить расписание в пределах двух недель от сегодняшнего дня.';

  @override
  String get aiChooseGroup => 'Сначала выбери свою группу в расписании.';

  @override
  String get aiScheduleUnavailable =>
      'Сейчас расписание получить не удалось. Это не означает, что пар нет. Попробуй позже.';

  @override
  String get aiPermissionRequired =>
      'Для ответа по документам нужно разрешить передачу вопроса сервису ИИ. Отправь вопрос ещё раз.';

  @override
  String get aiAuthRequired =>
      'Сессия UNIO истекла. Войди в аккаунт заново, чтобы продолжить.';

  @override
  String get aiLimit => 'Достигнут лимит запросов помощника. Попробуй позже.';

  @override
  String get aiBusy =>
      'Помощник сейчас занят. Попробуй через несколько секунд.';

  @override
  String get aiUnavailable =>
      'Не удалось подготовить ответ. Проверь соединение и попробуй позже.';

  @override
  String get aiNoLessons => 'На этот день в расписании пар нет.';

  @override
  String get aiScheduleSource =>
      'Из сервиса расписания UNIO. Возможны изменения на портале.';

  @override
  String get aiSourceNotice =>
      'Проверь условия в оригинале. Ответ помощника не заменяет решение университета.';

  @override
  String get aiPage => 'Страница';

  @override
  String get aiOpenSource => 'Открыть оригинал';

  @override
  String get aiSearching => 'Ищу информацию…';

  @override
  String get aiWriting => 'Готовлю ответ…';

  @override
  String get aiLoadingSchedule => 'Проверяю расписание…';

  @override
  String get aiSources => 'Источники';

  @override
  String get aiFollowup => 'Какие документы нужны?';

  @override
  String get aiDayAfter => 'Расписание на послезавтра';

  @override
  String get aiNewsLatest => 'Вот последние публикации университета.';

  @override
  String aiNewsOnDate(String date) {
    return 'Новости за $date';
  }

  @override
  String get aiNewsEmpty =>
      'В сохранённых новостях нет публикаций за этот день. Можно посмотреть последнюю новость или выбрать другую дату.';

  @override
  String get aiNewsChooseDate =>
      'За какой день показать новости? Например: «новости за 21 октября 2026» или «новости за вчера».';

  @override
  String get aiNewsUnavailable =>
      'Не получилось загрузить новости. Попробуй ещё раз чуть позже.';

  @override
  String get aiAllNews => 'Все новости';

  @override
  String get aiReadNews => 'Читать полностью';

  @override
  String get aiRequestsHelp =>
      'Заказать справку или подать заявление можно на портале ВГСПУ или прямо в UNIO — в разделе «Справки и заявления». Для этого понадобится вход через портал.';

  @override
  String get aiOpenPortal => 'Открыть портал ВГСПУ';

  @override
  String get aiReferenceNotice =>
      'Информация носит справочный характер. ИИ может ошибаться — проверяй важные сведения по официальным источникам. Ответы не заменяют консультацию специалиста, в том числе медицинскую.';

  @override
  String get aiLoadingGrades => 'Проверяю успеваемость…';

  @override
  String get aiGradesFromPortal =>
      'Данные из раздела «Успеваемость». Баллы по срезам накопительные: складывать их не нужно.';

  @override
  String get aiOpenGrades => 'Открыть успеваемость';

  @override
  String get aiGradesAuthRequired =>
      'Успеваемость доступна после входа через портал ВГСПУ. Открой раздел и подключи свою учётную запись.';

  @override
  String get aiGradesUnavailable =>
      'Не получилось загрузить успеваемость. Попробуй позже или обнови данные в разделе «Успеваемость».';

  @override
  String get aiGradesEmpty =>
      'Портал пока не вернул данные об успеваемости. Это не означает, что у тебя нулевые баллы.';

  @override
  String get aiGradesNotFound =>
      'Не нашёл этот предмет или семестр в твоей успеваемости. Уточни название, например: «Что у меня по русскому языку за 2 семестр?»';

  @override
  String get aiHistory => 'История чатов';

  @override
  String get aiNewChat => 'Новый чат';

  @override
  String get aiHistorySearch => 'Поиск по перепискам';

  @override
  String get aiHistoryLocal => 'История сохраняется только на этом устройстве.';

  @override
  String get aiHistoryExternal =>
      'Вопросы к документам передаются внешнему ИИ-сервису после разрешения.';

  @override
  String get aiHistoryEmpty => 'Здесь появятся твои разговоры';

  @override
  String get aiHistoryNoResults => 'Переписки не найдены';

  @override
  String get aiRename => 'Переименовать';

  @override
  String get aiDeleteChat => 'Удалить чат';

  @override
  String get aiDeleteChatBody =>
      'Переписка и связанные карточки будут удалены с этого устройства.';

  @override
  String get aiDeleteHistory => 'Очистить всю историю';

  @override
  String get aiDeleteHistoryBody =>
      'Все переписки и черновики этого аккаунта будут удалены с устройства. Отменить это действие нельзя.';

  @override
  String get aiCancelAction => 'Отмена';

  @override
  String get aiDeleteAction => 'Удалить';

  @override
  String get aiSaveAction => 'Сохранить';

  @override
  String get aiTodayGroup => 'Сегодня';

  @override
  String get aiYesterdayGroup => 'Вчера';

  @override
  String get aiWeekGroup => 'Последние 7 дней';

  @override
  String get aiEarlierGroup => 'Ранее';

  @override
  String get aiUntitled => 'Новый разговор';

  @override
  String get aiCopy => 'Копировать';

  @override
  String get aiCopied => 'Ответ скопирован';

  @override
  String get aiRetry => 'Повторить';

  @override
  String get aiHelpful => 'Полезно';

  @override
  String get aiNotHelpful => 'Не помогло';

  @override
  String get aiStop => 'Остановить ответ';

  @override
  String get aiInterrupted =>
      'Ответ прерван. Полученные блоки сохранены; ответ может быть неполным.';

  @override
  String get aiNetworkError =>
      'Не удалось связаться с сервером. Проверь подключение и попробуй ещё раз.';

  @override
  String get aiHistoryFailure =>
      'Не удалось сохранить историю. Сообщения пока доступны только в текущем сеансе. Проверь свободное место и доступ к хранилищу.';

  @override
  String get aiHistoryRetry => 'Проверить сохранение';

  @override
  String get aiLoadOlder => 'Показать предыдущие сообщения';

  @override
  String get aiReturnSchedule => 'Вернуться к расписанию';

  @override
  String get aiSourceUnavailable => 'Официальная ссылка не указана';

  @override
  String get aiStarterGrades => 'Что у меня по успеваемости?';

  @override
  String get aiStarterRequests => 'Как заказать справку?';

  @override
  String get aiContactsFollowup => 'Куда обращаться?';

  @override
  String get aiEligibilityFollowup => 'Кто имеет право на получение?';

  @override
  String get aiNewsFollowup => 'Покажи последнюю новость';

  @override
  String get aiTomorrowFirst => 'Какая у меня завтра первая пара?';

  @override
  String get aiHistoryBrowser =>
      'В браузере история может исчезнуть после очистки данных сайта или выхода из приватного режима.';

  @override
  String get aiLegacy => 'Сообщение из другой версии приложения';

  @override
  String get aiOpenStatements => 'Открыть заявления';

  @override
  String get notificationPreferencesDescription =>
      'Напоминания о парах и готовности заявлений. Разрешение на показ задаётся в настройках устройства.';
}

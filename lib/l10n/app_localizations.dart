import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get language;

  /// No description provided for @languageSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить язык. Попробуйте ещё раз.'**
  String get languageSaveFailed;

  /// No description provided for @uiAcademicProgress.
  ///
  /// In ru, this message translates to:
  /// **'Успеваемость'**
  String get uiAcademicProgress;

  /// No description provided for @uiPointsGradesAndPassResultsOrganisedBySemester.
  ///
  /// In ru, this message translates to:
  /// **'Баллы, оценки и зачёты по семестрам — в одном месте.'**
  String get uiPointsGradesAndPassResultsOrganisedBySemester;

  /// No description provided for @uiSignInWithYourUniversityAccountToView.
  ///
  /// In ru, this message translates to:
  /// **'Войдите с учётной записью университета, чтобы увидеть свою успеваемость.'**
  String get uiSignInWithYourUniversityAccountToView;

  /// No description provided for @uiCouldNotLoadAcademicProgress.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить зачётку'**
  String get uiCouldNotLoadAcademicProgress;

  /// No description provided for @uiTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get uiTryAgain;

  /// No description provided for @uiCouldNotRetrieveAcademicProgress.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить зачётку'**
  String get uiCouldNotRetrieveAcademicProgress;

  /// No description provided for @uiNoDataYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет данных'**
  String get uiNoDataYet;

  /// No description provided for @uiPullDownToRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Потяните вниз, чтобы обновить.'**
  String get uiPullDownToRefresh;

  /// No description provided for @uiVgspuPortal.
  ///
  /// In ru, this message translates to:
  /// **'Портал ВГСПУ'**
  String get uiVgspuPortal;

  /// No description provided for @uiPointsAbsencesAndSubjectResults.
  ///
  /// In ru, this message translates to:
  /// **'Баллы, пропуски и результаты по предметам.'**
  String get uiPointsAbsencesAndSubjectResults;

  /// No description provided for @uiNoSemester.
  ///
  /// In ru, this message translates to:
  /// **'Без семестра'**
  String get uiNoSemester;

  /// No description provided for @uiSemester.
  ///
  /// In ru, this message translates to:
  /// **'{p0} семестр'**
  String uiSemester(String p0);

  /// No description provided for @uiEachCheckpointShowsCumulativePointsAndHoursMissed.
  ///
  /// In ru, this message translates to:
  /// **'В каждом срезе указаны накопленные баллы и пропущенные часы. Значения взяты с портала и не складываются между срезами.'**
  String get uiEachCheckpointShowsCumulativePointsAndHoursMissed;

  /// No description provided for @uiSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get uiSchedule;

  /// No description provided for @uiUniversity.
  ///
  /// In ru, this message translates to:
  /// **'Университет'**
  String get uiUniversity;

  /// No description provided for @uiSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get uiSettings;

  /// No description provided for @uiCouldNotReadTheDocumentsPleaseReopenThis.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать документы. Откройте экран ещё раз.'**
  String get uiCouldNotReadTheDocumentsPleaseReopenThis;

  /// No description provided for @uiYourChoiceHasBeenSaved.
  ///
  /// In ru, this message translates to:
  /// **'Выбор сохранён.'**
  String get uiYourChoiceHasBeenSaved;

  /// No description provided for @uiAnalyticsIsOffPreviouslySharedDataIsNot.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика отключена. Ранее переданные данные не удаляются автоматически: unio.support@gmail.com.'**
  String get uiAnalyticsIsOffPreviouslySharedDataIsNot;

  /// No description provided for @uiTheServerRecordWillBeSentAgainWhen.
  ///
  /// In ru, this message translates to:
  /// **'{p0} Серверная запись будет повторно отправлена при открытии приложения.'**
  String uiTheServerRecordWillBeSentAgainWhen(String p0);

  /// No description provided for @uiCouldNotCompleteTheChangePleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить изменение. Повторите действие.'**
  String get uiCouldNotCompleteTheChangePleaseTryAgain;

  /// No description provided for @uiCouldNotSaveYourChoicePleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить выбор. Попробуйте ещё раз.'**
  String get uiCouldNotSaveYourChoicePleaseTryAgain;

  /// No description provided for @uiDeleteAccountAndData.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт и данные?'**
  String get uiDeleteAccountAndData;

  /// No description provided for @uiThisDeletesYourUnioServerAccountLocalSign.
  ///
  /// In ru, this message translates to:
  /// **'Будут удалены аккаунт UNIO на сервере, локальные средства входа, заметки и их фотографии, кеши и история согласий. Обработка на основании согласия прекратится.\n\nПри отсутствии сети удаление на сервере останется в очереди. До подтверждения в защищённом хранилище останется только токен для выполнения запроса. Откройте приложение с интернетом до его удаления.\n\nДокументы в ВГСПУ, оригиналы фото, экспортированные файлы, резервные копии сервера и ранее отправленные данные MyTracker не удаляются этой кнопкой. Для обращения: unio.support@gmail.com.'**
  String get uiThisDeletesYourUnioServerAccountLocalSign;

  /// No description provided for @uiCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get uiCancel;

  /// No description provided for @uiDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get uiDelete;

  /// No description provided for @uiDocumentsAndData.
  ///
  /// In ru, this message translates to:
  /// **'Документы и данные'**
  String get uiDocumentsAndData;

  /// No description provided for @uiYourChoices.
  ///
  /// In ru, this message translates to:
  /// **'Ваш выбор'**
  String get uiYourChoices;

  /// No description provided for @uiDataManagement.
  ///
  /// In ru, this message translates to:
  /// **'Управление данными'**
  String get uiDataManagement;

  /// No description provided for @uiAnalyticsIsOptionalDecliningDoesNotLimitUnio.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика добровольна. Отказ от неё не ограничивает функции UNIO.'**
  String get uiAnalyticsIsOptionalDecliningDoesNotLimitUnio;

  /// No description provided for @uiIAcceptTheUserAgreement.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю пользовательское соглашение'**
  String get uiIAcceptTheUserAgreement;

  /// No description provided for @uiIConsentToUnioProcessingMyPersonalData.
  ///
  /// In ru, this message translates to:
  /// **'Даю согласие на обработку персональных данных UNIO'**
  String get uiIConsentToUnioProcessingMyPersonalData;

  /// No description provided for @uiSeparateConsentThePolicyAndFullTextAre.
  ///
  /// In ru, this message translates to:
  /// **'Отдельное согласие. Политика и полный текст доступны выше.'**
  String get uiSeparateConsentThePolicyAndFullTextAre;

  /// No description provided for @uiMytrackerIsNotUsedInTheWebApp.
  ///
  /// In ru, this message translates to:
  /// **'MyTracker в веб-версии не используется. Локальные данные хранятся в браузере; очистка данных сайта удалит заметки и вход. Перед очисткой дождитесь подтверждения удаления аккаунта на сервере.'**
  String get uiMytrackerIsNotUsedInTheWebApp;

  /// No description provided for @uiIGiveSeparateConsentToMytracker.
  ///
  /// In ru, this message translates to:
  /// **'Даю отдельное согласие на MyTracker'**
  String get uiIGiveSeparateConsentToMytracker;

  /// No description provided for @uiOptionalYouCanWithdrawConsentHereAtAny.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно. Можно отозвать здесь в любой момент.'**
  String get uiOptionalYouCanWithdrawConsentHereAtAny;

  /// No description provided for @uiSaving.
  ///
  /// In ru, this message translates to:
  /// **'Сохраняем…'**
  String get uiSaving;

  /// No description provided for @uiContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get uiContinue;

  /// No description provided for @uiSignOutWithoutAccepting.
  ///
  /// In ru, this message translates to:
  /// **'Выйти без принятия'**
  String get uiSignOutWithoutAccepting;

  /// No description provided for @uiWithdrawConsentAndDeleteData.
  ///
  /// In ru, this message translates to:
  /// **'Отозвать согласие и удалить данные'**
  String get uiWithdrawConsentAndDeleteData;

  /// No description provided for @uiNotesAreKeptUntilYouDeleteThemInactive.
  ///
  /// In ru, this message translates to:
  /// **'Заметки хранятся до удаления вами. Неактивные серверные аккаунты удаляются через 90 дней. Для запросов о данных: unio.support@gmail.com.'**
  String get uiNotesAreKeptUntilYouDeleteThemInactive;

  /// No description provided for @uiCouldNotOpenThisNoteOnYourDevice.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть заметку на устройстве. Попробуйте ещё раз.'**
  String get uiCouldNotOpenThisNoteOnYourDevice;

  /// No description provided for @uiCouldNotSaveTheNoteCheckAvailableStorage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить заметку. Проверьте свободное место и попробуйте ещё раз.'**
  String get uiCouldNotSaveTheNoteCheckAvailableStorage;

  /// No description provided for @uiSavedOnThisDevice.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено на устройстве'**
  String get uiSavedOnThisDevice;

  /// No description provided for @uiCouldNotReadThePhotoChooseAnotherImage.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать фото. Выберите другое изображение.'**
  String get uiCouldNotReadThePhotoChooseAnotherImage;

  /// No description provided for @uiCouldNotOpenPhotosCheckAppPermissionsAnd.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть фотографии. Проверьте разрешения приложения и попробуйте ещё раз.'**
  String get uiCouldNotOpenPhotosCheckAppPermissionsAnd;

  /// No description provided for @uiDeleteNote.
  ///
  /// In ru, this message translates to:
  /// **'Удалить заметку?'**
  String get uiDeleteNote;

  /// No description provided for @uiThisClassNoteAndItsAttachedPhotosWill.
  ///
  /// In ru, this message translates to:
  /// **'Текст и прикреплённые фото этой пары будут удалены из приложения. Оригиналы в галерее останутся.'**
  String get uiThisClassNoteAndItsAttachedPhotosWill;

  /// No description provided for @uiNoteDeleted.
  ///
  /// In ru, this message translates to:
  /// **'Заметка удалена'**
  String get uiNoteDeleted;

  /// No description provided for @uiCouldNotDeleteTheNotePleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить заметку. Попробуйте ещё раз.'**
  String get uiCouldNotDeleteTheNotePleaseTryAgain;

  /// No description provided for @uiSaveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения?'**
  String get uiSaveChanges;

  /// No description provided for @uiThisNoteHasUnsavedChanges.
  ///
  /// In ru, this message translates to:
  /// **'В заметке есть несохранённые изменения.'**
  String get uiThisNoteHasUnsavedChanges;

  /// No description provided for @uiKeepEditing.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить редактирование'**
  String get uiKeepEditing;

  /// No description provided for @uiDiscardChanges.
  ///
  /// In ru, this message translates to:
  /// **'Не сохранять'**
  String get uiDiscardChanges;

  /// No description provided for @uiSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get uiSave;

  /// No description provided for @uiAddHomework.
  ///
  /// In ru, this message translates to:
  /// **'Записать ДЗ'**
  String get uiAddHomework;

  /// No description provided for @uiFromGallery.
  ///
  /// In ru, this message translates to:
  /// **'Из галереи'**
  String get uiFromGallery;

  /// No description provided for @uiTakeAPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Снять фото'**
  String get uiTakeAPhoto;

  /// No description provided for @uiHomeworkAndNotes.
  ///
  /// In ru, this message translates to:
  /// **'ДЗ и заметки'**
  String get uiHomeworkAndNotes;

  /// No description provided for @uiDeleteNote59.
  ///
  /// In ru, this message translates to:
  /// **'Удалить заметку'**
  String get uiDeleteNote59;

  /// No description provided for @uiNoteUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Заметка недоступна'**
  String get uiNoteUnavailable;

  /// No description provided for @uiClassNote.
  ///
  /// In ru, this message translates to:
  /// **'Заметка к паре'**
  String get uiClassNote;

  /// No description provided for @uiWhatIsTheAssignmentWriteDownHomeworkOr.
  ///
  /// In ru, this message translates to:
  /// **'Что задали?\nЗапиши задание или важную мысль…'**
  String get uiWhatIsTheAssignmentWriteDownHomeworkOr;

  /// No description provided for @uiPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии'**
  String get uiPhotos;

  /// No description provided for @uiAddAssignmentPhotosFromYourGalleryOrCamera.
  ///
  /// In ru, this message translates to:
  /// **'Фото задания можно добавить из галереи или с камеры.'**
  String get uiAddAssignmentPhotosFromYourGalleryOrCamera;

  /// No description provided for @uiNotesAndPhotosAreStoredOnlyOnThis.
  ///
  /// In ru, this message translates to:
  /// **'Заметки и фото хранятся только на этом устройстве и доступны без интернета. При удалении приложения или его данных они будут потеряны.'**
  String get uiNotesAndPhotosAreStoredOnlyOnThis;

  /// No description provided for @uiUniversityNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости университета'**
  String get uiUniversityNews;

  /// No description provided for @uiCouldNotLoadThisArticle.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить новость'**
  String get uiCouldNotLoadThisArticle;

  /// No description provided for @uiArticleNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Новость не найдена'**
  String get uiArticleNotFound;

  /// No description provided for @uiThisArticleIsNoLongerAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Материал больше недоступен.'**
  String get uiThisArticleIsNoLongerAvailable;

  /// No description provided for @uiJanuary.
  ///
  /// In ru, this message translates to:
  /// **'января'**
  String get uiJanuary;

  /// No description provided for @uiFebruary.
  ///
  /// In ru, this message translates to:
  /// **'февраля'**
  String get uiFebruary;

  /// No description provided for @uiMarch.
  ///
  /// In ru, this message translates to:
  /// **'марта'**
  String get uiMarch;

  /// No description provided for @uiApril.
  ///
  /// In ru, this message translates to:
  /// **'апреля'**
  String get uiApril;

  /// No description provided for @uiMay.
  ///
  /// In ru, this message translates to:
  /// **'мая'**
  String get uiMay;

  /// No description provided for @uiJune.
  ///
  /// In ru, this message translates to:
  /// **'июня'**
  String get uiJune;

  /// No description provided for @uiJuly.
  ///
  /// In ru, this message translates to:
  /// **'июля'**
  String get uiJuly;

  /// No description provided for @uiAugust.
  ///
  /// In ru, this message translates to:
  /// **'августа'**
  String get uiAugust;

  /// No description provided for @uiSeptember.
  ///
  /// In ru, this message translates to:
  /// **'сентября'**
  String get uiSeptember;

  /// No description provided for @uiOctober.
  ///
  /// In ru, this message translates to:
  /// **'октября'**
  String get uiOctober;

  /// No description provided for @uiNovember.
  ///
  /// In ru, this message translates to:
  /// **'ноября'**
  String get uiNovember;

  /// No description provided for @uiDecember.
  ///
  /// In ru, this message translates to:
  /// **'декабря'**
  String get uiDecember;

  /// No description provided for @uiNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости'**
  String get uiNews;

  /// No description provided for @uiCouldNotLoadNews.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить новости'**
  String get uiCouldNotLoadNews;

  /// No description provided for @uiNoNewsYet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет новостей'**
  String get uiNoNewsYet;

  /// No description provided for @uiCheckBackALittleLater.
  ///
  /// In ru, this message translates to:
  /// **'Загляните сюда чуть позже.'**
  String get uiCheckBackALittleLater;

  /// No description provided for @uiUnioNews.
  ///
  /// In ru, this message translates to:
  /// **'UNIO · Новости'**
  String get uiUnioNews;

  /// No description provided for @uiOnCampus.
  ///
  /// In ru, this message translates to:
  /// **'В университете'**
  String get uiOnCampus;

  /// No description provided for @uiUniversityEventsAndAnnouncements.
  ///
  /// In ru, this message translates to:
  /// **'События и объявления университета'**
  String get uiUniversityEventsAndAnnouncements;

  /// No description provided for @uiNoDate.
  ///
  /// In ru, this message translates to:
  /// **'Без даты'**
  String get uiNoDate;

  /// No description provided for @uiToday.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get uiToday;

  /// No description provided for @uiYesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get uiYesterday;

  /// No description provided for @uiLatest.
  ///
  /// In ru, this message translates to:
  /// **'ПОСЛЕДНЕЕ'**
  String get uiLatest;

  /// No description provided for @uiOpenTheFullArticleToReadThisStory.
  ///
  /// In ru, this message translates to:
  /// **'Открой полную статью, чтобы прочитать новость.'**
  String get uiOpenTheFullArticleToReadThisStory;

  /// No description provided for @uiVgspuNews.
  ///
  /// In ru, this message translates to:
  /// **'Новости ВГСПУ'**
  String get uiVgspuNews;

  /// No description provided for @uiCloseStory.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть новость'**
  String get uiCloseStory;

  /// No description provided for @uiReadFullArticle.
  ///
  /// In ru, this message translates to:
  /// **'Читать полностью'**
  String get uiReadFullArticle;

  /// No description provided for @uiEnterYourPortalUsernameAndPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин и пароль от портала {p0}'**
  String uiEnterYourPortalUsernameAndPassword(String p0);

  /// No description provided for @uiSignInViaThePortal.
  ///
  /// In ru, this message translates to:
  /// **'Вход через портал {p0}'**
  String uiSignInViaThePortal(String p0);

  /// No description provided for @uiUseYourUniversityPortalUsernameAndPassword.
  ///
  /// In ru, this message translates to:
  /// **'Используй логин и пароль от портала университета.'**
  String get uiUseYourUniversityPortalUsernameAndPassword;

  /// No description provided for @uiPortalUsername.
  ///
  /// In ru, this message translates to:
  /// **'Логин от портала'**
  String get uiPortalUsername;

  /// No description provided for @uiPortalPassword.
  ///
  /// In ru, this message translates to:
  /// **'Пароль от портала'**
  String get uiPortalPassword;

  /// No description provided for @uiSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get uiSignIn;

  /// No description provided for @uiYourPasswordIsNotSavedInTheBrowser.
  ///
  /// In ru, this message translates to:
  /// **'Пароль не сохраняется в браузере. Вход остаётся активным после закрытия UNIO.'**
  String get uiYourPasswordIsNotSavedInTheBrowser;

  /// No description provided for @uiYourUsernameAndPasswordAreStoredEncryptedOn.
  ///
  /// In ru, this message translates to:
  /// **'Логин и пароль хранятся зашифрованно на устройстве.'**
  String get uiYourUsernameAndPasswordAreStoredEncryptedOn;

  /// No description provided for @uiPortalTemporarilyUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Портал пока недоступен'**
  String get uiPortalTemporarilyUnavailable;

  /// No description provided for @uiCheckYourVgspuPortalAccount.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте личный кабинет ВГСПУ'**
  String get uiCheckYourVgspuPortalAccount;

  /// No description provided for @uiCouldNotLoadApplications.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить заявления'**
  String get uiCouldNotLoadApplications;

  /// No description provided for @uiApplicationStatusEditingIsCurrentlyUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Статус заявления: {p0}. Заполнение сейчас недоступно.'**
  String uiApplicationStatusEditingIsCurrentlyUnavailable(String p0);

  /// No description provided for @uiApplicationCreatedThePortalIsPreparingTheForm.
  ///
  /// In ru, this message translates to:
  /// **'Заявление создано. Подождите немного — портал готовит форму. Обновите список чуть позже.'**
  String get uiApplicationCreatedThePortalIsPreparingTheForm;

  /// No description provided for @uiCertificatesAndApplications.
  ///
  /// In ru, this message translates to:
  /// **'Справки и заявления'**
  String get uiCertificatesAndApplications;

  /// No description provided for @uiRefreshStatuses.
  ///
  /// In ru, this message translates to:
  /// **'Обновить статусы'**
  String get uiRefreshStatuses;

  /// No description provided for @uiCreatingApplication.
  ///
  /// In ru, this message translates to:
  /// **'Создаём заявление…'**
  String get uiCreatingApplication;

  /// No description provided for @uiSubmitAnApplication.
  ///
  /// In ru, this message translates to:
  /// **'Подать заявление'**
  String get uiSubmitAnApplication;

  /// No description provided for @uiMyApplications.
  ///
  /// In ru, this message translates to:
  /// **'Мои заявления'**
  String get uiMyApplications;

  /// No description provided for @uiCheckedAtPullDownToRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Проверено в {p0} · потяните вниз, чтобы обновить'**
  String uiCheckedAtPullDownToRefresh(String p0);

  /// No description provided for @uiCouldNotRefreshStatusesShowingPreviousData.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить статусы. Показаны предыдущие данные.\n{p0}'**
  String uiCouldNotRefreshStatusesShowingPreviousData(String p0);

  /// No description provided for @uiNoApplicationsYet.
  ///
  /// In ru, this message translates to:
  /// **'Заявлений пока нет'**
  String get uiNoApplicationsYet;

  /// No description provided for @uiChooseTheDocumentYouNeedUsingTheButton.
  ///
  /// In ru, this message translates to:
  /// **'Выберите нужный документ кнопкой ниже.'**
  String get uiChooseTheDocumentYouNeedUsingTheButton;

  /// No description provided for @uiNewApplication.
  ///
  /// In ru, this message translates to:
  /// **'Новое заявление'**
  String get uiNewApplication;

  /// No description provided for @uiWhichDocumentDoYouNeed.
  ///
  /// In ru, this message translates to:
  /// **'Какой документ нужен?'**
  String get uiWhichDocumentDoYouNeed;

  /// No description provided for @uiChooseACategoryAndApplicationTypeFromThe.
  ///
  /// In ru, this message translates to:
  /// **'Выберите категорию и вид заявления из списка университета.'**
  String get uiChooseACategoryAndApplicationTypeFromThe;

  /// No description provided for @uiCategory.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get uiCategory;

  /// No description provided for @uiRetryLoading.
  ///
  /// In ru, this message translates to:
  /// **'Повторить загрузку'**
  String get uiRetryLoading;

  /// No description provided for @uiNoApplicationsAvailableInThisCategory.
  ///
  /// In ru, this message translates to:
  /// **'В этой категории нет доступных заявлений.'**
  String get uiNoApplicationsAvailableInThisCategory;

  /// No description provided for @uiApplicationType.
  ///
  /// In ru, this message translates to:
  /// **'Вид заявления'**
  String get uiApplicationType;

  /// No description provided for @uiCreateApplication.
  ///
  /// In ru, this message translates to:
  /// **'Создать заявление'**
  String get uiCreateApplication;

  /// No description provided for @uiADraftWillBeCreatedOnThePortal.
  ///
  /// In ru, this message translates to:
  /// **'На портале будет создан черновик. На обработку вы отправите его после проверки данных.'**
  String get uiADraftWillBeCreatedOnThePortal;

  /// No description provided for @uiComingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Скоро здесь'**
  String get uiComingSoon;

  /// No description provided for @uiThisSectionIsStillBeingDeveloped.
  ///
  /// In ru, this message translates to:
  /// **'Раздел ещё дорабатывается.'**
  String get uiThisSectionIsStillBeingDeveloped;

  /// No description provided for @uiCouldNotOpenTheBrowser.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть браузер.'**
  String get uiCouldNotOpenTheBrowser;

  /// No description provided for @uiTemplateSavedFillItOutInADocument.
  ///
  /// In ru, this message translates to:
  /// **'Шаблон сохранён. Заполните его в редакторе документов и прикрепите к заявлению.'**
  String get uiTemplateSavedFillItOutInADocument;

  /// No description provided for @uiCouldNotSaveTheTemplateTryAgainAnd.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить шаблон. Попробуйте ещё раз и выберите доступную папку.'**
  String get uiCouldNotSaveTheTemplateTryAgainAnd;

  /// No description provided for @uiApplication.
  ///
  /// In ru, this message translates to:
  /// **'Заявление'**
  String get uiApplication;

  /// No description provided for @uiChooseAFileInOneOfTheListed.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл в одном из указанных форматов.'**
  String get uiChooseAFileInOneOfTheListed;

  /// No description provided for @uiChooseAFileUpToMb.
  ///
  /// In ru, this message translates to:
  /// **'Выберите файл размером до 20 МБ.'**
  String get uiChooseAFileUpToMb;

  /// No description provided for @uiTheSelectedFileIsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Выбран пустой файл.'**
  String get uiTheSelectedFileIsEmpty;

  /// No description provided for @uiCouldNotReadTheFilePleaseSelectIt.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать файл. Попробуйте выбрать его ещё раз.'**
  String get uiCouldNotReadTheFilePleaseSelectIt;

  /// No description provided for @uiAttachYourApplication.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепите заявление'**
  String get uiAttachYourApplication;

  /// No description provided for @uiFileAlreadyUploadedToThePortal.
  ///
  /// In ru, this message translates to:
  /// **'Файл уже загружен на портал'**
  String get uiFileAlreadyUploadedToThePortal;

  /// No description provided for @uiAttachADocumentConfirmingYourSelectedCategory.
  ///
  /// In ru, this message translates to:
  /// **'Прикрепите документ, подтверждающий выбранную категорию.'**
  String get uiAttachADocumentConfirmingYourSelectedCategory;

  /// No description provided for @uiFillOutTheTemplateAndAttachYourApplication.
  ///
  /// In ru, this message translates to:
  /// **'Заполните шаблон и прикрепите файл заявления.'**
  String get uiFillOutTheTemplateAndAttachYourApplication;

  /// No description provided for @uiUpToMb.
  ///
  /// In ru, this message translates to:
  /// **'{p0} · до 20 МБ'**
  String uiUpToMb(String p0);

  /// No description provided for @uiChooseFile.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать файл'**
  String get uiChooseFile;

  /// No description provided for @uiReplaceFile.
  ///
  /// In ru, this message translates to:
  /// **'Заменить файл'**
  String get uiReplaceFile;

  /// No description provided for @uiTheFileWillBeUploadedWhenYouSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Файл будет загружен на портал при отправке заявления.'**
  String get uiTheFileWillBeUploadedWhenYouSubmit;

  /// No description provided for @uiRemoveSelectedFile.
  ///
  /// In ru, this message translates to:
  /// **'Убрать выбранный файл'**
  String get uiRemoveSelectedFile;

  /// No description provided for @uiSubmitApplication.
  ///
  /// In ru, this message translates to:
  /// **'Отправить заявление?'**
  String get uiSubmitApplication;

  /// No description provided for @uiCheckYourDetailsAndAttachmentsYourApplicationWill.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте заполненные данные и вложения. Заявление поступит на обработку в университет.'**
  String get uiCheckYourDetailsAndAttachmentsYourApplicationWill;

  /// No description provided for @uiReviewAgain.
  ///
  /// In ru, this message translates to:
  /// **'Проверить ещё раз'**
  String get uiReviewAgain;

  /// No description provided for @uiSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get uiSubmit;

  /// No description provided for @uiSubmissionCouldNotBeConfirmedCheckTheApplication.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подтвердить отправку. Проверьте статус в списке заявлений перед повторной попыткой — портал мог уже получить данные.'**
  String get uiSubmissionCouldNotBeConfirmedCheckTheApplication;

  /// No description provided for @uiEmailAddress.
  ///
  /// In ru, this message translates to:
  /// **'Электронная почта'**
  String get uiEmailAddress;

  /// No description provided for @uiPostalAddress.
  ///
  /// In ru, this message translates to:
  /// **'Почтовый адрес'**
  String get uiPostalAddress;

  /// No description provided for @uiStartOfPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Начало периода'**
  String get uiStartOfPeriod;

  /// No description provided for @uiEndOfPeriod.
  ///
  /// In ru, this message translates to:
  /// **'Конец периода'**
  String get uiEndOfPeriod;

  /// No description provided for @uiNumberOfCopies.
  ///
  /// In ru, this message translates to:
  /// **'Количество справок'**
  String get uiNumberOfCopies;

  /// No description provided for @uiDdMmYyyy.
  ///
  /// In ru, this message translates to:
  /// **'ДД.ММ.ГГГГ'**
  String get uiDdMmYyyy;

  /// No description provided for @uiChooseDate.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать дату'**
  String get uiChooseDate;

  /// No description provided for @uiPleaseConfirmYourConsent.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите согласие'**
  String get uiPleaseConfirmYourConsent;

  /// No description provided for @uiApplication160.
  ///
  /// In ru, this message translates to:
  /// **'Заявление №{p0}'**
  String uiApplication160(String p0);

  /// No description provided for @uiFormNotAvailableYet.
  ///
  /// In ru, this message translates to:
  /// **'Форма пока недоступна'**
  String get uiFormNotAvailableYet;

  /// No description provided for @uiCouldNotOpenApplication.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть заявление'**
  String get uiCouldNotOpenApplication;

  /// No description provided for @uiBackToApplications.
  ///
  /// In ru, this message translates to:
  /// **'К списку заявлений'**
  String get uiBackToApplications;

  /// No description provided for @uiFillInYourDetails.
  ///
  /// In ru, this message translates to:
  /// **'Заполните данные'**
  String get uiFillInYourDetails;

  /// No description provided for @uiApplicationOnThePortal.
  ///
  /// In ru, this message translates to:
  /// **'Заявление на портале'**
  String get uiApplicationOnThePortal;

  /// No description provided for @uiFieldsMarkedWithAnAsteriskAreRequiredYou.
  ///
  /// In ru, this message translates to:
  /// **'Поля со звёздочкой обязательны. Перед отправкой вы сможете проверить данные.'**
  String get uiFieldsMarkedWithAnAsteriskAreRequiredYou;

  /// No description provided for @uiThisApplicationCannotBeEditedItsCurrentStatus.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование этой заявки недоступно. Актуальный статус указан в списке заявлений.'**
  String get uiThisApplicationCannotBeEditedItsCurrentStatus;

  /// No description provided for @uiSaving168.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get uiSaving168;

  /// No description provided for @uiDownloadWordTemplate.
  ///
  /// In ru, this message translates to:
  /// **'Скачать шаблон Word'**
  String get uiDownloadWordTemplate;

  /// No description provided for @uiOpenTemplateOnThePortal.
  ///
  /// In ru, this message translates to:
  /// **'Открыть шаблон на портале'**
  String get uiOpenTemplateOnThePortal;

  /// No description provided for @uiSomeAttachmentsOrFieldsInThisFormAre.
  ///
  /// In ru, this message translates to:
  /// **'Эта форма содержит вложения или поля, которые пока доступны только на портале. Продолжите заполнение в браузере.'**
  String get uiSomeAttachmentsOrFieldsInThisFormAre;

  /// No description provided for @uiSubmitForProcessing.
  ///
  /// In ru, this message translates to:
  /// **'Отправить на обработку'**
  String get uiSubmitForProcessing;

  /// No description provided for @uiCheckApplicationStatus.
  ///
  /// In ru, this message translates to:
  /// **'Проверить статус заявления'**
  String get uiCheckApplicationStatus;

  /// No description provided for @uiOpenOnTheVgspuPortal.
  ///
  /// In ru, this message translates to:
  /// **'Открыть на портале ВГСПУ'**
  String get uiOpenOnTheVgspuPortal;

  /// No description provided for @uiClassPhotosRecoveredAndSaved.
  ///
  /// In ru, this message translates to:
  /// **'Фотографии к паре восстановлены и сохранены'**
  String get uiClassPhotosRecoveredAndSaved;

  /// No description provided for @uiCouldNotRecoverTheSelectedPhotosOpenThe.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить выбранные фото. Откройте заметку и добавьте их ещё раз.'**
  String get uiCouldNotRecoverTheSelectedPhotosOpenThe;

  /// No description provided for @uiNextWeek.
  ///
  /// In ru, this message translates to:
  /// **'Следующая неделя'**
  String get uiNextWeek;

  /// No description provided for @uiThisWeek.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get uiThisWeek;

  /// No description provided for @uiCouldNotLoadSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить расписание'**
  String get uiCouldNotLoadSchedule;

  /// No description provided for @uiCheckYourInternetConnectionAndTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте подключение к интернету и попробуйте ещё раз'**
  String get uiCheckYourInternetConnectionAndTryAgain;

  /// No description provided for @uiNoScheduleFoundForThisWeek.
  ///
  /// In ru, this message translates to:
  /// **'На выбранную неделю расписание не найдено'**
  String get uiNoScheduleFoundForThisWeek;

  /// No description provided for @uiEndGuestSession.
  ///
  /// In ru, this message translates to:
  /// **'Завершить гостевой сеанс'**
  String get uiEndGuestSession;

  /// No description provided for @uiSignOut.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get uiSignOut;

  /// No description provided for @uiYouWillNeedToChooseAGroupAgain.
  ///
  /// In ru, this message translates to:
  /// **'Для нового гостевого сеанса потребуется снова выбрать группу.'**
  String get uiYouWillNeedToChooseAGroupAgain;

  /// No description provided for @uiYouWillNeedToSignInAgainTo.
  ///
  /// In ru, this message translates to:
  /// **'Для доступа к аккаунту потребуется войти снова.'**
  String get uiYouWillNeedToSignInAgainTo;

  /// No description provided for @uiEndSession.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get uiEndSession;

  /// No description provided for @uiSignOut187.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get uiSignOut187;

  /// No description provided for @uiAccountAndAppPreferences.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт и параметры приложения'**
  String get uiAccountAndAppPreferences;

  /// No description provided for @uiTeacher.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель'**
  String get uiTeacher;

  /// No description provided for @uiPersonalAccount.
  ///
  /// In ru, this message translates to:
  /// **'Личный аккаунт'**
  String get uiPersonalAccount;

  /// No description provided for @uiGroup.
  ///
  /// In ru, this message translates to:
  /// **'Группа {p0}'**
  String uiGroup(String p0);

  /// No description provided for @uiPortal.
  ///
  /// In ru, this message translates to:
  /// **'Портал {p0}'**
  String uiPortal(String p0);

  /// No description provided for @uiGuestAccess.
  ///
  /// In ru, this message translates to:
  /// **'Гостевой доступ'**
  String get uiGuestAccess;

  /// No description provided for @uiScheduleForGroup.
  ///
  /// In ru, this message translates to:
  /// **'Расписание группы {p0}'**
  String uiScheduleForGroup(String p0);

  /// No description provided for @uiChangeGroup.
  ///
  /// In ru, this message translates to:
  /// **'Сменить группу'**
  String get uiChangeGroup;

  /// No description provided for @uiSignInToThePortalAgain.
  ///
  /// In ru, this message translates to:
  /// **'Повторить вход через портал'**
  String get uiSignInToThePortalAgain;

  /// No description provided for @uiSignInViaThePortal198.
  ///
  /// In ru, this message translates to:
  /// **'Войти через портал {p0}'**
  String uiSignInViaThePortal198(String p0);

  /// No description provided for @uiPreferences.
  ///
  /// In ru, this message translates to:
  /// **'Параметры'**
  String get uiPreferences;

  /// No description provided for @uiDarkTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get uiDarkTheme;

  /// No description provided for @uiPushNotifications.
  ///
  /// In ru, this message translates to:
  /// **'Пуш-уведомления'**
  String get uiPushNotifications;

  /// No description provided for @uiNotificationsAreCurrentlyUnavailableOnIphoneAddUnio.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления пока недоступны. На iPhone добавьте UNIO на главный экран.'**
  String get uiNotificationsAreCurrentlyUnavailableOnIphoneAddUnio;

  /// No description provided for @uiScheduleWidget.
  ///
  /// In ru, this message translates to:
  /// **'Виджет расписания'**
  String get uiScheduleWidget;

  /// No description provided for @uiYourNextClassOnTheHomeScreen.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшая пара на рабочем столе'**
  String get uiYourNextClassOnTheHomeScreen;

  /// No description provided for @uiPrivacy.
  ///
  /// In ru, this message translates to:
  /// **'Конфиденциальность'**
  String get uiPrivacy;

  /// No description provided for @uiConsentAnalyticsAndDeletion.
  ///
  /// In ru, this message translates to:
  /// **'Согласия, аналитика и удаление'**
  String get uiConsentAnalyticsAndDeletion;

  /// No description provided for @uiInstallUnio.
  ///
  /// In ru, this message translates to:
  /// **'Установить UNIO'**
  String get uiInstallUnio;

  /// No description provided for @uiAddToHomeScreenWebBeta.
  ///
  /// In ru, this message translates to:
  /// **'На главный экран · веб-бета'**
  String get uiAddToHomeScreenWebBeta;

  /// No description provided for @uiNotesAreStoredInThisBrowserClearingSite.
  ///
  /// In ru, this message translates to:
  /// **'Заметки хранятся в этом браузере. Очистка данных сайта удаляет их. Пароль портала в веб-версии не сохраняется.'**
  String get uiNotesAreStoredInThisBrowserClearingSite;

  /// No description provided for @uiSigningOut.
  ///
  /// In ru, this message translates to:
  /// **'Выход…'**
  String get uiSigningOut;

  /// No description provided for @uiUnioVersion.
  ///
  /// In ru, this message translates to:
  /// **'UNIO · Версия {p0}'**
  String uiUnioVersion(String p0);

  /// No description provided for @uiCouldNotSignOutPleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти. Попробуйте ещё раз.'**
  String get uiCouldNotSignOutPleaseTryAgain;

  /// No description provided for @uiClass.
  ///
  /// In ru, this message translates to:
  /// **'Занятие'**
  String get uiClass;

  /// No description provided for @uiClassDetailsAndTeachingTools.
  ///
  /// In ru, this message translates to:
  /// **'Детали занятия и инструменты преподавателя.'**
  String get uiClassDetailsAndTeachingTools;

  /// No description provided for @uiRoomNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория не указана'**
  String get uiRoomNotSpecified;

  /// No description provided for @uiRoom.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория {p0}'**
  String uiRoom(String p0);

  /// No description provided for @uiFindAnAvailableRoom.
  ///
  /// In ru, this message translates to:
  /// **'Найти свободную аудиторию'**
  String get uiFindAnAvailableRoom;

  /// No description provided for @uiBackToSchedule.
  ///
  /// In ru, this message translates to:
  /// **'К расписанию'**
  String get uiBackToSchedule;

  /// No description provided for @uiAvailableRooms.
  ///
  /// In ru, this message translates to:
  /// **'Свободные аудитории'**
  String get uiAvailableRooms;

  /// No description provided for @uiCouldNotFindRooms.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти аудитории'**
  String get uiCouldNotFindRooms;

  /// No description provided for @uiForTeachers.
  ///
  /// In ru, this message translates to:
  /// **'Для преподавателя'**
  String get uiForTeachers;

  /// No description provided for @uiARoomForYourClass.
  ///
  /// In ru, this message translates to:
  /// **'Место для пары'**
  String get uiARoomForYourClass;

  /// No description provided for @uiNoAvailableRoomsFoundInTheKnownSchedules.
  ///
  /// In ru, this message translates to:
  /// **'По известным расписаниям свободных аудиторий не найдено.'**
  String get uiNoAvailableRoomsFoundInTheKnownSchedules;

  /// No description provided for @uiRoom224.
  ///
  /// In ru, this message translates to:
  /// **'Ауд. {p0}'**
  String uiRoom224(String p0);

  /// No description provided for @uiTodaySSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня по расписанию'**
  String get uiTodaySSchedule;

  /// No description provided for @uiPartOfTheScheduleIsUnavailableShowingKnown.
  ///
  /// In ru, this message translates to:
  /// **'Часть расписания недоступна. Показаны известные занятия.'**
  String get uiPartOfTheScheduleIsUnavailableShowingKnown;

  /// No description provided for @uiNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас · {p0}–{p1}'**
  String uiNow(String p0, String p1);

  /// No description provided for @uiCouldNotDetermineWhetherThereIsAClass.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить, есть ли занятие сейчас.'**
  String get uiCouldNotDetermineWhetherThereIsAClass;

  /// No description provided for @uiNoClassesScheduledRightNow.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас занятий по расписанию нет.'**
  String get uiNoClassesScheduledRightNow;

  /// No description provided for @uiNext.
  ///
  /// In ru, this message translates to:
  /// **'Следующая · {p0}'**
  String uiNext(String p0);

  /// No description provided for @uiTimesForUpcomingClassesAreNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Время следующих занятий не указано.'**
  String get uiTimesForUpcomingClassesAreNotSpecified;

  /// No description provided for @uiNoMoreClassesToday.
  ///
  /// In ru, this message translates to:
  /// **'Следующих занятий сегодня нет.'**
  String get uiNoMoreClassesToday;

  /// No description provided for @uiTheScheduleShowsPlannedClassesNotAPerson.
  ///
  /// In ru, this message translates to:
  /// **'Расписание показывает запланированные занятия, а не фактическое присутствие в вузе.'**
  String get uiTheScheduleShowsPlannedClassesNotAPerson;

  /// No description provided for @uiSavedDataNotConfirmedWithTheServer.
  ///
  /// In ru, this message translates to:
  /// **'Есть сохранённые данные · без актуального подтверждения с сервера'**
  String get uiSavedDataNotConfirmedWithTheServer;

  /// No description provided for @uiTodaySScheduleHasNotLoadedRefreshTo.
  ///
  /// In ru, this message translates to:
  /// **'Расписание на сегодня не загружено. Обновите экран, чтобы повторить.'**
  String get uiTodaySScheduleHasNotLoadedRefreshTo;

  /// No description provided for @uiRefreshSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Обновить расписание'**
  String get uiRefreshSchedule;

  /// No description provided for @uiClassesAndRoomsFromTheUniversitySchedule.
  ///
  /// In ru, this message translates to:
  /// **'Занятия и аудитории по расписанию университета.'**
  String get uiClassesAndRoomsFromTheUniversitySchedule;

  /// No description provided for @uiClassSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание занятий'**
  String get uiClassSchedule;

  /// No description provided for @uiPreviousDay.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущий день'**
  String get uiPreviousDay;

  /// No description provided for @uiToday240.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня · {p0}'**
  String uiToday240(String p0);

  /// No description provided for @uiNextDay.
  ///
  /// In ru, this message translates to:
  /// **'Следующий день'**
  String get uiNextDay;

  /// No description provided for @uiBackToToday.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к сегодня'**
  String get uiBackToToday;

  /// No description provided for @uiCouldNotLoadClasses.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить занятия'**
  String get uiCouldNotLoadClasses;

  /// No description provided for @uiTheScheduleHasNotLoadedCompletely.
  ///
  /// In ru, this message translates to:
  /// **'Расписание загружено не полностью.'**
  String get uiTheScheduleHasNotLoadedCompletely;

  /// No description provided for @uiShowingSavedSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Показано сохранённое расписание.'**
  String get uiShowingSavedSchedule;

  /// No description provided for @uiNoKnownClassesForThisDayTheFull.
  ///
  /// In ru, this message translates to:
  /// **'Известных занятий на этот день нет. Полное расписание пока недоступно.'**
  String get uiNoKnownClassesForThisDayTheFull;

  /// No description provided for @uiViewClassesAndRooms.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть занятия и аудитории'**
  String get uiViewClassesAndRooms;

  /// No description provided for @uiFindATeacher.
  ///
  /// In ru, this message translates to:
  /// **'Найти преподавателя'**
  String get uiFindATeacher;

  /// No description provided for @uiRefreshDirectory.
  ///
  /// In ru, this message translates to:
  /// **'Обновить справочник'**
  String get uiRefreshDirectory;

  /// No description provided for @uiSurnameOrPartOfAName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия или часть ФИО'**
  String get uiSurnameOrPartOfAName;

  /// No description provided for @uiClearSearch.
  ///
  /// In ru, this message translates to:
  /// **'Очистить поиск'**
  String get uiClearSearch;

  /// No description provided for @uiSearchingTheSavedDirectory.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по сохранённому справочнику'**
  String get uiSearchingTheSavedDirectory;

  /// No description provided for @uiDirectoryCurrentlyUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Справочник пока недоступен'**
  String get uiDirectoryCurrentlyUnavailable;

  /// No description provided for @uiRecentlyViewed.
  ///
  /// In ru, this message translates to:
  /// **'Недавно смотрели'**
  String get uiRecentlyViewed;

  /// No description provided for @uiClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить'**
  String get uiClear;

  /// No description provided for @uiWhoAreYouLookingFor.
  ///
  /// In ru, this message translates to:
  /// **'Кого ищем?'**
  String get uiWhoAreYouLookingFor;

  /// No description provided for @uiEnterAtLeastTwoLettersOfASurname.
  ///
  /// In ru, this message translates to:
  /// **'Введите хотя бы две буквы фамилии. Полное ФИО знать не обязательно.'**
  String get uiEnterAtLeastTwoLettersOfASurname;

  /// No description provided for @uiNoMatches.
  ///
  /// In ru, this message translates to:
  /// **'Совпадений нет'**
  String get uiNoMatches;

  /// No description provided for @uiCheckTheSurnameOrTryFewerLetters.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте фамилию или попробуйте ввести меньше букв.'**
  String get uiCheckTheSurnameOrTryFewerLetters;

  /// No description provided for @uiChooseATeacher.
  ///
  /// In ru, this message translates to:
  /// **'Выберите преподавателя'**
  String get uiChooseATeacher;

  /// No description provided for @uiMoreMatchesAvailableRefineTheSurname.
  ///
  /// In ru, this message translates to:
  /// **'Есть ещё совпадения — уточните фамилию.'**
  String get uiMoreMatchesAvailableRefineTheSurname;

  /// No description provided for @uiUniversityEventsAnnouncementsAndCampusLife.
  ///
  /// In ru, this message translates to:
  /// **'События, объявления и жизнь университета'**
  String get uiUniversityEventsAnnouncementsAndCampusLife;

  /// No description provided for @uiCertificatesFormsAndPortalResponses.
  ///
  /// In ru, this message translates to:
  /// **'Справки, формы и ответы портала'**
  String get uiCertificatesFormsAndPortalResponses;

  /// No description provided for @uiTeachers.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватели'**
  String get uiTeachers;

  /// No description provided for @uiSearchBySurnameClassesAndRooms.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по фамилии, занятия и аудитории'**
  String get uiSearchBySurnameClassesAndRooms;

  /// No description provided for @uiUnioUniversity.
  ///
  /// In ru, this message translates to:
  /// **'UNIO · Университет'**
  String get uiUnioUniversity;

  /// No description provided for @uiForYourStudies.
  ///
  /// In ru, this message translates to:
  /// **'Всё для учёбы'**
  String get uiForYourStudies;

  /// No description provided for @uiNewsApplicationsAndTeacherSearchInOnePlace.
  ///
  /// In ru, this message translates to:
  /// **'Новости, заявления и поиск преподавателей — в одном месте.'**
  String get uiNewsApplicationsAndTeacherSearchInOnePlace;

  /// No description provided for @uiApplications.
  ///
  /// In ru, this message translates to:
  /// **'Заявления'**
  String get uiApplications;

  /// No description provided for @uiUseYourUniversityAccountYourApplicationsWillAppear.
  ///
  /// In ru, this message translates to:
  /// **'Используйте учётную запись университета. После входа откроется список заявлений.'**
  String get uiUseYourUniversityAccountYourApplicationsWillAppear;

  /// No description provided for @uiBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get uiBack;

  /// No description provided for @uiSkip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get uiSkip;

  /// No description provided for @uiPageOf.
  ///
  /// In ru, this message translates to:
  /// **'Страница {p0} из {p1}'**
  String uiPageOf(String p0, String p1);

  /// No description provided for @uiPage.
  ///
  /// In ru, this message translates to:
  /// **'Страница {p0}'**
  String uiPage(String p0);

  /// No description provided for @uiGetStarted.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get uiGetStarted;

  /// No description provided for @uiNext276.
  ///
  /// In ru, this message translates to:
  /// **'Дальше'**
  String get uiNext276;

  /// No description provided for @uiLetSGetAcquainted.
  ///
  /// In ru, this message translates to:
  /// **'ДАВАЙ ЗНАКОМИТЬСЯ'**
  String get uiLetSGetAcquainted;

  /// No description provided for @uiChooseYourRole.
  ///
  /// In ru, this message translates to:
  /// **'Выбери\nсвою роль'**
  String get uiChooseYourRole;

  /// No description provided for @uiStudentsAndTeachersHaveAccessToDifferentSections.
  ///
  /// In ru, this message translates to:
  /// **'Для студентов и преподавателей доступны разные разделы.'**
  String get uiStudentsAndTeachersHaveAccessToDifferentSections;

  /// No description provided for @uiDoYouStudyOrTeach.
  ///
  /// In ru, this message translates to:
  /// **'Ты учишься или преподаёшь?'**
  String get uiDoYouStudyOrTeach;

  /// No description provided for @uiIMAStudent.
  ///
  /// In ru, this message translates to:
  /// **'Я студент'**
  String get uiIMAStudent;

  /// No description provided for @uiClassesGradesAndApplications.
  ///
  /// In ru, this message translates to:
  /// **'Пары, зачётка и заявления'**
  String get uiClassesGradesAndApplications;

  /// No description provided for @uiIMATeacher.
  ///
  /// In ru, this message translates to:
  /// **'Я преподаватель'**
  String get uiIMATeacher;

  /// No description provided for @uiScheduleAndAvailableRooms.
  ///
  /// In ru, this message translates to:
  /// **'Расписание и свободные аудитории'**
  String get uiScheduleAndAvailableRooms;

  /// No description provided for @uiYouCanChangeYourRoleBySigningOut.
  ///
  /// In ru, this message translates to:
  /// **'Можно сменить роль, выйдя из аккаунта.'**
  String get uiYouCanChangeYourRoleBySigningOut;

  /// No description provided for @uiForStudents.
  ///
  /// In ru, this message translates to:
  /// **'СТУДЕНТАМ'**
  String get uiForStudents;

  /// No description provided for @uiHowWouldYouLikeToSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Как хочешь\nвойти?'**
  String get uiHowWouldYouLikeToSignIn;

  /// No description provided for @uiConnectYourPortalAccountOrStartWithYour.
  ///
  /// In ru, this message translates to:
  /// **'Подключи портал или начни с расписания своей группы.'**
  String get uiConnectYourPortalAccountOrStartWithYour;

  /// No description provided for @uiWhatWorksForYou.
  ///
  /// In ru, this message translates to:
  /// **'Как тебе удобнее?'**
  String get uiWhatWorksForYou;

  /// No description provided for @uiScheduleGradesAndApplications.
  ///
  /// In ru, this message translates to:
  /// **'Расписание, зачётка, заявления'**
  String get uiScheduleGradesAndApplications;

  /// No description provided for @uiContinueAsAGuest.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить как гость'**
  String get uiContinueAsAGuest;

  /// No description provided for @uiStartWithYourGroupCodeYouCanConnect.
  ///
  /// In ru, this message translates to:
  /// **'Начни с номера группы. Портал можно подключить позже.'**
  String get uiStartWithYourGroupCodeYouCanConnect;

  /// No description provided for @uiWelcomeToUnio.
  ///
  /// In ru, this message translates to:
  /// **'ПРИВЕТ, ЭТО UNIO'**
  String get uiWelcomeToUnio;

  /// No description provided for @uiHiThisIsUnio.
  ///
  /// In ru, this message translates to:
  /// **'Привет! Это UNIO.'**
  String get uiHiThisIsUnio;

  /// No description provided for @uiAnAppForYourStudies.
  ///
  /// In ru, this message translates to:
  /// **'Приложение для учёбы.'**
  String get uiAnAppForYourStudies;

  /// No description provided for @uiViewYourScheduleSaveAssignmentsAndRequestCertificates.
  ///
  /// In ru, this message translates to:
  /// **'Здесь можно смотреть расписание, записывать задания и заказывать справки.'**
  String get uiViewYourScheduleSaveAssignmentsAndRequestCertificates;

  /// No description provided for @uiSchedule297.
  ///
  /// In ru, this message translates to:
  /// **'РАСПИСАНИЕ'**
  String get uiSchedule297;

  /// No description provided for @uiYourClassSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание занятий.'**
  String get uiYourClassSchedule;

  /// No description provided for @uiForTodayAndTheWeek.
  ///
  /// In ru, this message translates to:
  /// **'На сегодня и неделю.'**
  String get uiForTodayAndTheWeek;

  /// No description provided for @uiChooseADayToViewClassesTimesAnd.
  ///
  /// In ru, this message translates to:
  /// **'Выбери день и посмотри пары, время и аудитории. Сохранённое расписание работает без интернета.'**
  String get uiChooseADayToViewClassesTimesAnd;

  /// No description provided for @uiCertificatesAndApplications301.
  ///
  /// In ru, this message translates to:
  /// **'СПРАВКИ И ЗАЯВЛЕНИЯ'**
  String get uiCertificatesAndApplications301;

  /// No description provided for @uiNeedACertificate.
  ///
  /// In ru, this message translates to:
  /// **'Нужна справка?'**
  String get uiNeedACertificate;

  /// No description provided for @uiRequestItInTheApp.
  ///
  /// In ru, this message translates to:
  /// **'Закажи в приложении.'**
  String get uiRequestItInTheApp;

  /// No description provided for @uiRequestCertificatesViaThePortalTrackTheirStatus.
  ///
  /// In ru, this message translates to:
  /// **'Заказывай справки через портал, следи за статусом и получай уведомления о готовности.'**
  String get uiRequestCertificatesViaThePortalTrackTheirStatus;

  /// No description provided for @uiMoreFeatures.
  ///
  /// In ru, this message translates to:
  /// **'ДРУГИЕ РАЗДЕЛЫ'**
  String get uiMoreFeatures;

  /// No description provided for @uiNewsAndTeachers.
  ///
  /// In ru, this message translates to:
  /// **'Новости и преподаватели.'**
  String get uiNewsAndTeachers;

  /// No description provided for @uiHomeworkAndNotes307.
  ///
  /// In ru, this message translates to:
  /// **'Задания и заметки.'**
  String get uiHomeworkAndNotes307;

  /// No description provided for @uiFindTeachersAndTheirClassesReadUniversityNews.
  ///
  /// In ru, this message translates to:
  /// **'Ищи преподавателей и их занятия, читай новости вуза и оставляй заметки к своим парам.'**
  String get uiFindTeachersAndTheirClassesReadUniversityNews;

  /// No description provided for @uiEnterYourFullNameCharacters.
  ///
  /// In ru, this message translates to:
  /// **'Введите ФИО (от 3 до 255 символов)'**
  String get uiEnterYourFullNameCharacters;

  /// No description provided for @uiEnterYourVgspuPortalUsernameAndPassword.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин и пароль от портала ВГСПУ'**
  String get uiEnterYourVgspuPortalUsernameAndPassword;

  /// No description provided for @uiEnterYourGroupUsernameAndPassword.
  ///
  /// In ru, this message translates to:
  /// **'Заполните группу, логин и пароль'**
  String get uiEnterYourGroupUsernameAndPassword;

  /// No description provided for @uiEnterYourGroupCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер группы'**
  String get uiEnterYourGroupCode;

  /// No description provided for @uiCouldNotSignInCheckYourConnectionAnd.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти. Проверьте соединение и попробуйте ещё раз.'**
  String get uiCouldNotSignInCheckYourConnectionAnd;

  /// No description provided for @uiForTeachers314.
  ///
  /// In ru, this message translates to:
  /// **'ПРЕПОДАВАТЕЛЯМ'**
  String get uiForTeachers314;

  /// No description provided for @uiYourAccount.
  ///
  /// In ru, this message translates to:
  /// **'ЛИЧНЫЙ КАБИНЕТ'**
  String get uiYourAccount;

  /// No description provided for @uiQuickStart.
  ///
  /// In ru, this message translates to:
  /// **'БЫСТРЫЙ СТАРТ'**
  String get uiQuickStart;

  /// No description provided for @uiTeacherSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание\nпреподавателя'**
  String get uiTeacherSchedule;

  /// No description provided for @uiSignInViaThePortal318.
  ///
  /// In ru, this message translates to:
  /// **'Вход\nчерез портал'**
  String get uiSignInViaThePortal318;

  /// No description provided for @uiChooseYourGroup.
  ///
  /// In ru, this message translates to:
  /// **'Укажи\nсвою группу'**
  String get uiChooseYourGroup;

  /// No description provided for @uiSignInWithYourVgspuPortalAccountYour.
  ///
  /// In ru, this message translates to:
  /// **'Войди с аккаунтом портала ВГСПУ. ФИО нужно, чтобы найти твоё расписание.'**
  String get uiSignInWithYourVgspuPortalAccountYour;

  /// No description provided for @uiUseYourPortalUsernameAndPassword.
  ///
  /// In ru, this message translates to:
  /// **'Используй свой логин и пароль от портала {p0}.'**
  String uiUseYourPortalUsernameAndPassword(String p0);

  /// No description provided for @uiChooseAGroupAndPlanYourDayNo.
  ///
  /// In ru, this message translates to:
  /// **'Выбери группу — и можно планировать день. Пароль университета не нужен.'**
  String get uiChooseAGroupAndPlanYourDayNo;

  /// No description provided for @uiEnterYourGroupCodeAndPlanYourDay.
  ///
  /// In ru, this message translates to:
  /// **'Укажи номер группы — и можно планировать день. Подключить портал получится позже.'**
  String get uiEnterYourGroupCodeAndPlanYourDay;

  /// No description provided for @uiTeacherSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Вход преподавателя'**
  String get uiTeacherSignIn;

  /// No description provided for @uiFullName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия, имя и отчество'**
  String get uiFullName;

  /// No description provided for @uiShowPassword.
  ///
  /// In ru, this message translates to:
  /// **'Показать пароль'**
  String get uiShowPassword;

  /// No description provided for @uiHidePassword.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть пароль'**
  String get uiHidePassword;

  /// No description provided for @uiYourUsernameAndPasswordAreStoredSecurelyOn.
  ///
  /// In ru, this message translates to:
  /// **'Логин и пароль сохраняются защищённо на этом устройстве.'**
  String get uiYourUsernameAndPasswordAreStoredSecurelyOn;

  /// No description provided for @uiNoPortalUsernameOrPasswordNeeded.
  ///
  /// In ru, this message translates to:
  /// **'Без логина и пароля от портала.'**
  String get uiNoPortalUsernameOrPasswordNeeded;

  /// No description provided for @uiToday330.
  ///
  /// In ru, this message translates to:
  /// **'СЕГОДНЯ'**
  String get uiToday330;

  /// No description provided for @uiToday331.
  ///
  /// In ru, this message translates to:
  /// **'· Сегодня'**
  String get uiToday331;

  /// No description provided for @uiNoClasses.
  ///
  /// In ru, this message translates to:
  /// **'Пар нет'**
  String get uiNoClasses;

  /// No description provided for @uiNoClassesTakeABreak.
  ///
  /// In ru, this message translates to:
  /// **'Пар нет — можно выдохнуть'**
  String get uiNoClassesTakeABreak;

  /// No description provided for @uiChooseAnotherDayToViewItsSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой день, чтобы посмотреть расписание.'**
  String get uiChooseAnotherDayToViewItsSchedule;

  /// No description provided for @uiGroupListCurrentlyUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Список групп пока недоступен'**
  String get uiGroupListCurrentlyUnavailable;

  /// No description provided for @uiCouldNotCheckTheGroupListPleaseTry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить список групп. Попробуйте ещё раз.'**
  String get uiCouldNotCheckTheGroupListPleaseTry;

  /// No description provided for @uiGroupCode.
  ///
  /// In ru, this message translates to:
  /// **'Номер группы'**
  String get uiGroupCode;

  /// No description provided for @uiStartTypingAGroupCodeOrNumber.
  ///
  /// In ru, this message translates to:
  /// **'Начните вводить код или номер'**
  String get uiStartTypingAGroupCodeOrNumber;

  /// No description provided for @uiLoadingGroups.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем группы…'**
  String get uiLoadingGroups;

  /// No description provided for @uiTryAgain340.
  ///
  /// In ru, this message translates to:
  /// **'{p0}. Повторить'**
  String uiTryAgain340(String p0);

  /// No description provided for @uiGroupNotFoundCheckTheCodeOrEnter.
  ///
  /// In ru, this message translates to:
  /// **'Группа не найдена. Проверьте код или введите только номер.'**
  String get uiGroupNotFoundCheckTheCodeOrEnter;

  /// No description provided for @uiHowToViewYourSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Как смотреть\nрасписание'**
  String get uiHowToViewYourSchedule;

  /// No description provided for @uiChooseADayOnTheScheduleTimesAre.
  ///
  /// In ru, this message translates to:
  /// **'Выбирай день в карточке расписания. Время — слева, рядом — предмет и аудитория. Нажми на пару, чтобы открыть её.'**
  String get uiChooseADayOnTheScheduleTimesAre;

  /// No description provided for @uiHowToSwitchWeeks.
  ///
  /// In ru, this message translates to:
  /// **'Как сменить\nнеделю'**
  String get uiHowToSwitchWeeks;

  /// No description provided for @uiSwipeLeftForNextWeekAndRightFor.
  ///
  /// In ru, this message translates to:
  /// **'Свайп влево открывает следующую неделю, вправо — возвращает текущую. Кнопка над расписанием делает то же самое. Сохранённые пары доступны без сети.'**
  String get uiSwipeLeftForNextWeekAndRightFor;

  /// No description provided for @uiHowToAddHomework.
  ///
  /// In ru, this message translates to:
  /// **'Как записать ДЗ'**
  String get uiHowToAddHomework;

  /// No description provided for @uiOpenAClassWriteDownHomeworkOrAn.
  ///
  /// In ru, this message translates to:
  /// **'Открой пару, запиши домашнее задание или важную мысль и нажми «Сохранить». Запись привязана к этому занятию.'**
  String get uiOpenAClassWriteDownHomeworkOrAn;

  /// No description provided for @uiHowToAddPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Как добавить фото'**
  String get uiHowToAddPhotos;

  /// No description provided for @uiScrollTheActionBarToAddPhotosFrom.
  ///
  /// In ru, this message translates to:
  /// **'Листай панель действий, чтобы добавить фото из галереи или с камеры. Заметки и фотографии хранятся на устройстве: удаление приложения удалит и их.'**
  String get uiScrollTheActionBarToAddPhotosFrom;

  /// No description provided for @uiHowToRequestACertificate.
  ///
  /// In ru, this message translates to:
  /// **'Как заказать справку'**
  String get uiHowToRequestACertificate;

  /// No description provided for @uiOpenUniversitySubmitAnApplicationAndSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Открой «Университет» → «Подать заявление» и войди через портал. Выбери документ. Пока статус «Новое», портал ещё готовит форму.'**
  String get uiOpenUniversitySubmitAnApplicationAndSignIn;

  /// No description provided for @uiFillingOutAnApplication.
  ///
  /// In ru, this message translates to:
  /// **'Заполнение заявления'**
  String get uiFillingOutAnApplication;

  /// No description provided for @uiWhenOpenFormAppearsOpenTheApplicationAfter.
  ///
  /// In ru, this message translates to:
  /// **'Когда появится «Перейти к заполнению», открой форму. После отправки проверяй статус здесь. Пуш-уведомления можно включить в настройках; проверка бывает с задержкой.'**
  String get uiWhenOpenFormAppearsOpenTheApplicationAfter;

  /// No description provided for @uiRooms.
  ///
  /// In ru, this message translates to:
  /// **'Аудитории'**
  String get uiRooms;

  /// No description provided for @uiFindARoom.
  ///
  /// In ru, this message translates to:
  /// **'Поиск аудитории'**
  String get uiFindARoom;

  /// No description provided for @uiOpenAClassAndSelectFindAnAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Открой занятие и выбери «Найти свободную аудиторию» в панели действий. Поиск использует дату и время этой пары.'**
  String get uiOpenAClassAndSelectFindAnAvailable;

  /// No description provided for @uiWhatTheSearchShows.
  ///
  /// In ru, this message translates to:
  /// **'Что показывает поиск'**
  String get uiWhatTheSearchShows;

  /// No description provided for @uiUnioOnlyChecksTheSchedulesItKnowsA.
  ///
  /// In ru, this message translates to:
  /// **'UNIO проверяет только известные ему расписания. Найденная аудитория не забронирована: перед занятием уточни, свободна ли она на самом деле.'**
  String get uiUnioOnlyChecksTheSchedulesItKnowsA;

  /// No description provided for @uiTeacherSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск преподавателя'**
  String get uiTeacherSearch;

  /// No description provided for @uiOpenTeachersInTheUniversityTabEnterAt.
  ///
  /// In ru, this message translates to:
  /// **'Во вкладке «Университет» открой «Преподаватели». Введи хотя бы две буквы фамилии и выбери нужное полное имя.'**
  String get uiOpenTeachersInTheUniversityTabEnterAt;

  /// No description provided for @uiClassesAndRooms.
  ///
  /// In ru, this message translates to:
  /// **'Занятия и аудитории'**
  String get uiClassesAndRooms;

  /// No description provided for @uiATeacherSCardShowsClassesAndRooms.
  ///
  /// In ru, this message translates to:
  /// **'В карточке преподавателя есть занятия и аудитории. Это план, а не отслеживание человека: расписание не подтверждает его присутствие в вузе.'**
  String get uiATeacherSCardShowsClassesAndRooms;

  /// No description provided for @uiGettingStarted.
  ///
  /// In ru, this message translates to:
  /// **'Первое знакомство'**
  String get uiGettingStarted;

  /// No description provided for @uiCloseGuide.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть гайд'**
  String get uiCloseGuide;

  /// No description provided for @uiAppGuide.
  ///
  /// In ru, this message translates to:
  /// **'ГАЙД ПО ПРИЛОЖЕНИЮ'**
  String get uiAppGuide;

  /// No description provided for @uiGotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get uiGotIt;

  /// No description provided for @uiExample.
  ///
  /// In ru, this message translates to:
  /// **'ПРИМЕР · {p0}'**
  String uiExample(String p0);

  /// No description provided for @uiMon.
  ///
  /// In ru, this message translates to:
  /// **'ПН'**
  String get uiMon;

  /// No description provided for @uiTue.
  ///
  /// In ru, this message translates to:
  /// **'ВТ'**
  String get uiTue;

  /// No description provided for @uiWed.
  ///
  /// In ru, this message translates to:
  /// **'СР'**
  String get uiWed;

  /// No description provided for @uiThu.
  ///
  /// In ru, this message translates to:
  /// **'ЧТ'**
  String get uiThu;

  /// No description provided for @uiFri.
  ///
  /// In ru, this message translates to:
  /// **'ПТ'**
  String get uiFri;

  /// No description provided for @uiForeignLanguage.
  ///
  /// In ru, this message translates to:
  /// **'10:10 · Иностранный язык'**
  String get uiForeignLanguage;

  /// No description provided for @uiRoom374.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория 314'**
  String get uiRoom374;

  /// No description provided for @uiPedagogy.
  ///
  /// In ru, this message translates to:
  /// **'11:50 · Педагогика'**
  String get uiPedagogy;

  /// No description provided for @uiRoom376.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория 208'**
  String get uiRoom376;

  /// No description provided for @uiSwipeLeft.
  ///
  /// In ru, this message translates to:
  /// **'Свайп влево'**
  String get uiSwipeLeft;

  /// No description provided for @uiReadChapter.
  ///
  /// In ru, this message translates to:
  /// **'Прочитать главу 3'**
  String get uiReadChapter;

  /// No description provided for @uiAssignmentForTheNextClass.
  ///
  /// In ru, this message translates to:
  /// **'Задание к следующей паре'**
  String get uiAssignmentForTheNextClass;

  /// No description provided for @uiNew.
  ///
  /// In ru, this message translates to:
  /// **'Новое'**
  String get uiNew;

  /// No description provided for @uiThePortalIsPreparingTheForm.
  ///
  /// In ru, this message translates to:
  /// **'Портал готовит форму'**
  String get uiThePortalIsPreparingTheForm;

  /// No description provided for @uiOpenForm.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к заполнению'**
  String get uiOpenForm;

  /// No description provided for @uiYouCanOpenTheApplication.
  ///
  /// In ru, this message translates to:
  /// **'Можно открыть заявление'**
  String get uiYouCanOpenTheApplication;

  /// No description provided for @uiUniversityResponse.
  ///
  /// In ru, this message translates to:
  /// **'Ответ университета'**
  String get uiUniversityResponse;

  /// No description provided for @uiTheStatusWillAppearInTheList.
  ///
  /// In ru, this message translates to:
  /// **'Статус появится в списке'**
  String get uiTheStatusWillAppearInTheList;

  /// No description provided for @uiSelectedClassTime.
  ///
  /// In ru, this message translates to:
  /// **'Время выбранного занятия'**
  String get uiSelectedClassTime;

  /// No description provided for @uiBasedOnKnownSchedules.
  ///
  /// In ru, this message translates to:
  /// **'По известным расписаниям'**
  String get uiBasedOnKnownSchedules;

  /// No description provided for @uiSearchBySurname.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по фамилии'**
  String get uiSearchBySurname;

  /// No description provided for @uiChooseTheFullName.
  ///
  /// In ru, this message translates to:
  /// **'Выбери полное имя'**
  String get uiChooseTheFullName;

  /// No description provided for @uiTeacherDetails.
  ///
  /// In ru, this message translates to:
  /// **'Карточка преподавателя'**
  String get uiTeacherDetails;

  /// No description provided for @uiTodayAndOtherDays.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня и другие дни'**
  String get uiTodayAndOtherDays;

  /// No description provided for @uiRoomAndTime.
  ///
  /// In ru, this message translates to:
  /// **'Аудитория и время'**
  String get uiRoomAndTime;

  /// No description provided for @uiFromTheClassSchedule.
  ///
  /// In ru, this message translates to:
  /// **'По плану занятий'**
  String get uiFromTheClassSchedule;

  /// No description provided for @uiConfirmInTheAndroidDialogTheWidgetWill.
  ///
  /// In ru, this message translates to:
  /// **'Подтверди добавление в окне Android. Виджет появится на рабочем столе.'**
  String get uiConfirmInTheAndroidDialogTheWidgetWill;

  /// No description provided for @uiTouchAndHoldAnEmptyAreaOnYour.
  ///
  /// In ru, this message translates to:
  /// **'Зажми пустое место на рабочем столе → «Виджеты» → UNIO.'**
  String get uiTouchAndHoldAnEmptyAreaOnYour;

  /// No description provided for @uiYourScheduleAtHand.
  ///
  /// In ru, this message translates to:
  /// **'Расписание под рукой'**
  String get uiYourScheduleAtHand;

  /// No description provided for @uiYourNextClassAndRoomRightOnYour.
  ///
  /// In ru, this message translates to:
  /// **'Ближайшая пара и аудитория — прямо на рабочем столе.'**
  String get uiYourNextClassAndRoomRightOnYour;

  /// No description provided for @uiNextClassToday.
  ///
  /// In ru, this message translates to:
  /// **'СЛЕДУЮЩАЯ ПАРА · СЕГОДНЯ'**
  String get uiNextClassToday;

  /// No description provided for @uiForeignLanguage399.
  ///
  /// In ru, this message translates to:
  /// **'Иностранный язык'**
  String get uiForeignLanguage399;

  /// No description provided for @uiPracticalRoom.
  ///
  /// In ru, this message translates to:
  /// **'Практика · Ауд. 0439'**
  String get uiPracticalRoom;

  /// No description provided for @uiYourDayYourPace.
  ///
  /// In ru, this message translates to:
  /// **'Твой день — в твоём ритме'**
  String get uiYourDayYourPace;

  /// No description provided for @uiDesignPreviewTheWidgetWillShowYourSelected.
  ///
  /// In ru, this message translates to:
  /// **'Пример оформления. Виджет покажет выбранное расписание и будет открывать UNIO по нажатию.'**
  String get uiDesignPreviewTheWidgetWillShowYourSelected;

  /// No description provided for @uiAddToHomeScreen.
  ///
  /// In ru, this message translates to:
  /// **'Добавить на рабочий стол'**
  String get uiAddToHomeScreen;

  /// No description provided for @uiRoom404.
  ///
  /// In ru, this message translates to:
  /// **'  •  Ауд. {p0}'**
  String uiRoom404(String p0);

  /// No description provided for @uiGroup405.
  ///
  /// In ru, this message translates to:
  /// **'Группа: {p0}'**
  String uiGroup405(String p0);

  /// No description provided for @uiLoadingTodaySClasses.
  ///
  /// In ru, this message translates to:
  /// **'Загружаем пары на сегодня…'**
  String get uiLoadingTodaySClasses;

  /// No description provided for @uiTodaySScheduleHasNotLoaded.
  ///
  /// In ru, this message translates to:
  /// **'Расписание на сегодня не загружено'**
  String get uiTodaySScheduleHasNotLoaded;

  /// No description provided for @uiTapToTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы повторить'**
  String get uiTapToTryAgain;

  /// No description provided for @uiNoScheduleFoundForThisWeek409.
  ///
  /// In ru, this message translates to:
  /// **'Расписание на эту неделю не найдено'**
  String get uiNoScheduleFoundForThisWeek409;

  /// No description provided for @uiTapToRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы обновить'**
  String get uiTapToRefresh;

  /// No description provided for @uiTimesForUpcomingClassesAreNotSpecified411.
  ///
  /// In ru, this message translates to:
  /// **'Время следующих пар не указано'**
  String get uiTimesForUpcomingClassesAreNotSpecified411;

  /// No description provided for @uiNoMoreClassesToday412.
  ///
  /// In ru, this message translates to:
  /// **'Следующих пар сегодня нет'**
  String get uiNoMoreClassesToday412;

  /// No description provided for @uiNoClassesTodayEnjoyYourBreak.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня без пар — отдыхай ☕'**
  String get uiNoClassesTodayEnjoyYourBreak;

  /// No description provided for @uiNextClassTodayGoToThisClassIn.
  ///
  /// In ru, this message translates to:
  /// **'Следующая пара сегодня: {p0}, {p1}–{p2}{p3}. Перейти к паре в расписании.'**
  String uiNextClassTodayGoToThisClassIn(
      String p0, String p1, String p2, String p3);

  /// No description provided for @uiNextClassToday415.
  ///
  /// In ru, this message translates to:
  /// **'Следующая пара · сегодня'**
  String get uiNextClassToday415;

  /// No description provided for @uiStartsIn.
  ///
  /// In ru, this message translates to:
  /// **'До начала'**
  String get uiStartsIn;

  /// No description provided for @uiYourDay.
  ///
  /// In ru, this message translates to:
  /// **'Твой день'**
  String get uiYourDay;

  /// No description provided for @uiTheScheduleForOtherDaysIsBelow.
  ///
  /// In ru, this message translates to:
  /// **'Расписание на другие дни — ниже.'**
  String get uiTheScheduleForOtherDaysIsBelow;

  /// No description provided for @uiClassPhotos.
  ///
  /// In ru, this message translates to:
  /// **'Фото к паре'**
  String get uiClassPhotos;

  /// No description provided for @uiPreviousPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Предыдущее фото'**
  String get uiPreviousPhoto;

  /// No description provided for @uiNextPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Следующее фото'**
  String get uiNextPhoto;

  /// No description provided for @uiCouldNotOpenPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть фотографию'**
  String get uiCouldNotOpenPhoto;

  /// No description provided for @uiPhoto.
  ///
  /// In ru, this message translates to:
  /// **'Фото {p0}'**
  String uiPhoto(String p0);

  /// No description provided for @uiRemovePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Убрать фото'**
  String get uiRemovePhoto;

  /// No description provided for @uiUniversityServices.
  ///
  /// In ru, this message translates to:
  /// **'Сервисы университета'**
  String get uiUniversityServices;

  /// No description provided for @uiViaThePortalRightInUnio.
  ///
  /// In ru, this message translates to:
  /// **'{p0} через портал {p1} — прямо в UNIO.'**
  String uiViaThePortalRightInUnio(String p0, String p1);

  /// No description provided for @uiPortalSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Нужен вход через портал'**
  String get uiPortalSignInRequired;

  /// No description provided for @uiUseYourUniversityAccountToOpenThisSection.
  ///
  /// In ru, this message translates to:
  /// **'Используйте учётную запись университета, чтобы открыть этот раздел.'**
  String get uiUseYourUniversityAccountToOpenThisSection;

  /// No description provided for @uiAvailableAfterSigningInViaThePortalGuest.
  ///
  /// In ru, this message translates to:
  /// **'Доступно после входа через портал {p0} — в гостевом режиме доступно только расписание'**
  String uiAvailableAfterSigningInViaThePortalGuest(String p0);

  /// No description provided for @uiUnioOnYourHomeScreen.
  ///
  /// In ru, this message translates to:
  /// **'UNIO на главном экране'**
  String get uiUnioOnYourHomeScreen;

  /// No description provided for @uiOnIphoneOpenUnioInSafariTapShare.
  ///
  /// In ru, this message translates to:
  /// **'На iPhone: откройте UNIO в Safari, нажмите «Поделиться» → «На экран Домой». Если есть переключатель «Открывать как веб-приложение», включите его.\n\nНа Android и компьютере: откройте меню браузера и выберите «Установить приложение» или «Добавить на главный экран».\n\nПосле первой загрузки доступны сохранённые расписания и заметки. Для новых данных нужен интернет. Очистка данных сайта удаляет локальные заметки и вход.'**
  String get uiOnIphoneOpenUnioInSafariTapShare;

  /// No description provided for @uiThePortalIsPreparingYourForm.
  ///
  /// In ru, this message translates to:
  /// **'Портал готовит форму для заполнения'**
  String get uiThePortalIsPreparingYourForm;

  /// No description provided for @uiSubjects.
  ///
  /// In ru, this message translates to:
  /// **'Предметы'**
  String get uiSubjects;

  /// No description provided for @uiSemester445.
  ///
  /// In ru, this message translates to:
  /// **'Семестр {p0}'**
  String uiSemester445(String p0);

  /// No description provided for @uiNoResultYet.
  ///
  /// In ru, this message translates to:
  /// **'Результат пока не указан'**
  String get uiNoResultYet;

  /// No description provided for @uiPts.
  ///
  /// In ru, this message translates to:
  /// **'{p0} б.'**
  String uiPts(String p0);

  /// No description provided for @uiCheckpointsAndAbsences.
  ///
  /// In ru, this message translates to:
  /// **'Срезы и пропуски'**
  String get uiCheckpointsAndAbsences;

  /// No description provided for @uiCheckpoint.
  ///
  /// In ru, this message translates to:
  /// **'{p0} срез'**
  String uiCheckpoint(String p0);

  /// No description provided for @uiMissedH.
  ///
  /// In ru, this message translates to:
  /// **'Пропуски: {p0} ч.'**
  String uiMissedH(String p0);

  /// No description provided for @uiLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка'**
  String get uiLoading;

  /// No description provided for @uiRefreshing.
  ///
  /// In ru, this message translates to:
  /// **'Обновление'**
  String get uiRefreshing;

  /// No description provided for @uiSat.
  ///
  /// In ru, this message translates to:
  /// **'СБ'**
  String get uiSat;

  /// No description provided for @uiSun.
  ///
  /// In ru, this message translates to:
  /// **'ВС'**
  String get uiSun;

  /// No description provided for @uiPullDownToRefreshTheSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Потяните вниз, чтобы обновить расписание.'**
  String get uiPullDownToRefreshTheSchedule;

  /// No description provided for @uiClassesForTheWeek.
  ///
  /// In ru, this message translates to:
  /// **'Пары на неделю'**
  String get uiClassesForTheWeek;

  /// No description provided for @uiAlwaysNearby.
  ///
  /// In ru, this message translates to:
  /// **'Всегда рядом'**
  String get uiAlwaysNearby;

  /// No description provided for @uiForYourStudies470.
  ///
  /// In ru, this message translates to:
  /// **'Для учёбы'**
  String get uiForYourStudies470;

  /// No description provided for @uiYourDay471.
  ///
  /// In ru, this message translates to:
  /// **'ТВОЙ ДЕНЬ'**
  String get uiYourDay471;

  /// No description provided for @uiPedagogy472.
  ///
  /// In ru, this message translates to:
  /// **'Педагогика'**
  String get uiPedagogy472;

  /// No description provided for @uiEvenOffline.
  ///
  /// In ru, this message translates to:
  /// **'Даже без сети'**
  String get uiEvenOffline;

  /// No description provided for @uiEnrolmentCertificate.
  ///
  /// In ru, this message translates to:
  /// **'Справка об обучении'**
  String get uiEnrolmentCertificate;

  /// No description provided for @uiApplicationSubmitted.
  ///
  /// In ru, this message translates to:
  /// **'Заявление отправлено'**
  String get uiApplicationSubmitted;

  /// No description provided for @uiSubmittedInProgressReady.
  ///
  /// In ru, this message translates to:
  /// **'Отправлено → В работе → Готово'**
  String get uiSubmittedInProgressReady;

  /// No description provided for @uiCertificateReady.
  ///
  /// In ru, this message translates to:
  /// **'Справка готова'**
  String get uiCertificateReady;

  /// No description provided for @uiReadyToCollect.
  ///
  /// In ru, this message translates to:
  /// **'Можно забирать'**
  String get uiReadyToCollect;

  /// No description provided for @uiTeacherClassSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Преподаватель\nРасписание занятий'**
  String get uiTeacherClassSchedule;

  /// No description provided for @uiNextClassRoom.
  ///
  /// In ru, this message translates to:
  /// **'Следующая пара · ауд. 314'**
  String get uiNextClassRoom;

  /// No description provided for @uiEssentialsAtHand.
  ///
  /// In ru, this message translates to:
  /// **'Важное — под рукой'**
  String get uiEssentialsAtHand;

  /// No description provided for @uiClassNotes.
  ///
  /// In ru, this message translates to:
  /// **'Заметки к занятиям'**
  String get uiClassNotes;

  /// No description provided for @uiTheServerHasConfirmedDeletionAndSignOut.
  ///
  /// In ru, this message translates to:
  /// **'Запросы удаления и выхода подтверждены сервером.'**
  String get uiTheServerHasConfirmedDeletionAndSignOut;

  /// No description provided for @uiTheServerRequestIsStillWaitingForA.
  ///
  /// In ru, this message translates to:
  /// **'Запрос к серверу ещё ожидает сети. Не удаляйте приложение до подтверждения.'**
  String get uiTheServerRequestIsStillWaitingForA;

  /// No description provided for @uiPleaseAcceptTheDocumentsToSignInAnalytics.
  ///
  /// In ru, this message translates to:
  /// **'Для входа нужно принять документы. Аналитика необязательна.'**
  String get uiPleaseAcceptTheDocumentsToSignInAnalytics;

  /// No description provided for @uiCleanupIsIncompleteWeWillRetryOnThe.
  ///
  /// In ru, this message translates to:
  /// **'Очистка не завершена. Повторим при следующем запуске. Не удаляйте приложение до подтверждения.'**
  String get uiCleanupIsIncompleteWeWillRetryOnThe;

  /// No description provided for @uiYouAreSignedOutTheServerRequestIs.
  ///
  /// In ru, this message translates to:
  /// **'Вы вышли. Запрос на сервер ожидает сети — откройте приложение с интернетом.'**
  String get uiYouAreSignedOutTheServerRequestIs;

  /// No description provided for @uiYourUnioAccountAndLocalDataHaveBeen.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт UNIO и локальные данные удалены.'**
  String get uiYourUnioAccountAndLocalDataHaveBeen;

  /// No description provided for @uiYouHaveSignedOut.
  ///
  /// In ru, this message translates to:
  /// **'Вы вышли из аккаунта.'**
  String get uiYouHaveSignedOut;

  /// No description provided for @uiMonday.
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get uiMonday;

  /// No description provided for @uiTuesday.
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get uiTuesday;

  /// No description provided for @uiWednesday.
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get uiWednesday;

  /// No description provided for @uiThursday.
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get uiThursday;

  /// No description provided for @uiFriday.
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get uiFriday;

  /// No description provided for @uiSaturday.
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get uiSaturday;

  /// No description provided for @uiSunday.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get uiSunday;

  /// No description provided for @uiClass497.
  ///
  /// In ru, this message translates to:
  /// **'пара'**
  String get uiClass497;

  /// No description provided for @uiClasses.
  ///
  /// In ru, this message translates to:
  /// **'пары'**
  String get uiClasses;

  /// No description provided for @uiClasses499.
  ///
  /// In ru, this message translates to:
  /// **'пар'**
  String get uiClasses499;

  /// No description provided for @uiCouldNotConnectCheckYourInternetConnectionAnd.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться. Проверьте интернет и попробуйте ещё раз.'**
  String get uiCouldNotConnectCheckYourInternetConnectionAnd;

  /// No description provided for @uiTheServiceIsTemporarilyUnavailablePleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Сервис временно недоступен. Попробуйте чуть позже.'**
  String get uiTheServiceIsTemporarilyUnavailablePleaseTryAgain;

  /// No description provided for @uiCouldNotCompleteThisActionPleaseTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить действие. Попробуйте ещё раз.'**
  String get uiCouldNotCompleteThisActionPleaseTryAgain;

  /// No description provided for @uiSignInAgainAndRetryThisAction.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт заново и повторите действие.'**
  String get uiSignInAgainAndRetryThisAction;

  /// No description provided for @uiThisActionIsCurrentlyUnavailableForYourAccount.
  ///
  /// In ru, this message translates to:
  /// **'Это действие сейчас недоступно для вашего аккаунта.'**
  String get uiThisActionIsCurrentlyUnavailableForYourAccount;

  /// No description provided for @uiCouldNotFindTheRequestedDataTryRefreshing.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти запрошенные данные. Попробуйте обновить экран.'**
  String get uiCouldNotFindTheRequestedDataTryRefreshing;

  /// No description provided for @uiCheckYourDetailsAndTryAgain.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте заполненные данные и попробуйте ещё раз.'**
  String get uiCheckYourDetailsAndTryAgain;

  /// No description provided for @uiTheResponseIsTakingLongerThanExpectedPlease.
  ///
  /// In ru, this message translates to:
  /// **'Ответ задерживается. Попробуйте ещё раз чуть позже.'**
  String get uiTheResponseIsTakingLongerThanExpectedPlease;

  /// No description provided for @uiTooManyAttemptsPleaseWaitALittleAnd.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много попыток. Подождите немного и повторите.'**
  String get uiTooManyAttemptsPleaseWaitALittleAnd;

  /// No description provided for @uiThePortalHasRestrictedAccessTryAnotherNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Портал ограничил доступ. Попробуйте другую сеть или откройте портал в браузере. Код REQ_ACCESS.'**
  String get uiThePortalHasRestrictedAccessTryAnotherNetwork;

  /// No description provided for @uiCouldNotLoadTheListTryRefreshingIt.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить список. Попробуйте обновить его позже. Код REQ_EMPTY.'**
  String get uiCouldNotLoadTheListTryRefreshingIt;

  /// No description provided for @uiOpenYourVgspuPortalAccountAnActionMay.
  ///
  /// In ru, this message translates to:
  /// **'Откройте личный кабинет ВГСПУ: возможно, там требуется действие. Если раздел заявлений доступен, сообщите поддержке код REQ_PAGE.'**
  String get uiOpenYourVgspuPortalAccountAnActionMay;

  /// No description provided for @uiCouldNotOpenThePageSecurelyPleaseTry.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось безопасно открыть страницу. Попробуйте позже.'**
  String get uiCouldNotOpenThePageSecurelyPleaseTry;

  /// No description provided for @storyViewed.
  ///
  /// In ru, this message translates to:
  /// **'Просмотрено'**
  String get storyViewed;

  /// No description provided for @open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get open;

  /// No description provided for @draft.
  ///
  /// In ru, this message translates to:
  /// **'Проект'**
  String get draft;

  /// No description provided for @accepted.
  ///
  /// In ru, this message translates to:
  /// **'Принято'**
  String get accepted;

  /// No description provided for @withdrawn.
  ///
  /// In ru, this message translates to:
  /// **'Отозвано'**
  String get withdrawn;

  /// No description provided for @waitingForForm.
  ///
  /// In ru, this message translates to:
  /// **'Подождите ещё немного — получаем информацию от портала. Когда форма будет готова, появится «Перейти к заполнению». Обновите список чуть позже.'**
  String get waitingForForm;

  /// No description provided for @noStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус не указан'**
  String get noStatus;

  /// No description provided for @lecture.
  ///
  /// In ru, this message translates to:
  /// **'Лекция'**
  String get lecture;

  /// No description provided for @practice.
  ///
  /// In ru, this message translates to:
  /// **'Практика'**
  String get practice;

  /// No description provided for @lab.
  ///
  /// In ru, this message translates to:
  /// **'Лабораторная'**
  String get lab;

  /// No description provided for @seminar.
  ///
  /// In ru, this message translates to:
  /// **'Семинар'**
  String get seminar;

  /// No description provided for @consultation.
  ///
  /// In ru, this message translates to:
  /// **'Консультация'**
  String get consultation;

  /// No description provided for @exam.
  ///
  /// In ru, this message translates to:
  /// **'Экзамен'**
  String get exam;

  /// No description provided for @credit.
  ///
  /// In ru, this message translates to:
  /// **'Зачёт'**
  String get credit;

  /// No description provided for @documentsOriginalLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Документы опубликованы на русском языке. Выбор языка интерфейса не меняет их текст.'**
  String get documentsOriginalLanguage;

  /// No description provided for @notesSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в студенческий аккаунт, чтобы открыть заметки.'**
  String get notesSignIn;

  /// No description provided for @notesNoDate.
  ///
  /// In ru, this message translates to:
  /// **'У этой пары не указана дата. Обновите расписание.'**
  String get notesNoDate;

  /// No description provided for @notesWrongOwner.
  ///
  /// In ru, this message translates to:
  /// **'Заметка относится к другому аккаунту.'**
  String get notesWrongOwner;

  /// No description provided for @notesReadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать сохранённую заметку.'**
  String get notesReadFailed;

  /// No description provided for @notesPhotosFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать фотографии заметки.'**
  String get notesPhotosFailed;

  /// No description provided for @photoTooLarge.
  ///
  /// In ru, this message translates to:
  /// **'Фото слишком большое. Выберите изображение до 10 МБ.'**
  String get photoTooLarge;

  /// No description provided for @photoAddFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось добавить фото. Максимальный размер — 10 МБ.'**
  String get photoAddFailed;

  /// No description provided for @notesTextLimit.
  ///
  /// In ru, this message translates to:
  /// **'Можно сохранить до 20 000 символов.'**
  String get notesTextLimit;

  /// No description provided for @photoReadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать фотографию.'**
  String get photoReadFailed;

  /// No description provided for @photoUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Фотография недоступна. Добавьте её ещё раз.'**
  String get photoUnavailable;

  /// No description provided for @photosRecoveryFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить выбранные фото. Добавьте их ещё раз.'**
  String get photosRecoveryFailed;

  /// No description provided for @portalCheckCredentials.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте логин и пароль портала ВГСПУ.'**
  String get portalCheckCredentials;

  /// No description provided for @portalReauthenticate.
  ///
  /// In ru, this message translates to:
  /// **'Портал ВГСПУ завершил авторизацию. Повторите вход через портал в настройках UNIO.'**
  String get portalReauthenticate;

  /// No description provided for @webSignInEnded.
  ///
  /// In ru, this message translates to:
  /// **'Вход в веб-версию завершён. Войдите через портал повторно.'**
  String get webSignInEnded;

  /// No description provided for @webConfigMissing.
  ///
  /// In ru, this message translates to:
  /// **'Веб-доступ к порталу ещё не настроен. Сообщите поддержке код WEB_CONFIG.'**
  String get webConfigMissing;

  /// No description provided for @attachmentLimit.
  ///
  /// In ru, this message translates to:
  /// **'Выберите вложение размером до 20 МБ.'**
  String get attachmentLimit;

  /// No description provided for @chooseSuggestedGroup.
  ///
  /// In ru, this message translates to:
  /// **'Выберите группу из подсказок.'**
  String get chooseSuggestedGroup;

  /// No description provided for @tooManyRequests.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много запросов. Попробуйте немного позже.'**
  String get tooManyRequests;

  /// No description provided for @portalConnectionFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось связаться с порталом. Попробуйте ещё раз.'**
  String get portalConnectionFailed;

  /// No description provided for @checkInternet.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться. Проверьте интернет.'**
  String get checkInternet;

  /// No description provided for @refreshSignInFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить вход. Повторите действие.'**
  String get refreshSignInFailed;

  /// No description provided for @portalOtherSite.
  ///
  /// In ru, this message translates to:
  /// **'Портал предложил переход на другой сайт.'**
  String get portalOtherSite;

  /// No description provided for @portalNoRedirect.
  ///
  /// In ru, this message translates to:
  /// **'Портал не вернул адрес перехода.'**
  String get portalNoRedirect;

  /// No description provided for @portalUploadRedirect.
  ///
  /// In ru, this message translates to:
  /// **'Портал перенаправил загрузку файла. Обновите заявление и проверьте вложение.'**
  String get portalUploadRedirect;

  /// No description provided for @portalTooManyRedirects.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много перенаправлений портала.'**
  String get portalTooManyRedirects;

  /// No description provided for @operationSignIn.
  ///
  /// In ru, this message translates to:
  /// **'Вход в портал'**
  String get operationSignIn;

  /// No description provided for @operationDraft.
  ///
  /// In ru, this message translates to:
  /// **'Создание черновика'**
  String get operationDraft;

  /// No description provided for @operationTypes.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка видов заявлений'**
  String get operationTypes;

  /// No description provided for @operationRequests.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка списка заявлений'**
  String get operationRequests;

  /// No description provided for @operationSubmit.
  ///
  /// In ru, this message translates to:
  /// **'Отправка заявления'**
  String get operationSubmit;

  /// No description provided for @operationForm.
  ///
  /// In ru, this message translates to:
  /// **'Открытие формы'**
  String get operationForm;

  /// No description provided for @operationPortal.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка страницы портала'**
  String get operationPortal;

  /// No description provided for @portalCsrfRejected.
  ///
  /// In ru, this message translates to:
  /// **'портал не принял защитный токен формы'**
  String get portalCsrfRejected;

  /// No description provided for @portalNeedsSignIn.
  ///
  /// In ru, this message translates to:
  /// **'портал требует повторного входа'**
  String get portalNeedsSignIn;

  /// No description provided for @portalDenied.
  ///
  /// In ru, this message translates to:
  /// **'портал отказал в доступе'**
  String get portalDenied;

  /// No description provided for @portalNoResponse.
  ///
  /// In ru, this message translates to:
  /// **'ответ не получен; проверьте соединение'**
  String get portalNoResponse;

  /// No description provided for @portalError.
  ///
  /// In ru, this message translates to:
  /// **'портал вернул ошибку'**
  String get portalError;

  /// No description provided for @portalSessionExpired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия портала истекла. Войдите через портал заново.'**
  String get portalSessionExpired;

  /// No description provided for @portalSignInFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти в портал. Проверьте логин и пароль; возможно, портал требует дополнительного подтверждения.'**
  String get portalSignInFailed;

  /// No description provided for @portalSignInRequired.
  ///
  /// In ru, this message translates to:
  /// **'Войдите через портал ВГСПУ, чтобы продолжить.'**
  String get portalSignInRequired;

  /// No description provided for @tooManyRequestPages.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много страниц заявлений. Откройте портал для полного списка.'**
  String get tooManyRequestPages;

  /// No description provided for @typesNotReturned.
  ///
  /// In ru, this message translates to:
  /// **'Портал не вернул типы заявлений. Попробуйте войти заново.'**
  String get typesNotReturned;

  /// No description provided for @typesLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить типы заявлений.'**
  String get typesLoadFailed;

  /// No description provided for @invalidRequestId.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный номер заявления.'**
  String get invalidRequestId;

  /// No description provided for @formNotFillable.
  ///
  /// In ru, this message translates to:
  /// **'Заполнение сейчас недоступно. Вернитесь к списку и обновите статус заявления.'**
  String get formNotFillable;

  /// No description provided for @typeNoLongerAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Этот тип заявления больше недоступен. Выберите другой.'**
  String get typeNoLongerAvailable;

  /// No description provided for @draftNotConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Портал не подтвердил создание. Обновите список перед повторной попыткой.'**
  String get draftNotConfirmed;

  /// No description provided for @fieldRequired.
  ///
  /// In ru, this message translates to:
  /// **'Заполните это поле'**
  String get fieldRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте адрес электронной почты'**
  String get emailInvalid;

  /// No description provided for @dateInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Укажите дату в формате ДД.ММ.ГГГГ'**
  String get dateInvalid;

  /// No description provided for @periodInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Конец периода должен быть не раньше начала'**
  String get periodInvalid;

  /// No description provided for @positiveIntegerRequired.
  ///
  /// In ru, this message translates to:
  /// **'Укажите целое число больше нуля'**
  String get positiveIntegerRequired;

  /// No description provided for @formPortalOnly.
  ///
  /// In ru, this message translates to:
  /// **'Эту форму нельзя отправить из приложения. Откройте её на портале.'**
  String get formPortalOnly;

  /// No description provided for @checkFields.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте заполнение'**
  String get checkFields;

  /// No description provided for @checkAttachments.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте вложения'**
  String get checkAttachments;

  /// No description provided for @fileRejected.
  ///
  /// In ru, this message translates to:
  /// **'Файл не принят порталом. Заявление не отправлено.'**
  String get fileRejected;

  /// No description provided for @checkAttachmentFormat.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте формат и размер вложения и повторите попытку.'**
  String get checkAttachmentFormat;

  /// No description provided for @portalCorrectForm.
  ///
  /// In ru, this message translates to:
  /// **'Портал просит исправить заявление'**
  String get portalCorrectForm;

  /// No description provided for @submissionPending.
  ///
  /// In ru, this message translates to:
  /// **'Запрос отправлен, но портал пока не подтвердил новый статус. Обновите список заявлений перед повторной отправкой.'**
  String get submissionPending;

  /// No description provided for @groupNotInCatalog.
  ///
  /// In ru, this message translates to:
  /// **'Такой группы нет в каталоге. Выберите свою группу из подсказок.'**
  String get groupNotInCatalog;

  /// No description provided for @groupCheckConnection.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить список групп. Проверьте соединение и попробуйте ещё раз.'**
  String get groupCheckConnection;

  /// No description provided for @groupNotInCatalogShort.
  ///
  /// In ru, this message translates to:
  /// **'Такой группы нет в каталоге. Выберите группу из подсказок.'**
  String get groupNotInCatalogShort;

  /// No description provided for @groupCheckFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить список групп. Попробуйте ещё раз.'**
  String get groupCheckFailed;

  /// No description provided for @signInIncomplete.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось завершить вход. Попробуйте ещё раз.'**
  String get signInIncomplete;

  /// No description provided for @fullNameRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите ФИО (от 3 до 255 символов)'**
  String get fullNameRequired;

  /// No description provided for @credentialsRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите логин и пароль от портала ВГСПУ'**
  String get credentialsRequired;

  /// No description provided for @semanticRoomSuffix.
  ///
  /// In ru, this message translates to:
  /// **', аудитория {p0}'**
  String semanticRoomSuffix(String p0);

  /// No description provided for @checkNamedField.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте поле «{p0}».'**
  String checkNamedField(String p0);

  /// No description provided for @invalidNamedFile.
  ///
  /// In ru, this message translates to:
  /// **'Недопустимый файл: {p0}.'**
  String invalidNamedFile(String p0);

  /// No description provided for @portalStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус на портале: {p0}'**
  String portalStatus(String p0);

  /// No description provided for @aiTitle.
  ///
  /// In ru, this message translates to:
  /// **'UNIO AI'**
  String get aiTitle;

  /// No description provided for @aiSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Расписание и документы вуза'**
  String get aiSubtitle;

  /// No description provided for @aiWelcome.
  ///
  /// In ru, this message translates to:
  /// **'Чем могу помочь?'**
  String get aiWelcome;

  /// No description provided for @aiIntro.
  ///
  /// In ru, this message translates to:
  /// **'Найду пары на нужный день и помогу разобраться в документах университета. Ответы по документам — со ссылками на источники.'**
  String get aiIntro;

  /// No description provided for @aiTomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Какое у меня завтра расписание?'**
  String get aiTomorrow;

  /// No description provided for @aiScholarship.
  ///
  /// In ru, this message translates to:
  /// **'Как получить социальную стипендию?'**
  String get aiScholarship;

  /// No description provided for @aiDorm.
  ///
  /// In ru, this message translates to:
  /// **'Как заселиться в общежитие?'**
  String get aiDorm;

  /// No description provided for @aiHint.
  ///
  /// In ru, this message translates to:
  /// **'Не отправляй пароли, документы и личные сведения. Диалог хранится только в памяти приложения до выхода из аккаунта или перезапуска.'**
  String get aiHint;

  /// No description provided for @aiInput.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение…'**
  String get aiInput;

  /// No description provided for @aiSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get aiSend;

  /// No description provided for @aiClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить диалог и сбросить разрешение'**
  String get aiClear;

  /// No description provided for @aiThinking.
  ///
  /// In ru, this message translates to:
  /// **'Проверяю расписание и источники…'**
  String get aiThinking;

  /// No description provided for @aiPrivacyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Перед первым вопросом к документам'**
  String get aiPrivacyTitle;

  /// No description provided for @aiPrivacyBody.
  ///
  /// In ru, this message translates to:
  /// **'Для подготовки ответа UNIO передаст внешнему сервису ИИ текст вопроса, предыдущий вопрос при уточнении и фрагменты публичных материалов. Логин, пароль, токен аккаунта и успеваемость не передаются. Расписание, новости и оценки не требуют обращения к модели. Не вводи персональные данные. Разрешение действует до очистки диалога или выхода; уже переданный вопрос этим не удаляется у получателя.'**
  String get aiPrivacyBody;

  /// No description provided for @aiAllow.
  ///
  /// In ru, this message translates to:
  /// **'Разрешить и отправить вопрос'**
  String get aiAllow;

  /// No description provided for @aiNotNow.
  ///
  /// In ru, this message translates to:
  /// **'Не сейчас'**
  String get aiNotNow;

  /// No description provided for @aiOffTopic.
  ///
  /// In ru, this message translates to:
  /// **'Я помогаю с расписанием и документами университета. Спроси, например, о стипендии или общежитии.'**
  String get aiOffTopic;

  /// No description provided for @aiSensitive.
  ///
  /// In ru, this message translates to:
  /// **'В вопросе могут быть личные данные или секретные значения. Удали их и задай вопрос в общем виде.'**
  String get aiSensitive;

  /// No description provided for @aiInsufficient.
  ///
  /// In ru, this message translates to:
  /// **'В проверенных документах пока недостаточно сведений. Уточни вопрос; если нужный документ ещё не добавлен, ответ лучше проверить в вузе.'**
  String get aiInsufficient;

  /// No description provided for @aiNotConfigured.
  ///
  /// In ru, this message translates to:
  /// **'Помощник ещё подключается на сервере. Попробуй позже.'**
  String get aiNotConfigured;

  /// No description provided for @aiChooseDate.
  ///
  /// In ru, this message translates to:
  /// **'На какой день показать пары? Напиши «сегодня», «завтра», день недели или дату ГГГГ-ММ-ДД.'**
  String get aiChooseDate;

  /// No description provided for @aiDateRange.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас можно проверить расписание в пределах двух недель от сегодняшнего дня.'**
  String get aiDateRange;

  /// No description provided for @aiChooseGroup.
  ///
  /// In ru, this message translates to:
  /// **'Сначала выбери свою группу в расписании.'**
  String get aiChooseGroup;

  /// No description provided for @aiScheduleUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас расписание получить не удалось. Это не означает, что пар нет. Попробуй позже.'**
  String get aiScheduleUnavailable;

  /// No description provided for @aiPermissionRequired.
  ///
  /// In ru, this message translates to:
  /// **'Для ответа по документам нужно разрешить передачу вопроса сервису ИИ. Отправь вопрос ещё раз.'**
  String get aiPermissionRequired;

  /// No description provided for @aiAuthRequired.
  ///
  /// In ru, this message translates to:
  /// **'Сессия UNIO истекла. Войди в аккаунт заново, чтобы продолжить.'**
  String get aiAuthRequired;

  /// No description provided for @aiLimit.
  ///
  /// In ru, this message translates to:
  /// **'Достигнут лимит запросов помощника. Попробуй позже.'**
  String get aiLimit;

  /// No description provided for @aiBusy.
  ///
  /// In ru, this message translates to:
  /// **'Помощник сейчас занят. Попробуй через несколько секунд.'**
  String get aiBusy;

  /// No description provided for @aiUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подготовить ответ. Проверь соединение и попробуй позже.'**
  String get aiUnavailable;

  /// No description provided for @aiNoLessons.
  ///
  /// In ru, this message translates to:
  /// **'На этот день в расписании пар нет.'**
  String get aiNoLessons;

  /// No description provided for @aiScheduleSource.
  ///
  /// In ru, this message translates to:
  /// **'Из сервиса расписания UNIO. Возможны изменения на портале.'**
  String get aiScheduleSource;

  /// No description provided for @aiSourceNotice.
  ///
  /// In ru, this message translates to:
  /// **'Проверь условия в оригинале. Ответ помощника не заменяет решение университета.'**
  String get aiSourceNotice;

  /// No description provided for @aiPage.
  ///
  /// In ru, this message translates to:
  /// **'Страница'**
  String get aiPage;

  /// No description provided for @aiOpenSource.
  ///
  /// In ru, this message translates to:
  /// **'Открыть оригинал'**
  String get aiOpenSource;

  /// No description provided for @aiSearching.
  ///
  /// In ru, this message translates to:
  /// **'Ищу информацию…'**
  String get aiSearching;

  /// No description provided for @aiWriting.
  ///
  /// In ru, this message translates to:
  /// **'Готовлю ответ…'**
  String get aiWriting;

  /// No description provided for @aiLoadingSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Проверяю расписание…'**
  String get aiLoadingSchedule;

  /// No description provided for @aiSources.
  ///
  /// In ru, this message translates to:
  /// **'Источники'**
  String get aiSources;

  /// No description provided for @aiFollowup.
  ///
  /// In ru, this message translates to:
  /// **'Какие документы нужны?'**
  String get aiFollowup;

  /// No description provided for @aiDayAfter.
  ///
  /// In ru, this message translates to:
  /// **'Расписание на послезавтра'**
  String get aiDayAfter;

  /// No description provided for @aiNewsLatest.
  ///
  /// In ru, this message translates to:
  /// **'Вот последние публикации университета.'**
  String get aiNewsLatest;

  /// No description provided for @aiNewsOnDate.
  ///
  /// In ru, this message translates to:
  /// **'Новости за {date}'**
  String aiNewsOnDate(String date);

  /// No description provided for @aiNewsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'В сохранённых новостях нет публикаций за этот день. Можно посмотреть последнюю новость или выбрать другую дату.'**
  String get aiNewsEmpty;

  /// No description provided for @aiNewsChooseDate.
  ///
  /// In ru, this message translates to:
  /// **'За какой день показать новости? Например: «новости за 21 октября 2026» или «новости за вчера».'**
  String get aiNewsChooseDate;

  /// No description provided for @aiNewsUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось загрузить новости. Попробуй ещё раз чуть позже.'**
  String get aiNewsUnavailable;

  /// No description provided for @aiAllNews.
  ///
  /// In ru, this message translates to:
  /// **'Все новости'**
  String get aiAllNews;

  /// No description provided for @aiReadNews.
  ///
  /// In ru, this message translates to:
  /// **'Читать полностью'**
  String get aiReadNews;

  /// No description provided for @aiRequestsHelp.
  ///
  /// In ru, this message translates to:
  /// **'Заказать справку или подать заявление можно на портале ВГСПУ или прямо в UNIO — в разделе «Справки и заявления». Для этого понадобится вход через портал.'**
  String get aiRequestsHelp;

  /// No description provided for @aiOpenPortal.
  ///
  /// In ru, this message translates to:
  /// **'Открыть портал ВГСПУ'**
  String get aiOpenPortal;

  /// No description provided for @aiReferenceNotice.
  ///
  /// In ru, this message translates to:
  /// **'Информация носит справочный характер. ИИ может ошибаться — проверяй важные сведения по официальным источникам. Ответы не заменяют консультацию специалиста, в том числе медицинскую.'**
  String get aiReferenceNotice;

  /// No description provided for @aiLoadingGrades.
  ///
  /// In ru, this message translates to:
  /// **'Проверяю успеваемость…'**
  String get aiLoadingGrades;

  /// No description provided for @aiGradesFromPortal.
  ///
  /// In ru, this message translates to:
  /// **'Данные из раздела «Успеваемость». Баллы по срезам накопительные: складывать их не нужно.'**
  String get aiGradesFromPortal;

  /// No description provided for @aiOpenGrades.
  ///
  /// In ru, this message translates to:
  /// **'Открыть успеваемость'**
  String get aiOpenGrades;

  /// No description provided for @aiGradesAuthRequired.
  ///
  /// In ru, this message translates to:
  /// **'Успеваемость доступна после входа через портал ВГСПУ. Открой раздел и подключи свою учётную запись.'**
  String get aiGradesAuthRequired;

  /// No description provided for @aiGradesUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Не получилось загрузить успеваемость. Попробуй позже или обнови данные в разделе «Успеваемость».'**
  String get aiGradesUnavailable;

  /// No description provided for @aiGradesEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Портал пока не вернул данные об успеваемости. Это не означает, что у тебя нулевые баллы.'**
  String get aiGradesEmpty;

  /// No description provided for @aiGradesNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Не нашёл этот предмет или семестр в твоей успеваемости. Уточни название, например: «Что у меня по русскому языку за 2 семестр?»'**
  String get aiGradesNotFound;

  /// No description provided for @aiHistory.
  ///
  /// In ru, this message translates to:
  /// **'История чатов'**
  String get aiHistory;

  /// No description provided for @aiNewChat.
  ///
  /// In ru, this message translates to:
  /// **'Новый чат'**
  String get aiNewChat;

  /// No description provided for @aiHistorySearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по перепискам'**
  String get aiHistorySearch;

  /// No description provided for @aiHistoryLocal.
  ///
  /// In ru, this message translates to:
  /// **'История сохраняется только на этом устройстве.'**
  String get aiHistoryLocal;

  /// No description provided for @aiHistoryExternal.
  ///
  /// In ru, this message translates to:
  /// **'Вопросы к документам передаются внешнему ИИ-сервису после разрешения.'**
  String get aiHistoryExternal;

  /// No description provided for @aiHistoryEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся твои разговоры'**
  String get aiHistoryEmpty;

  /// No description provided for @aiHistoryNoResults.
  ///
  /// In ru, this message translates to:
  /// **'Переписки не найдены'**
  String get aiHistoryNoResults;

  /// No description provided for @aiRename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get aiRename;

  /// No description provided for @aiDeleteChat.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чат'**
  String get aiDeleteChat;

  /// No description provided for @aiDeleteChatBody.
  ///
  /// In ru, this message translates to:
  /// **'Переписка и связанные карточки будут удалены с этого устройства.'**
  String get aiDeleteChatBody;

  /// No description provided for @aiDeleteHistory.
  ///
  /// In ru, this message translates to:
  /// **'Очистить всю историю'**
  String get aiDeleteHistory;

  /// No description provided for @aiDeleteHistoryBody.
  ///
  /// In ru, this message translates to:
  /// **'Все переписки и черновики этого аккаунта будут удалены с устройства. Отменить это действие нельзя.'**
  String get aiDeleteHistoryBody;

  /// No description provided for @aiCancelAction.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get aiCancelAction;

  /// No description provided for @aiDeleteAction.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get aiDeleteAction;

  /// No description provided for @aiSaveAction.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get aiSaveAction;

  /// No description provided for @aiTodayGroup.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get aiTodayGroup;

  /// No description provided for @aiYesterdayGroup.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get aiYesterdayGroup;

  /// No description provided for @aiWeekGroup.
  ///
  /// In ru, this message translates to:
  /// **'Последние 7 дней'**
  String get aiWeekGroup;

  /// No description provided for @aiEarlierGroup.
  ///
  /// In ru, this message translates to:
  /// **'Ранее'**
  String get aiEarlierGroup;

  /// No description provided for @aiUntitled.
  ///
  /// In ru, this message translates to:
  /// **'Новый разговор'**
  String get aiUntitled;

  /// No description provided for @aiCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get aiCopy;

  /// No description provided for @aiCopied.
  ///
  /// In ru, this message translates to:
  /// **'Ответ скопирован'**
  String get aiCopied;

  /// No description provided for @aiRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get aiRetry;

  /// No description provided for @aiHelpful.
  ///
  /// In ru, this message translates to:
  /// **'Полезно'**
  String get aiHelpful;

  /// No description provided for @aiNotHelpful.
  ///
  /// In ru, this message translates to:
  /// **'Не помогло'**
  String get aiNotHelpful;

  /// No description provided for @aiStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановить ответ'**
  String get aiStop;

  /// No description provided for @aiInterrupted.
  ///
  /// In ru, this message translates to:
  /// **'Ответ прерван. Полученные блоки сохранены; ответ может быть неполным.'**
  String get aiInterrupted;

  /// No description provided for @aiNetworkError.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось связаться с сервером. Проверь подключение и попробуй ещё раз.'**
  String get aiNetworkError;

  /// No description provided for @aiHistoryFailure.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить историю. Сообщения пока доступны только в текущем сеансе. Проверь свободное место и доступ к хранилищу.'**
  String get aiHistoryFailure;

  /// No description provided for @aiHistoryRetry.
  ///
  /// In ru, this message translates to:
  /// **'Проверить сохранение'**
  String get aiHistoryRetry;

  /// No description provided for @aiLoadOlder.
  ///
  /// In ru, this message translates to:
  /// **'Показать предыдущие сообщения'**
  String get aiLoadOlder;

  /// No description provided for @aiReturnSchedule.
  ///
  /// In ru, this message translates to:
  /// **'Вернуться к расписанию'**
  String get aiReturnSchedule;

  /// No description provided for @aiSourceUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Официальная ссылка не указана'**
  String get aiSourceUnavailable;

  /// No description provided for @aiStarterGrades.
  ///
  /// In ru, this message translates to:
  /// **'Что у меня по успеваемости?'**
  String get aiStarterGrades;

  /// No description provided for @aiStarterRequests.
  ///
  /// In ru, this message translates to:
  /// **'Как заказать справку?'**
  String get aiStarterRequests;

  /// No description provided for @aiContactsFollowup.
  ///
  /// In ru, this message translates to:
  /// **'Куда обращаться?'**
  String get aiContactsFollowup;

  /// No description provided for @aiEligibilityFollowup.
  ///
  /// In ru, this message translates to:
  /// **'Кто имеет право на получение?'**
  String get aiEligibilityFollowup;

  /// No description provided for @aiNewsFollowup.
  ///
  /// In ru, this message translates to:
  /// **'Покажи последнюю новость'**
  String get aiNewsFollowup;

  /// No description provided for @aiTomorrowFirst.
  ///
  /// In ru, this message translates to:
  /// **'Какая у меня завтра первая пара?'**
  String get aiTomorrowFirst;

  /// No description provided for @aiHistoryBrowser.
  ///
  /// In ru, this message translates to:
  /// **'В браузере история может исчезнуть после очистки данных сайта или выхода из приватного режима.'**
  String get aiHistoryBrowser;

  /// No description provided for @aiLegacy.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение из другой версии приложения'**
  String get aiLegacy;

  /// No description provided for @aiOpenStatements.
  ///
  /// In ru, this message translates to:
  /// **'Открыть заявления'**
  String get aiOpenStatements;

  /// No description provided for @notificationPreferencesDescription.
  ///
  /// In ru, this message translates to:
  /// **'Напоминания о парах и готовности заявлений. Разрешение на показ задаётся в настройках устройства.'**
  String get notificationPreferencesDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get languageSaveFailed =>
      'Could not save the language. Please try again.';

  @override
  String get uiAcademicProgress => 'Grades';

  @override
  String get uiPointsGradesAndPassResultsOrganisedBySemester =>
      'Points, grades and pass results, organised by semester.';

  @override
  String get uiSignInWithYourUniversityAccountToView =>
      'Sign in with your university account to view your academic progress.';

  @override
  String get uiCouldNotLoadAcademicProgress =>
      'Could not load academic progress';

  @override
  String get uiTryAgain => 'Try again';

  @override
  String get uiCouldNotRetrieveAcademicProgress =>
      'Could not retrieve academic progress';

  @override
  String get uiNoDataYet => 'No data yet';

  @override
  String get uiPullDownToRefresh => 'Pull down to refresh.';

  @override
  String get uiVgspuPortal => 'VGSPU portal';

  @override
  String get uiPointsAbsencesAndSubjectResults =>
      'Points, absences and subject results.';

  @override
  String get uiNoSemester => 'No semester';

  @override
  String uiSemester(String p0) {
    return 'Semester $p0';
  }

  @override
  String get uiEachCheckpointShowsCumulativePointsAndHoursMissed =>
      'Each checkpoint shows cumulative points and hours missed. Values come from the portal; do not add them across checkpoints.';

  @override
  String get uiSchedule => 'Schedule';

  @override
  String get uiUniversity => 'University';

  @override
  String get uiSettings => 'Settings';

  @override
  String get uiCouldNotReadTheDocumentsPleaseReopenThis =>
      'Could not read the documents. Please reopen this screen.';

  @override
  String get uiYourChoiceHasBeenSaved => 'Your choice has been saved.';

  @override
  String get uiAnalyticsIsOffPreviouslySharedDataIsNot =>
      'Analytics is off. Previously shared data is not deleted automatically. Contact: unio.support@gmail.com.';

  @override
  String uiTheServerRecordWillBeSentAgainWhen(String p0) {
    return '$p0 The server record will be sent again when you open the app.';
  }

  @override
  String get uiCouldNotCompleteTheChangePleaseTryAgain =>
      'Could not complete the change. Please try again.';

  @override
  String get uiCouldNotSaveYourChoicePleaseTryAgain =>
      'Could not save your choice. Please try again.';

  @override
  String get uiDeleteAccountAndData => 'Delete account and data?';

  @override
  String get uiThisDeletesYourUnioServerAccountLocalSign =>
      'This deletes your UNIO server account, local sign-in details, notes and their photos, caches and consent history. Processing based on consent will stop.\n\nIf you are offline, server deletion will remain queued. Only the token needed to complete this request will remain in secure storage until confirmation. Open the app online before uninstalling it.\n\nThis button does not delete university documents, original photos, exported files, server backups or data already sent to MyTracker. Contact: unio.support@gmail.com.';

  @override
  String get uiCancel => 'Cancel';

  @override
  String get uiDelete => 'Delete';

  @override
  String get uiDocumentsAndData => 'Documents and data';

  @override
  String get uiYourChoices => 'Your choices';

  @override
  String get uiDataManagement => 'Data management';

  @override
  String get uiAnalyticsIsOptionalDecliningDoesNotLimitUnio =>
      'Analytics is optional. Declining does not limit UNIO features.';

  @override
  String get uiIAcceptTheUserAgreement => 'I accept the user agreement';

  @override
  String get uiIConsentToUnioProcessingMyPersonalData =>
      'I consent to UNIO processing my personal data';

  @override
  String get uiSeparateConsentThePolicyAndFullTextAre =>
      'Separate consent. The policy and full text are available above.';

  @override
  String get uiMytrackerIsNotUsedInTheWebApp =>
      'MyTracker is not used in the web app. Local data is stored in your browser; clearing site data deletes notes and sign-in details. Before clearing it, wait for confirmation of server account deletion.';

  @override
  String get uiIGiveSeparateConsentToMytracker =>
      'I give separate consent to MyTracker';

  @override
  String get uiOptionalYouCanWithdrawConsentHereAtAny =>
      'Optional. You can withdraw consent here at any time.';

  @override
  String get uiSaving => 'Saving…';

  @override
  String get uiContinue => 'Continue';

  @override
  String get uiSignOutWithoutAccepting => 'Sign out without accepting';

  @override
  String get uiWithdrawConsentAndDeleteData =>
      'Withdraw consent and delete data';

  @override
  String get uiNotesAreKeptUntilYouDeleteThemInactive =>
      'Notes are kept until you delete them. Inactive server accounts are deleted after 90 days. Data enquiries: unio.support@gmail.com.';

  @override
  String get uiCouldNotOpenThisNoteOnYourDevice =>
      'Could not open this note on your device. Please try again.';

  @override
  String get uiCouldNotSaveTheNoteCheckAvailableStorage =>
      'Could not save the note. Check available storage and try again.';

  @override
  String get uiSavedOnThisDevice => 'Saved on this device';

  @override
  String get uiCouldNotReadThePhotoChooseAnotherImage =>
      'Could not read the photo. Choose another image.';

  @override
  String get uiCouldNotOpenPhotosCheckAppPermissionsAnd =>
      'Could not open photos. Check app permissions and try again.';

  @override
  String get uiDeleteNote => 'Delete note?';

  @override
  String get uiThisClassNoteAndItsAttachedPhotosWill =>
      'This class note and its attached photos will be deleted from the app. Originals in your gallery will remain.';

  @override
  String get uiNoteDeleted => 'Note deleted';

  @override
  String get uiCouldNotDeleteTheNotePleaseTryAgain =>
      'Could not delete the note. Please try again.';

  @override
  String get uiSaveChanges => 'Save changes?';

  @override
  String get uiThisNoteHasUnsavedChanges => 'This note has unsaved changes.';

  @override
  String get uiKeepEditing => 'Keep editing';

  @override
  String get uiDiscardChanges => 'Discard changes';

  @override
  String get uiSave => 'Save';

  @override
  String get uiAddHomework => 'Add homework';

  @override
  String get uiFromGallery => 'From gallery';

  @override
  String get uiTakeAPhoto => 'Take a photo';

  @override
  String get uiHomeworkAndNotes => 'Homework and notes';

  @override
  String get uiDeleteNote59 => 'Delete note';

  @override
  String get uiNoteUnavailable => 'Note unavailable';

  @override
  String get uiClassNote => 'Class note';

  @override
  String get uiWhatIsTheAssignmentWriteDownHomeworkOr =>
      'What is the assignment?\nWrite down homework or an important thought…';

  @override
  String get uiPhotos => 'Photos';

  @override
  String get uiAddAssignmentPhotosFromYourGalleryOrCamera =>
      'Add assignment photos from your gallery or camera.';

  @override
  String get uiNotesAndPhotosAreStoredOnlyOnThis =>
      'Notes and photos are stored only on this device and work offline. Uninstalling the app or clearing its data will delete them.';

  @override
  String get uiUniversityNews => 'University news';

  @override
  String get uiCouldNotLoadThisArticle => 'Could not load this article';

  @override
  String get uiArticleNotFound => 'Article not found';

  @override
  String get uiThisArticleIsNoLongerAvailable =>
      'This article is no longer available.';

  @override
  String get uiJanuary => 'January';

  @override
  String get uiFebruary => 'February';

  @override
  String get uiMarch => 'March';

  @override
  String get uiApril => 'April';

  @override
  String get uiMay => 'May';

  @override
  String get uiJune => 'June';

  @override
  String get uiJuly => 'July';

  @override
  String get uiAugust => 'August';

  @override
  String get uiSeptember => 'September';

  @override
  String get uiOctober => 'October';

  @override
  String get uiNovember => 'November';

  @override
  String get uiDecember => 'December';

  @override
  String get uiNews => 'News';

  @override
  String get uiCouldNotLoadNews => 'Could not load news';

  @override
  String get uiNoNewsYet => 'No news yet';

  @override
  String get uiCheckBackALittleLater => 'Check back a little later.';

  @override
  String get uiUnioNews => 'UNIO · News';

  @override
  String get uiOnCampus => 'On campus';

  @override
  String get uiUniversityEventsAndAnnouncements =>
      'University events and announcements';

  @override
  String get uiNoDate => 'No date';

  @override
  String get uiToday => 'Today';

  @override
  String get uiYesterday => 'Yesterday';

  @override
  String get uiLatest => 'LATEST';

  @override
  String get uiOpenTheFullArticleToReadThisStory =>
      'Open the full article to read this story.';

  @override
  String get uiVgspuNews => 'VGSPU news';

  @override
  String get uiCloseStory => 'Close story';

  @override
  String get uiReadFullArticle => 'Read full article';

  @override
  String uiEnterYourPortalUsernameAndPassword(String p0) {
    return 'Enter your $p0 portal username and password';
  }

  @override
  String uiSignInViaThePortal(String p0) {
    return 'Sign in via the $p0 portal';
  }

  @override
  String get uiUseYourUniversityPortalUsernameAndPassword =>
      'Use your university portal username and password.';

  @override
  String get uiPortalUsername => 'Portal username';

  @override
  String get uiPortalPassword => 'Portal password';

  @override
  String get uiSignIn => 'Sign in';

  @override
  String get uiYourPasswordIsNotSavedInTheBrowser =>
      'Your password is not saved in the browser. You stay signed in after closing UNIO.';

  @override
  String get uiYourUsernameAndPasswordAreStoredEncryptedOn =>
      'Your username and password are stored encrypted on this device.';

  @override
  String get uiPortalTemporarilyUnavailable => 'Portal temporarily unavailable';

  @override
  String get uiCheckYourVgspuPortalAccount => 'Check your VGSPU portal account';

  @override
  String get uiCouldNotLoadApplications => 'Could not load applications';

  @override
  String uiApplicationStatusEditingIsCurrentlyUnavailable(String p0) {
    return 'Application status: $p0. Editing is currently unavailable.';
  }

  @override
  String get uiApplicationCreatedThePortalIsPreparingTheForm =>
      'Application created. The portal is preparing the form. Refresh the list shortly.';

  @override
  String get uiCertificatesAndApplications => 'Certificates and applications';

  @override
  String get uiRefreshStatuses => 'Refresh statuses';

  @override
  String get uiCreatingApplication => 'Creating application…';

  @override
  String get uiSubmitAnApplication => 'Submit an application';

  @override
  String get uiMyApplications => 'My applications';

  @override
  String uiCheckedAtPullDownToRefresh(String p0) {
    return 'Checked at $p0 · pull down to refresh';
  }

  @override
  String uiCouldNotRefreshStatusesShowingPreviousData(String p0) {
    return 'Could not refresh statuses. Showing previous data.\n$p0';
  }

  @override
  String get uiNoApplicationsYet => 'No applications yet';

  @override
  String get uiChooseTheDocumentYouNeedUsingTheButton =>
      'Choose the document you need using the button below.';

  @override
  String get uiNewApplication => 'New application';

  @override
  String get uiWhichDocumentDoYouNeed => 'Which document do you need?';

  @override
  String get uiChooseACategoryAndApplicationTypeFromThe =>
      'Choose a category and application type from the university list.';

  @override
  String get uiCategory => 'Category';

  @override
  String get uiRetryLoading => 'Retry loading';

  @override
  String get uiNoApplicationsAvailableInThisCategory =>
      'No applications available in this category.';

  @override
  String get uiApplicationType => 'Application type';

  @override
  String get uiCreateApplication => 'Create application';

  @override
  String get uiADraftWillBeCreatedOnThePortal =>
      'A draft will be created on the portal. You can submit it for processing after checking your details.';

  @override
  String get uiComingSoon => 'Coming soon';

  @override
  String get uiThisSectionIsStillBeingDeveloped =>
      'This section is still being developed.';

  @override
  String get uiCouldNotOpenTheBrowser => 'Could not open the browser.';

  @override
  String get uiTemplateSavedFillItOutInADocument =>
      'Template saved. Fill it out in a document editor and attach it to your application.';

  @override
  String get uiCouldNotSaveTheTemplateTryAgainAnd =>
      'Could not save the template. Try again and choose an accessible folder.';

  @override
  String get uiApplication => 'Application';

  @override
  String get uiChooseAFileInOneOfTheListed =>
      'Choose a file in one of the listed formats.';

  @override
  String get uiChooseAFileUpToMb => 'Choose a file up to 20 MB.';

  @override
  String get uiTheSelectedFileIsEmpty => 'The selected file is empty.';

  @override
  String get uiCouldNotReadTheFilePleaseSelectIt =>
      'Could not read the file. Please select it again.';

  @override
  String get uiAttachYourApplication => 'Attach your application';

  @override
  String get uiFileAlreadyUploadedToThePortal =>
      'File already uploaded to the portal';

  @override
  String get uiAttachADocumentConfirmingYourSelectedCategory =>
      'Attach a document confirming your selected category.';

  @override
  String get uiFillOutTheTemplateAndAttachYourApplication =>
      'Fill out the template and attach your application file.';

  @override
  String uiUpToMb(String p0) {
    return '$p0 · up to 20 MB';
  }

  @override
  String get uiChooseFile => 'Choose file';

  @override
  String get uiReplaceFile => 'Replace file';

  @override
  String get uiTheFileWillBeUploadedWhenYouSubmit =>
      'The file will be uploaded when you submit your application.';

  @override
  String get uiRemoveSelectedFile => 'Remove selected file';

  @override
  String get uiSubmitApplication => 'Submit application?';

  @override
  String get uiCheckYourDetailsAndAttachmentsYourApplicationWill =>
      'Check your details and attachments. Your application will be sent to the university for processing.';

  @override
  String get uiReviewAgain => 'Review again';

  @override
  String get uiSubmit => 'Submit';

  @override
  String get uiSubmissionCouldNotBeConfirmedCheckTheApplication =>
      'Submission could not be confirmed. Check the application status before trying again: the portal may already have received your data.';

  @override
  String get uiEmailAddress => 'Email address';

  @override
  String get uiPostalAddress => 'Postal address';

  @override
  String get uiStartOfPeriod => 'Start of period';

  @override
  String get uiEndOfPeriod => 'End of period';

  @override
  String get uiNumberOfCopies => 'Number of copies';

  @override
  String get uiDdMmYyyy => 'DD.MM.YYYY';

  @override
  String get uiChooseDate => 'Choose date';

  @override
  String get uiPleaseConfirmYourConsent => 'Please confirm your consent';

  @override
  String uiApplication160(String p0) {
    return 'Application #$p0';
  }

  @override
  String get uiFormNotAvailableYet => 'Form not available yet';

  @override
  String get uiCouldNotOpenApplication => 'Could not open application';

  @override
  String get uiBackToApplications => 'Back to applications';

  @override
  String get uiFillInYourDetails => 'Fill in your details';

  @override
  String get uiApplicationOnThePortal => 'Application on the portal';

  @override
  String get uiFieldsMarkedWithAnAsteriskAreRequiredYou =>
      'Fields marked with an asterisk are required. You can review your details before submitting.';

  @override
  String get uiThisApplicationCannotBeEditedItsCurrentStatus =>
      'This application cannot be edited. Its current status is shown in the application list.';

  @override
  String get uiSaving168 => 'Saving…';

  @override
  String get uiDownloadWordTemplate => 'Download Word template';

  @override
  String get uiOpenTemplateOnThePortal => 'Open template on the portal';

  @override
  String get uiSomeAttachmentsOrFieldsInThisFormAre =>
      'Some attachments or fields in this form are only available on the portal. Continue in your browser.';

  @override
  String get uiSubmitForProcessing => 'Submit for processing';

  @override
  String get uiCheckApplicationStatus => 'Check application status';

  @override
  String get uiOpenOnTheVgspuPortal => 'Open on the VGSPU portal';

  @override
  String get uiClassPhotosRecoveredAndSaved =>
      'Class photos recovered and saved';

  @override
  String get uiCouldNotRecoverTheSelectedPhotosOpenThe =>
      'Could not recover the selected photos. Open the note and add them again.';

  @override
  String get uiNextWeek => 'Next week';

  @override
  String get uiThisWeek => 'This week';

  @override
  String get uiCouldNotLoadSchedule => 'Could not load schedule';

  @override
  String get uiCheckYourInternetConnectionAndTryAgain =>
      'Check your internet connection and try again';

  @override
  String get uiNoScheduleFoundForThisWeek => 'No schedule found for this week';

  @override
  String get uiEndGuestSession => 'End guest session';

  @override
  String get uiSignOut => 'Sign out';

  @override
  String get uiYouWillNeedToChooseAGroupAgain =>
      'You will need to choose a group again for a new guest session.';

  @override
  String get uiYouWillNeedToSignInAgainTo =>
      'You will need to sign in again to access your account.';

  @override
  String get uiEndSession => 'End session';

  @override
  String get uiSignOut187 => 'Sign out';

  @override
  String get uiAccountAndAppPreferences => 'Account and app preferences';

  @override
  String get uiTeacher => 'Teacher';

  @override
  String get uiPersonalAccount => 'Personal account';

  @override
  String uiGroup(String p0) {
    return 'Group $p0';
  }

  @override
  String uiPortal(String p0) {
    return '$p0 portal';
  }

  @override
  String get uiGuestAccess => 'Guest access';

  @override
  String uiScheduleForGroup(String p0) {
    return 'Schedule for group $p0';
  }

  @override
  String get uiChangeGroup => 'Change group';

  @override
  String get uiSignInToThePortalAgain => 'Sign in to the portal again';

  @override
  String uiSignInViaThePortal198(String p0) {
    return 'Sign in via the $p0 portal';
  }

  @override
  String get uiPreferences => 'Preferences';

  @override
  String get uiDarkTheme => 'Dark theme';

  @override
  String get uiPushNotifications => 'Push notifications';

  @override
  String get uiNotificationsAreCurrentlyUnavailableOnIphoneAddUnio =>
      'Notifications are currently unavailable. On iPhone, add UNIO to your Home Screen.';

  @override
  String get uiScheduleWidget => 'Schedule widget';

  @override
  String get uiYourNextClassOnTheHomeScreen =>
      'Your next class on the Home Screen';

  @override
  String get uiPrivacy => 'Privacy';

  @override
  String get uiConsentAnalyticsAndDeletion => 'Consent, analytics and deletion';

  @override
  String get uiInstallUnio => 'Install UNIO';

  @override
  String get uiAddToHomeScreenWebBeta => 'Add to Home Screen · web beta';

  @override
  String get uiNotesAreStoredInThisBrowserClearingSite =>
      'Notes are stored in this browser. Clearing site data deletes them. Your portal password is not saved in the web app.';

  @override
  String get uiSigningOut => 'Signing out…';

  @override
  String uiUnioVersion(String p0) {
    return 'UNIO · Version $p0';
  }

  @override
  String get uiCouldNotSignOutPleaseTryAgain =>
      'Could not sign out. Please try again.';

  @override
  String get uiClass => 'Class';

  @override
  String get uiClassDetailsAndTeachingTools =>
      'Class details and teaching tools.';

  @override
  String get uiRoomNotSpecified => 'Room not specified';

  @override
  String uiRoom(String p0) {
    return 'Room $p0';
  }

  @override
  String get uiFindAnAvailableRoom => 'Find an available room';

  @override
  String get uiBackToSchedule => 'Back to schedule';

  @override
  String get uiAvailableRooms => 'Available rooms';

  @override
  String get uiCouldNotFindRooms => 'Could not find rooms';

  @override
  String get uiForTeachers => 'For teachers';

  @override
  String get uiARoomForYourClass => 'A room for your class';

  @override
  String get uiNoAvailableRoomsFoundInTheKnownSchedules =>
      'No available rooms found in the known schedules.';

  @override
  String uiRoom224(String p0) {
    return 'Room $p0';
  }

  @override
  String get uiTodaySSchedule => 'Today\'s schedule';

  @override
  String get uiPartOfTheScheduleIsUnavailableShowingKnown =>
      'Part of the schedule is unavailable. Showing known classes.';

  @override
  String uiNow(String p0, String p1) {
    return 'Now · $p0–$p1';
  }

  @override
  String get uiCouldNotDetermineWhetherThereIsAClass =>
      'Could not determine whether there is a class now.';

  @override
  String get uiNoClassesScheduledRightNow => 'No classes scheduled right now.';

  @override
  String uiNext(String p0) {
    return 'Next · $p0';
  }

  @override
  String get uiTimesForUpcomingClassesAreNotSpecified =>
      'Times for upcoming classes are not specified.';

  @override
  String get uiNoMoreClassesToday => 'No more classes today.';

  @override
  String get uiTheScheduleShowsPlannedClassesNotAPerson =>
      'The schedule shows planned classes, not a person\'s actual location.';

  @override
  String get uiSavedDataNotConfirmedWithTheServer =>
      'Saved data · not confirmed with the server';

  @override
  String get uiTodaySScheduleHasNotLoadedRefreshTo =>
      'Today\'s schedule has not loaded. Refresh to try again.';

  @override
  String get uiRefreshSchedule => 'Refresh schedule';

  @override
  String get uiClassesAndRoomsFromTheUniversitySchedule =>
      'Classes and rooms from the university schedule.';

  @override
  String get uiClassSchedule => 'Class schedule';

  @override
  String get uiPreviousDay => 'Previous day';

  @override
  String uiToday240(String p0) {
    return 'Today · $p0';
  }

  @override
  String get uiNextDay => 'Next day';

  @override
  String get uiBackToToday => 'Back to today';

  @override
  String get uiCouldNotLoadClasses => 'Could not load classes';

  @override
  String get uiTheScheduleHasNotLoadedCompletely =>
      'The schedule has not loaded completely.';

  @override
  String get uiShowingSavedSchedule => 'Showing saved schedule.';

  @override
  String get uiNoKnownClassesForThisDayTheFull =>
      'No known classes for this day. The full schedule is currently unavailable.';

  @override
  String get uiViewClassesAndRooms => 'View classes and rooms';

  @override
  String get uiFindATeacher => 'Find a teacher';

  @override
  String get uiRefreshDirectory => 'Refresh directory';

  @override
  String get uiSurnameOrPartOfAName => 'Surname or part of a name';

  @override
  String get uiClearSearch => 'Clear search';

  @override
  String get uiSearchingTheSavedDirectory => 'Searching the saved directory';

  @override
  String get uiDirectoryCurrentlyUnavailable =>
      'Directory currently unavailable';

  @override
  String get uiRecentlyViewed => 'Recently viewed';

  @override
  String get uiClear => 'Clear';

  @override
  String get uiWhoAreYouLookingFor => 'Who are you looking for?';

  @override
  String get uiEnterAtLeastTwoLettersOfASurname =>
      'Enter at least two letters of a surname. You do not need the full name.';

  @override
  String get uiNoMatches => 'No matches';

  @override
  String get uiCheckTheSurnameOrTryFewerLetters =>
      'Check the surname or try fewer letters.';

  @override
  String get uiChooseATeacher => 'Choose a teacher';

  @override
  String get uiMoreMatchesAvailableRefineTheSurname =>
      'More matches available — refine the surname.';

  @override
  String get uiUniversityEventsAnnouncementsAndCampusLife =>
      'University events, announcements and campus life';

  @override
  String get uiCertificatesFormsAndPortalResponses =>
      'Certificates, forms and portal responses';

  @override
  String get uiTeachers => 'Teachers';

  @override
  String get uiSearchBySurnameClassesAndRooms =>
      'Search by surname, classes and rooms';

  @override
  String get uiUnioUniversity => 'UNIO · University';

  @override
  String get uiForYourStudies => 'For your studies';

  @override
  String get uiNewsApplicationsAndTeacherSearchInOnePlace =>
      'News, applications and teacher search in one place.';

  @override
  String get uiApplications => 'Applications';

  @override
  String get uiUseYourUniversityAccountYourApplicationsWillAppear =>
      'Use your university account. Your applications will appear after you sign in.';

  @override
  String get uiBack => 'Back';

  @override
  String get uiSkip => 'Skip';

  @override
  String uiPageOf(String p0, String p1) {
    return 'Page $p0 of $p1';
  }

  @override
  String uiPage(String p0) {
    return 'Page $p0';
  }

  @override
  String get uiGetStarted => 'Get started';

  @override
  String get uiNext276 => 'Next';

  @override
  String get uiLetSGetAcquainted => 'LET\'S GET ACQUAINTED';

  @override
  String get uiChooseYourRole => 'Choose\nyour role';

  @override
  String get uiStudentsAndTeachersHaveAccessToDifferentSections =>
      'Students and teachers have access to different sections.';

  @override
  String get uiDoYouStudyOrTeach => 'Do you study or teach?';

  @override
  String get uiIMAStudent => 'I\'m a student';

  @override
  String get uiClassesGradesAndApplications =>
      'Classes, grades and applications';

  @override
  String get uiIMATeacher => 'I\'m a teacher';

  @override
  String get uiScheduleAndAvailableRooms => 'Schedule and available rooms';

  @override
  String get uiYouCanChangeYourRoleBySigningOut =>
      'You can change your role by signing out.';

  @override
  String get uiForStudents => 'FOR STUDENTS';

  @override
  String get uiHowWouldYouLikeToSignIn => 'How would you\nlike to sign in?';

  @override
  String get uiConnectYourPortalAccountOrStartWithYour =>
      'Connect your portal account or start with your group schedule.';

  @override
  String get uiWhatWorksForYou => 'What works for you?';

  @override
  String get uiScheduleGradesAndApplications =>
      'Schedule, grades and applications';

  @override
  String get uiContinueAsAGuest => 'Continue as a guest';

  @override
  String get uiStartWithYourGroupCodeYouCanConnect =>
      'Start with your group code. You can connect the portal later.';

  @override
  String get uiWelcomeToUnio => 'WELCOME TO UNIO';

  @override
  String get uiHiThisIsUnio => 'Hi! This is UNIO.';

  @override
  String get uiAnAppForYourStudies => 'An app for your studies.';

  @override
  String get uiViewYourScheduleSaveAssignmentsAndRequestCertificates =>
      'View your schedule, save assignments and request certificates.';

  @override
  String get uiSchedule297 => 'SCHEDULE';

  @override
  String get uiYourClassSchedule => 'Your class schedule.';

  @override
  String get uiForTodayAndTheWeek => 'For today and the week.';

  @override
  String get uiChooseADayToViewClassesTimesAnd =>
      'Choose a day to view classes, times and rooms. Saved schedules work offline.';

  @override
  String get uiCertificatesAndApplications301 =>
      'CERTIFICATES AND APPLICATIONS';

  @override
  String get uiNeedACertificate => 'Need a certificate?';

  @override
  String get uiRequestItInTheApp => 'Request it in the app.';

  @override
  String get uiRequestCertificatesViaThePortalTrackTheirStatus =>
      'Request certificates via the portal, track their status and get notified when they are ready.';

  @override
  String get uiMoreFeatures => 'MORE FEATURES';

  @override
  String get uiNewsAndTeachers => 'News and teachers.';

  @override
  String get uiHomeworkAndNotes307 => 'Homework and notes.';

  @override
  String get uiFindTeachersAndTheirClassesReadUniversityNews =>
      'Find teachers and their classes, read university news and keep notes for your classes.';

  @override
  String get uiEnterYourFullNameCharacters =>
      'Enter your full name (3–255 characters)';

  @override
  String get uiEnterYourVgspuPortalUsernameAndPassword =>
      'Enter your VGSPU portal username and password';

  @override
  String get uiEnterYourGroupUsernameAndPassword =>
      'Enter your group, username and password';

  @override
  String get uiEnterYourGroupCode => 'Enter your group code';

  @override
  String get uiCouldNotSignInCheckYourConnectionAnd =>
      'Could not sign in. Check your connection and try again.';

  @override
  String get uiForTeachers314 => 'FOR TEACHERS';

  @override
  String get uiYourAccount => 'YOUR ACCOUNT';

  @override
  String get uiQuickStart => 'QUICK START';

  @override
  String get uiTeacherSchedule => 'Teacher\nschedule';

  @override
  String get uiSignInViaThePortal318 => 'Sign in via\nthe portal';

  @override
  String get uiChooseYourGroup => 'Choose\nyour group';

  @override
  String get uiSignInWithYourVgspuPortalAccountYour =>
      'Sign in with your VGSPU portal account. Your full name is needed to find your schedule.';

  @override
  String uiUseYourPortalUsernameAndPassword(String p0) {
    return 'Use your $p0 portal username and password.';
  }

  @override
  String get uiChooseAGroupAndPlanYourDayNo =>
      'Choose a group and plan your day. No university password needed.';

  @override
  String get uiEnterYourGroupCodeAndPlanYourDay =>
      'Enter your group code and plan your day. You can connect the portal later.';

  @override
  String get uiTeacherSignIn => 'Teacher sign-in';

  @override
  String get uiFullName => 'Full name';

  @override
  String get uiShowPassword => 'Show password';

  @override
  String get uiHidePassword => 'Hide password';

  @override
  String get uiYourUsernameAndPasswordAreStoredSecurelyOn =>
      'Your username and password are stored securely on this device.';

  @override
  String get uiNoPortalUsernameOrPasswordNeeded =>
      'No portal username or password needed.';

  @override
  String get uiToday330 => 'TODAY';

  @override
  String get uiToday331 => '· Today';

  @override
  String get uiNoClasses => 'No classes';

  @override
  String get uiNoClassesTakeABreak => 'No classes — take a break';

  @override
  String get uiChooseAnotherDayToViewItsSchedule =>
      'Choose another day to view its schedule.';

  @override
  String get uiGroupListCurrentlyUnavailable =>
      'Group list currently unavailable';

  @override
  String get uiCouldNotCheckTheGroupListPleaseTry =>
      'Could not check the group list. Please try again.';

  @override
  String get uiGroupCode => 'Group code';

  @override
  String get uiStartTypingAGroupCodeOrNumber =>
      'Start typing a group code or number';

  @override
  String get uiLoadingGroups => 'Loading groups…';

  @override
  String uiTryAgain340(String p0) {
    return '$p0. Try again';
  }

  @override
  String get uiGroupNotFoundCheckTheCodeOrEnter =>
      'Group not found. Check the code or enter just the number.';

  @override
  String get uiHowToViewYourSchedule => 'How to view\nyour schedule';

  @override
  String get uiChooseADayOnTheScheduleTimesAre =>
      'Choose a day on the schedule. Times are on the left, with the subject and room beside them. Tap a class to open it.';

  @override
  String get uiHowToSwitchWeeks => 'How to switch\nweeks';

  @override
  String get uiSwipeLeftForNextWeekAndRightFor =>
      'Swipe left for next week and right for this week. The button above the schedule does the same. Saved classes are available offline.';

  @override
  String get uiHowToAddHomework => 'How to add homework';

  @override
  String get uiOpenAClassWriteDownHomeworkOrAn =>
      'Open a class, write down homework or an important thought and tap Save. The note is linked to that class.';

  @override
  String get uiHowToAddPhotos => 'How to add photos';

  @override
  String get uiScrollTheActionBarToAddPhotosFrom =>
      'Scroll the action bar to add photos from your gallery or camera. Notes and photos are stored on your device: uninstalling the app deletes them too.';

  @override
  String get uiHowToRequestACertificate => 'How to request a certificate';

  @override
  String get uiOpenUniversitySubmitAnApplicationAndSignIn =>
      'Open University → Submit an application and sign in via the portal. Choose a document. While the status is New, the portal is still preparing the form.';

  @override
  String get uiFillingOutAnApplication => 'Filling out an application';

  @override
  String get uiWhenOpenFormAppearsOpenTheApplicationAfter =>
      'When Open form appears, open the application. After submitting, check its status here. You can enable push notifications in Settings; checks may be delayed.';

  @override
  String get uiRooms => 'Rooms';

  @override
  String get uiFindARoom => 'Find a room';

  @override
  String get uiOpenAClassAndSelectFindAnAvailable =>
      'Open a class and select Find an available room in the action bar. The search uses that class\'s date and time.';

  @override
  String get uiWhatTheSearchShows => 'What the search shows';

  @override
  String get uiUnioOnlyChecksTheSchedulesItKnowsA =>
      'UNIO only checks the schedules it knows. A room found here is not reserved: confirm that it is actually available before class.';

  @override
  String get uiTeacherSearch => 'Teacher search';

  @override
  String get uiOpenTeachersInTheUniversityTabEnterAt =>
      'Open Teachers in the University tab. Enter at least two letters of the surname and choose the correct full name.';

  @override
  String get uiClassesAndRooms => 'Classes and rooms';

  @override
  String get uiATeacherSCardShowsClassesAndRooms =>
      'A teacher\'s card shows classes and rooms. This is a plan, not location tracking: a schedule does not confirm their presence on campus.';

  @override
  String get uiGettingStarted => 'Getting started';

  @override
  String get uiCloseGuide => 'Close guide';

  @override
  String get uiAppGuide => 'APP GUIDE';

  @override
  String get uiGotIt => 'Got it';

  @override
  String uiExample(String p0) {
    return 'EXAMPLE · $p0';
  }

  @override
  String get uiMon => 'MON';

  @override
  String get uiTue => 'TUE';

  @override
  String get uiWed => 'WED';

  @override
  String get uiThu => 'THU';

  @override
  String get uiFri => 'FRI';

  @override
  String get uiForeignLanguage => '10:10 · Foreign language';

  @override
  String get uiRoom374 => 'Room 314';

  @override
  String get uiPedagogy => '11:50 · Pedagogy';

  @override
  String get uiRoom376 => 'Room 208';

  @override
  String get uiSwipeLeft => 'Swipe left';

  @override
  String get uiReadChapter => 'Read chapter 3';

  @override
  String get uiAssignmentForTheNextClass => 'Assignment for the next class';

  @override
  String get uiNew => 'New';

  @override
  String get uiThePortalIsPreparingTheForm =>
      'The portal is preparing the form';

  @override
  String get uiOpenForm => 'Open form';

  @override
  String get uiYouCanOpenTheApplication => 'You can open the application';

  @override
  String get uiUniversityResponse => 'University response';

  @override
  String get uiTheStatusWillAppearInTheList =>
      'The status will appear in the list';

  @override
  String get uiSelectedClassTime => 'Selected class time';

  @override
  String get uiBasedOnKnownSchedules => 'Based on known schedules';

  @override
  String get uiSearchBySurname => 'Search by surname';

  @override
  String get uiChooseTheFullName => 'Choose the full name';

  @override
  String get uiTeacherDetails => 'Teacher details';

  @override
  String get uiTodayAndOtherDays => 'Today and other days';

  @override
  String get uiRoomAndTime => 'Room and time';

  @override
  String get uiFromTheClassSchedule => 'From the class schedule';

  @override
  String get uiConfirmInTheAndroidDialogTheWidgetWill =>
      'Confirm in the Android dialog. The widget will appear on your Home Screen.';

  @override
  String get uiTouchAndHoldAnEmptyAreaOnYour =>
      'Touch and hold an empty area on your Home Screen → Widgets → UNIO.';

  @override
  String get uiYourScheduleAtHand => 'Your schedule at hand';

  @override
  String get uiYourNextClassAndRoomRightOnYour =>
      'Your next class and room, right on your Home Screen.';

  @override
  String get uiNextClassToday => 'NEXT CLASS · TODAY';

  @override
  String get uiForeignLanguage399 => 'Foreign language';

  @override
  String get uiPracticalRoom => 'Practical · Room 0439';

  @override
  String get uiYourDayYourPace => 'Your day, your pace';

  @override
  String get uiDesignPreviewTheWidgetWillShowYourSelected =>
      'Design preview. The widget will show your selected schedule and open UNIO when tapped.';

  @override
  String get uiAddToHomeScreen => 'Add to Home Screen';

  @override
  String uiRoom404(String p0) {
    return '  •  Room $p0';
  }

  @override
  String uiGroup405(String p0) {
    return 'Group: $p0';
  }

  @override
  String get uiLoadingTodaySClasses => 'Loading today\'s classes…';

  @override
  String get uiTodaySScheduleHasNotLoaded => 'Today\'s schedule has not loaded';

  @override
  String get uiTapToTryAgain => 'Tap to try again';

  @override
  String get uiNoScheduleFoundForThisWeek409 =>
      'No schedule found for this week';

  @override
  String get uiTapToRefresh => 'Tap to refresh';

  @override
  String get uiTimesForUpcomingClassesAreNotSpecified411 =>
      'Times for upcoming classes are not specified';

  @override
  String get uiNoMoreClassesToday412 => 'No more classes today';

  @override
  String get uiNoClassesTodayEnjoyYourBreak =>
      'No classes today — enjoy your break ☕';

  @override
  String uiNextClassTodayGoToThisClassIn(
      String p0, String p1, String p2, String p3) {
    return 'Next class today: $p0, $p1–$p2$p3. Go to this class in the schedule.';
  }

  @override
  String get uiNextClassToday415 => 'Next class · today';

  @override
  String get uiStartsIn => 'Starts in';

  @override
  String get uiYourDay => 'Your day';

  @override
  String get uiTheScheduleForOtherDaysIsBelow =>
      'The schedule for other days is below.';

  @override
  String get uiClassPhotos => 'Class photos';

  @override
  String get uiPreviousPhoto => 'Previous photo';

  @override
  String get uiNextPhoto => 'Next photo';

  @override
  String get uiCouldNotOpenPhoto => 'Could not open photo';

  @override
  String uiPhoto(String p0) {
    return 'Photo $p0';
  }

  @override
  String get uiRemovePhoto => 'Remove photo';

  @override
  String get uiUniversityServices => 'University services';

  @override
  String uiViaThePortalRightInUnio(String p0, String p1) {
    return '$p0 via the $p1 portal, right in UNIO.';
  }

  @override
  String get uiPortalSignInRequired => 'Portal sign-in required';

  @override
  String get uiUseYourUniversityAccountToOpenThisSection =>
      'Use your university account to open this section.';

  @override
  String uiAvailableAfterSigningInViaThePortalGuest(String p0) {
    return 'Available after signing in via the $p0 portal. Guest mode only includes the schedule.';
  }

  @override
  String get uiUnioOnYourHomeScreen => 'UNIO on your Home Screen';

  @override
  String get uiOnIphoneOpenUnioInSafariTapShare =>
      'On iPhone: open UNIO in Safari, tap Share → Add to Home Screen. If you see Open as Web App, enable it.\n\nOn Android and desktop: open the browser menu and choose Install app or Add to Home Screen.\n\nAfter the first load, saved schedules and notes are available offline. New data requires internet access. Clearing site data deletes local notes and sign-in details.';

  @override
  String get uiThePortalIsPreparingYourForm =>
      'The portal is preparing your form';

  @override
  String get uiSubjects => 'Subjects';

  @override
  String uiSemester445(String p0) {
    return 'Semester $p0';
  }

  @override
  String get uiNoResultYet => 'No result yet';

  @override
  String uiPts(String p0) {
    return '$p0 pts';
  }

  @override
  String get uiCheckpointsAndAbsences => 'Checkpoints and absences';

  @override
  String uiCheckpoint(String p0) {
    return 'Checkpoint $p0';
  }

  @override
  String uiMissedH(String p0) {
    return 'Missed: $p0 h';
  }

  @override
  String get uiLoading => 'Loading';

  @override
  String get uiRefreshing => 'Refreshing';

  @override
  String get uiSat => 'SAT';

  @override
  String get uiSun => 'SUN';

  @override
  String get uiPullDownToRefreshTheSchedule =>
      'Pull down to refresh the schedule.';

  @override
  String get uiClassesForTheWeek => 'Classes for the week';

  @override
  String get uiAlwaysNearby => 'Always nearby';

  @override
  String get uiForYourStudies470 => 'For your studies';

  @override
  String get uiYourDay471 => 'YOUR DAY';

  @override
  String get uiPedagogy472 => 'Pedagogy';

  @override
  String get uiEvenOffline => 'Even offline';

  @override
  String get uiEnrolmentCertificate => 'Enrolment certificate';

  @override
  String get uiApplicationSubmitted => 'Application submitted';

  @override
  String get uiSubmittedInProgressReady => 'Submitted → In progress → Ready';

  @override
  String get uiCertificateReady => 'Certificate ready';

  @override
  String get uiReadyToCollect => 'Ready to collect';

  @override
  String get uiTeacherClassSchedule => 'Teacher\nClass schedule';

  @override
  String get uiNextClassRoom => 'Next class · room 314';

  @override
  String get uiEssentialsAtHand => 'Essentials at hand';

  @override
  String get uiClassNotes => 'Class notes';

  @override
  String get uiTheServerHasConfirmedDeletionAndSignOut =>
      'The server has confirmed deletion and sign-out requests.';

  @override
  String get uiTheServerRequestIsStillWaitingForA =>
      'The server request is still waiting for a connection. Do not uninstall the app until it is confirmed.';

  @override
  String get uiPleaseAcceptTheDocumentsToSignInAnalytics =>
      'Please accept the documents to sign in. Analytics is optional.';

  @override
  String get uiCleanupIsIncompleteWeWillRetryOnThe =>
      'Cleanup is incomplete. We will retry on the next launch. Do not uninstall the app until confirmation.';

  @override
  String get uiYouAreSignedOutTheServerRequestIs =>
      'You are signed out. The server request is waiting for a connection. Open the app online.';

  @override
  String get uiYourUnioAccountAndLocalDataHaveBeen =>
      'Your UNIO account and local data have been deleted.';

  @override
  String get uiYouHaveSignedOut => 'You have signed out.';

  @override
  String get uiMonday => 'Monday';

  @override
  String get uiTuesday => 'Tuesday';

  @override
  String get uiWednesday => 'Wednesday';

  @override
  String get uiThursday => 'Thursday';

  @override
  String get uiFriday => 'Friday';

  @override
  String get uiSaturday => 'Saturday';

  @override
  String get uiSunday => 'Sunday';

  @override
  String get uiClass497 => 'class';

  @override
  String get uiClasses => 'classes';

  @override
  String get uiClasses499 => 'classes';

  @override
  String get uiCouldNotConnectCheckYourInternetConnectionAnd =>
      'Could not connect. Check your internet connection and try again.';

  @override
  String get uiTheServiceIsTemporarilyUnavailablePleaseTryAgain =>
      'The service is temporarily unavailable. Please try again later.';

  @override
  String get uiCouldNotCompleteThisActionPleaseTryAgain =>
      'Could not complete this action. Please try again.';

  @override
  String get uiSignInAgainAndRetryThisAction =>
      'Sign in again and retry this action.';

  @override
  String get uiThisActionIsCurrentlyUnavailableForYourAccount =>
      'This action is currently unavailable for your account.';

  @override
  String get uiCouldNotFindTheRequestedDataTryRefreshing =>
      'Could not find the requested data. Try refreshing the screen.';

  @override
  String get uiCheckYourDetailsAndTryAgain =>
      'Check your details and try again.';

  @override
  String get uiTheResponseIsTakingLongerThanExpectedPlease =>
      'The response is taking longer than expected. Please try again shortly.';

  @override
  String get uiTooManyAttemptsPleaseWaitALittleAnd =>
      'Too many attempts. Please wait a little and try again.';

  @override
  String get uiThePortalHasRestrictedAccessTryAnotherNetwork =>
      'The portal has restricted access. Try another network or open the portal in your browser. Code REQ_ACCESS.';

  @override
  String get uiCouldNotLoadTheListTryRefreshingIt =>
      'Could not load the list. Try refreshing it later. Code REQ_EMPTY.';

  @override
  String get uiOpenYourVgspuPortalAccountAnActionMay =>
      'Open your VGSPU portal account: an action may be required there. If applications work on the portal, contact support with code REQ_PAGE.';

  @override
  String get uiCouldNotOpenThePageSecurelyPleaseTry =>
      'Could not open the page securely. Please try again later.';

  @override
  String get storyViewed => 'Viewed';

  @override
  String get open => 'Open';

  @override
  String get draft => 'Draft';

  @override
  String get accepted => 'Accepted';

  @override
  String get withdrawn => 'Withdrawn';

  @override
  String get waitingForForm =>
      'Please wait while we retrieve information from the portal. Open form will appear when the form is ready. Refresh the list shortly.';

  @override
  String get noStatus => 'No status specified';

  @override
  String get lecture => 'Lecture';

  @override
  String get practice => 'Practical';

  @override
  String get lab => 'Lab';

  @override
  String get seminar => 'Seminar';

  @override
  String get consultation => 'Consultation';

  @override
  String get exam => 'Exam';

  @override
  String get credit => 'Pass/fail assessment';

  @override
  String get documentsOriginalLanguage =>
      'Documents are published in Russian. Changing the interface language does not change their text.';

  @override
  String get notesSignIn => 'Sign in as a student to open notes.';

  @override
  String get notesNoDate => 'This class has no date. Refresh the schedule.';

  @override
  String get notesWrongOwner => 'This note belongs to another account.';

  @override
  String get notesReadFailed => 'Could not read the saved note.';

  @override
  String get notesPhotosFailed => 'Could not read the note photos.';

  @override
  String get photoTooLarge =>
      'The photo is too large. Choose an image up to 10 MB.';

  @override
  String get photoAddFailed =>
      'Could not add the photo. The maximum size is 10 MB.';

  @override
  String get notesTextLimit => 'You can save up to 20,000 characters.';

  @override
  String get photoReadFailed => 'Could not read the photo.';

  @override
  String get photoUnavailable => 'Photo unavailable. Please add it again.';

  @override
  String get photosRecoveryFailed =>
      'Could not recover the selected photos. Please add them again.';

  @override
  String get portalCheckCredentials =>
      'Check your VGSPU portal username and password.';

  @override
  String get portalReauthenticate =>
      'Your VGSPU portal session has ended. Sign in via the portal again in UNIO Settings.';

  @override
  String get webSignInEnded =>
      'Your web sign-in has ended. Sign in via the portal again.';

  @override
  String get webConfigMissing =>
      'Web portal access has not been configured. Contact support with code WEB_CONFIG.';

  @override
  String get attachmentLimit => 'Choose an attachment up to 20 MB.';

  @override
  String get chooseSuggestedGroup => 'Choose a group from the suggestions.';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get portalConnectionFailed =>
      'Could not connect to the portal. Please try again.';

  @override
  String get checkInternet =>
      'Could not connect. Check your internet connection.';

  @override
  String get refreshSignInFailed =>
      'Could not refresh your sign-in. Please try again.';

  @override
  String get portalOtherSite =>
      'The portal attempted to redirect to another website.';

  @override
  String get portalNoRedirect =>
      'The portal did not provide a redirect address.';

  @override
  String get portalUploadRedirect =>
      'The portal redirected the file upload. Refresh the application and check the attachment.';

  @override
  String get portalTooManyRedirects => 'Too many portal redirects.';

  @override
  String get operationSignIn => 'Portal sign-in';

  @override
  String get operationDraft => 'Creating draft';

  @override
  String get operationTypes => 'Loading application types';

  @override
  String get operationRequests => 'Loading applications';

  @override
  String get operationSubmit => 'Submitting application';

  @override
  String get operationForm => 'Opening form';

  @override
  String get operationPortal => 'Loading portal page';

  @override
  String get portalCsrfRejected =>
      'the portal rejected the form security token';

  @override
  String get portalNeedsSignIn => 'the portal requires you to sign in again';

  @override
  String get portalDenied => 'the portal denied access';

  @override
  String get portalNoResponse => 'no response received; check your connection';

  @override
  String get portalError => 'the portal returned an error';

  @override
  String get portalSessionExpired =>
      'Your portal session has expired. Sign in via the portal again.';

  @override
  String get portalSignInFailed =>
      'Could not sign in to the portal. Check your username and password; the portal may require additional verification.';

  @override
  String get portalSignInRequired =>
      'Sign in via the VGSPU portal to continue.';

  @override
  String get tooManyRequestPages =>
      'Too many application pages. Open the portal to view the full list.';

  @override
  String get typesNotReturned =>
      'The portal did not return application types. Try signing in again.';

  @override
  String get typesLoadFailed => 'Could not load application types.';

  @override
  String get invalidRequestId => 'Invalid application number.';

  @override
  String get formNotFillable =>
      'Editing is currently unavailable. Return to the list and refresh the application status.';

  @override
  String get typeNoLongerAvailable =>
      'This application type is no longer available. Choose another.';

  @override
  String get draftNotConfirmed =>
      'The portal did not confirm creation. Refresh the list before trying again.';

  @override
  String get fieldRequired => 'Fill in this field';

  @override
  String get emailInvalid => 'Check the email address';

  @override
  String get dateInvalid => 'Enter a date in DD.MM.YYYY format';

  @override
  String get periodInvalid =>
      'The end of the period must not be before the start';

  @override
  String get positiveIntegerRequired =>
      'Enter a whole number greater than zero';

  @override
  String get formPortalOnly =>
      'This form cannot be submitted from the app. Open it on the portal.';

  @override
  String get checkFields => 'Check the form';

  @override
  String get checkAttachments => 'Check attachments';

  @override
  String get fileRejected =>
      'The portal rejected the file. Your application has not been submitted.';

  @override
  String get checkAttachmentFormat =>
      'Check the attachment format and size, then try again.';

  @override
  String get portalCorrectForm =>
      'The portal requires changes to your application';

  @override
  String get submissionPending =>
      'The request was sent, but the portal has not confirmed the new status. Refresh the application list before submitting again.';

  @override
  String get groupNotInCatalog =>
      'This group is not in the directory. Choose your group from the suggestions.';

  @override
  String get groupCheckConnection =>
      'Could not check the group list. Check your connection and try again.';

  @override
  String get groupNotInCatalogShort =>
      'This group is not in the directory. Choose a group from the suggestions.';

  @override
  String get groupCheckFailed =>
      'Could not check the group list. Please try again.';

  @override
  String get signInIncomplete =>
      'Could not complete sign-in. Please try again.';

  @override
  String get fullNameRequired => 'Enter your full name (3–255 characters)';

  @override
  String get credentialsRequired =>
      'Enter your VGSPU portal username and password';

  @override
  String semanticRoomSuffix(String p0) {
    return ', room $p0';
  }

  @override
  String checkNamedField(String p0) {
    return 'Check the $p0 field.';
  }

  @override
  String invalidNamedFile(String p0) {
    return 'Invalid file: $p0.';
  }

  @override
  String portalStatus(String p0) {
    return 'Portal status: $p0';
  }

  @override
  String get aiTitle => 'Assistant';

  @override
  String get aiSubtitle => 'Schedule and university documents';

  @override
  String get aiWelcome => 'How can I help?';

  @override
  String get aiIntro =>
      'Find your classes and understand university documents, with sources you can check.';

  @override
  String get aiTomorrow => 'What is my schedule tomorrow?';

  @override
  String get aiScholarship => 'How do I get a social scholarship?';

  @override
  String get aiDorm => 'How do I move into a dormitory?';

  @override
  String get aiHint =>
      'Do not send passwords, personal documents or private information. The chat stays in app memory until sign-out or restart.';

  @override
  String get aiInput => 'Message…';

  @override
  String get aiSend => 'Send';

  @override
  String get aiClear => 'Clear chat and reset permission';

  @override
  String get aiThinking => 'Checking the schedule and sources…';

  @override
  String get aiPrivacyTitle => 'Before your first document question';

  @override
  String get aiPrivacyBody =>
      'To prepare an answer, UNIO sends your question, the previous question when you ask a follow-up, and public reference excerpts to an external AI service. Your login, password, account token and grades are not sent. Schedules, news and grades do not require a model request. Do not enter personal data. Permission lasts until you clear the chat or sign out; it does not delete questions already sent to the provider.';

  @override
  String get aiAllow => 'Allow and send question';

  @override
  String get aiNotNow => 'Not now';

  @override
  String get aiOffTopic =>
      'I help with schedules and university documents. Try asking about a scholarship or dormitory.';

  @override
  String get aiSensitive =>
      'Your question may contain personal data or secrets. Remove them and ask in general terms.';

  @override
  String get aiInsufficient =>
      'The reviewed documents do not contain enough information. Try a more specific question or check with the university.';

  @override
  String get aiNotConfigured =>
      'The assistant is not configured on the server yet. Please try later.';

  @override
  String get aiChooseDate =>
      'Which day? Say today, tomorrow, a weekday, or a date as YYYY-MM-DD.';

  @override
  String get aiDateRange => 'You can check dates within two weeks of today.';

  @override
  String get aiChooseGroup => 'Choose your group in the schedule first.';

  @override
  String get aiScheduleUnavailable =>
      'The schedule could not be loaded. This does not mean there are no classes. Please try later.';

  @override
  String get aiPermissionRequired =>
      'Document answers require permission to send your question to the AI service. Send the question again.';

  @override
  String get aiAuthRequired =>
      'Your UNIO session has expired. Sign in again to continue.';

  @override
  String get aiLimit =>
      'The assistant request limit has been reached. Please try later.';

  @override
  String get aiBusy => 'The assistant is busy. Try again in a few seconds.';

  @override
  String get aiUnavailable =>
      'Could not prepare an answer. Check your connection and try later.';

  @override
  String get aiNoLessons => 'There are no classes listed for this day.';

  @override
  String get aiScheduleSource =>
      'From the UNIO schedule service. The portal may have updates.';

  @override
  String get aiSourceNotice =>
      'Check the conditions in the original. An assistant answer does not replace a university decision.';

  @override
  String get aiPage => 'Page';

  @override
  String get aiOpenSource => 'Open original';

  @override
  String get aiSearching => 'Finding information…';

  @override
  String get aiWriting => 'Preparing an answer…';

  @override
  String get aiLoadingSchedule => 'Checking your schedule…';

  @override
  String get aiSources => 'Sources';

  @override
  String get aiFollowup => 'Which documents are needed?';

  @override
  String get aiDayAfter => 'Schedule for the day after tomorrow';

  @override
  String get aiNewsLatest => 'Here are the latest university publications.';

  @override
  String aiNewsOnDate(String date) {
    return 'News for $date';
  }

  @override
  String get aiNewsEmpty =>
      'There are no saved publications for this day. Try the latest news or a different date.';

  @override
  String get aiNewsChooseDate =>
      'Which day? For example, “news for 21 October 2026” or “news from yesterday”.';

  @override
  String get aiNewsUnavailable =>
      'Could not load the news. Please try again later.';

  @override
  String get aiAllNews => 'All news';

  @override
  String get aiReadNews => 'Read full article';

  @override
  String get aiRequestsHelp =>
      'You can request a certificate or submit an application through the VSSPU portal or in UNIO’s Certificates and applications section. Portal sign-in is required.';

  @override
  String get aiOpenPortal => 'Open the VSSPU portal';

  @override
  String get aiReferenceNotice =>
      'This information is for reference. AI can make mistakes; check important details against official sources. Answers do not replace professional advice, including medical advice.';

  @override
  String get aiLoadingGrades => 'Checking your grades…';

  @override
  String get aiGradesFromPortal =>
      'From the Grades section. Checkpoint scores are cumulative; do not add them together.';

  @override
  String get aiOpenGrades => 'Open grades';

  @override
  String get aiGradesAuthRequired =>
      'Your grades require VSSPU portal sign-in. Open the section and connect your university account.';

  @override
  String get aiGradesUnavailable =>
      'Could not load your grades. Try later or refresh the Grades section.';

  @override
  String get aiGradesEmpty =>
      'The portal has not returned any grades yet. This does not mean your scores are zero.';

  @override
  String get aiGradesNotFound =>
      'No matching subject or semester was found in your grades. Try the full subject name, for example: “What are my grades in Russian for semester 2?”';

  @override
  String get aiHistory => 'Chat history';

  @override
  String get aiNewChat => 'New chat';

  @override
  String get aiHistorySearch => 'Search conversations';

  @override
  String get aiHistoryLocal => 'History is saved only on this device.';

  @override
  String get aiHistoryExternal =>
      'Document questions are sent to an external AI service after permission.';

  @override
  String get aiHistoryEmpty => 'Your conversations will appear here';

  @override
  String get aiHistoryNoResults => 'No conversations found';

  @override
  String get aiRename => 'Rename';

  @override
  String get aiDeleteChat => 'Delete chat';

  @override
  String get aiDeleteChatBody =>
      'The conversation and its cards will be deleted from this device.';

  @override
  String get aiDeleteHistory => 'Clear all history';

  @override
  String get aiDeleteHistoryBody =>
      'All conversations and drafts for this account will be deleted from this device. This cannot be undone.';

  @override
  String get aiCancelAction => 'Cancel';

  @override
  String get aiDeleteAction => 'Delete';

  @override
  String get aiSaveAction => 'Save';

  @override
  String get aiTodayGroup => 'Today';

  @override
  String get aiYesterdayGroup => 'Yesterday';

  @override
  String get aiWeekGroup => 'Last 7 days';

  @override
  String get aiEarlierGroup => 'Earlier';

  @override
  String get aiUntitled => 'New conversation';

  @override
  String get aiCopy => 'Copy';

  @override
  String get aiCopied => 'Answer copied';

  @override
  String get aiRetry => 'Retry';

  @override
  String get aiHelpful => 'Helpful';

  @override
  String get aiNotHelpful => 'Not helpful';

  @override
  String get aiStop => 'Stop response';

  @override
  String get aiInterrupted =>
      'Response interrupted. Received blocks were saved; the answer may be incomplete.';

  @override
  String get aiNetworkError =>
      'Could not reach the server. Check your connection and try again.';

  @override
  String get aiHistoryFailure =>
      'History could not be saved. Messages are currently available only in this session. Check free space and storage access.';

  @override
  String get aiHistoryRetry => 'Check storage';

  @override
  String get aiLoadOlder => 'Show earlier messages';

  @override
  String get aiReturnSchedule => 'Back to schedule';

  @override
  String get aiSourceUnavailable => 'No official link provided';

  @override
  String get aiStarterGrades => 'Show my grades';

  @override
  String get aiStarterRequests => 'How can I order a certificate?';

  @override
  String get aiContactsFollowup => 'Who should I contact?';

  @override
  String get aiEligibilityFollowup => 'Who is eligible?';

  @override
  String get aiNewsFollowup => 'Show the latest news';

  @override
  String get aiTomorrowFirst => 'What is my first class tomorrow?';

  @override
  String get aiHistoryBrowser =>
      'Browser history may be lost when site data is cleared or private browsing ends.';

  @override
  String get aiLegacy => 'Message from a different app version';

  @override
  String get aiOpenStatements => 'Open applications';
}

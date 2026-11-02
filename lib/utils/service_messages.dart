import '../services/locale_service.dart';

String get connectionMessage =>
    l10n.uiCouldNotConnectCheckYourInternetConnectionAnd;
String get unavailableMessage =>
    l10n.uiTheServiceIsTemporarilyUnavailablePleaseTryAgain;
String get retryMessage => l10n.uiCouldNotCompleteThisActionPleaseTryAgain;

String responseMessage(int status) => switch (status) {
      401 => l10n.uiSignInAgainAndRetryThisAction,
      403 => l10n.uiThisActionIsCurrentlyUnavailableForYourAccount,
      404 => l10n.uiCouldNotFindTheRequestedDataTryRefreshing,
      400 || 422 => l10n.uiCheckYourDetailsAndTryAgain,
      408 || 504 => l10n.uiTheResponseIsTakingLongerThanExpectedPlease,
      429 => l10n.uiTooManyAttemptsPleaseWaitALittleAnd,
      _ => unavailableMessage,
    };

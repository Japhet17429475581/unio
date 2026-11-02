import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/services/api_service.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/utils/user_messages.dart';

void main() {
  test(
      'Technical errors are replaced without misreporting an outage as no internet',
      () {
    expect(
        userMessage(
            ApiException('Backend не запущен: traceback at /secret/path')),
        unavailableMessage);
    expect(
        userMessage(const DirectPortalException(
            'Страница: портал вернул ошибку (HTTP 503)')),
        unavailableMessage);
    expect(userMessage(ApiException('Не удалось подключиться к серверу.')),
        connectionMessage);
    expect(userMessage(StateError('Sensitive diagnostic data')), retryMessage);
    expect(userMessage(const DirectPortalException('Сессия портала истекла.')),
        contains('Войдите'));
  });
  test('Actionable validation and unfinished draft messages survive', () {
    for (final message in [
      'Проверьте логин и пароль',
      'Выберите файл размером до 20 МБ.',
      'Подождите немного — получаем информацию.'
    ]) {
      expect(userMessage(DirectPortalException(message)), message);
    }
  });
}

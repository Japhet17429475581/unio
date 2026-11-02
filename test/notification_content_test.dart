import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/models/notification_content.dart';
import 'package:unio_app/models/notification_plan.dart';
import 'package:unio_app/models/portal_request.dart';

void main() {
  test('Legacy plans retain server text when lesson data is missing', () {
    final content = NotificationContent.lesson(NotificationItem.fromJson({
      'title': 'Пара скоро начнётся',
      'body': 'Математика · в 08:30',
      'minutes_before': 60,
    }));
    expect(content.title, 'Пара скоро начнётся');
    expect(content.body, 'Математика · в 08:30');
    expect(content.subtitle, 'Через час');
    expect(content.expandedBody, content.body);
  });
  test('Whitespace and room prefixes do not spoil the compact reminder', () {
    final content = NotificationContent.lesson(NotificationItem.fromJson({
      'lesson': {
        'subject': '  Иностранный\nязык  ',
        'start': '10:10',
        'room': 'ауд. 314'
      },
    }));
    expect(content.title, 'Иностранный язык');
    expect(content.body, '10:10 · ауд. 314');
    expect(content.expandedBody, isNot(contains('null')));
  });
  for (final status in ['получение информации', 'На обработке', 'Готово']) {
    test(
        'Request status $status has useful text without invented pickup details',
        () {
      final item = RequestListItem(
          id: '101',
          title: 'Справка о доходах',
          category: '',
          status: status,
          updated: '',
          editUrl: '');
      final content =
          NotificationContent.request(item, ready: status == 'Готово');
      expect(content.body, contains(item.title));
      expect(content.expandedBody, contains('Заявление №101'));
      expect(content.expandedBody, contains(item.displayStatus));
      if (item.canFill) expect(content.title, 'Можно заполнить заявление');
      if (status == 'Готово') expect(content.title, 'Документ готов');
      expect(content.expandedBody, isNot(contains('деканат')));
    });
  }
}

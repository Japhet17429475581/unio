import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/models/lesson.dart';
import 'package:unio_app/models/teacher_schedule.dart';
import 'package:unio_app/screens/request_form_screen.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/widgets/feature_header.dart';
import 'redesign_test.dart' show mount, preview;
import 'support/portal_fakes.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('Onest');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      fonts.addFont(rootBundle.load('assets/fonts/Onest-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  test('Timetable orders unpadded times numerically and unknown times last',
      () {
    Lesson lesson(String start, {int day = 13}) => Lesson(
        date: DateTime(2026, 10, day),
        start: start,
        end: '',
        subject: 'Предмет',
        type: null,
        teacher: '',
        room: '');
    final lessons = [
      lesson('15:00'),
      lesson('9:40'),
      lesson('11:30'),
      lesson('13:10'),
      lesson(''),
      lesson(' 08:00 '),
      lesson('не указано'),
      lesson('7:30', day: 14)
    ]..sort(compareLessons);
    expect(lessons.take(5).map((l) => l.start),
        [' 08:00 ', '9:40', '11:30', '13:10', '15:00']);
    expect(lessons.last.date, DateTime(2026, 10, 14));
    expect(lessonMinutes('25:00'), isNull);
    expect(lessonMinutes('9:65'), isNull);
    final schedule = TeacherSchedule.fromJson({
      'groups': {'preview': <String>[], 'total': 0, 'has_more': false},
      'lessons': [
        for (final start in ['15:00', '9:40', '11:30'])
          {
            'date': '2026-10-13',
            'start': start,
            'end': '16:00',
            'subject': 'Предмет'
          }
      ]
    });
    expect(schedule.lessons.map((l) => l.start), ['9:40', '11:30', '15:00']);
  });

  for (final brightness in Brightness.values) {
    for (final income in [true, false]) {
      testWidgets(
          'Form values survive rebuild and remain readable: $brightness income=$income',
          (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        FlutterSecureStorage.setMockInitialValues({
          'portal_login': 'fixture',
          'portal_password': 'fixture',
          'is_portal_mode': 'true',
          'account_token': 'fixture'
        });
        DirectPortalClient.testFactory = () => fakePortal((o) {
              if (o.uri.path == '/login')
                return page(
                    o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
              if (o.uri.path == '/request/index') return page(portalListHtml);
              return page(income ? incomeFormHtml : portalFormHtml);
            });
        addTearDown(() => DirectPortalClient.testFactory = null);
        await tester.runAsync(() => mount(
            tester, const RequestFormScreen(requestId: '101'),
            brightness: brightness, size: const Size(360, 800), settle: false));
        for (var i = 0;
            i < 100 && find.byType(FeatureHeader).evaluate().isEmpty;
            i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 15)));
          await tester.pump(const Duration(milliseconds: 30));
        }
        await tester.pumpAndSettle();
        final input = find.byKey(
            ValueKey('request-input-${income ? 'field_166' : 'field_31'}'));
        await tester.ensureVisible(input);
        await tester.enterText(input, income ? '2' : 'Учебная организация');
        await tester.pumpAndSettle();
        // Changing a dropdown rebuilds the form. Entered text must survive.
        final select = find.byType(DropdownButtonFormField<String>).first;
        await tester.ensureVisible(select);
        await tester.tap(select);
        await tester.pumpAndSettle();
        await tester.tap(
            find.text(income ? 'По почте России' : 'Иная организация').last);
        await tester.pumpAndSettle();
        expect(
            find
                .text(income ? 'По почте России' : 'Иная организация')
                .hitTestable(),
            findsOneWidget);
        await tester.ensureVisible(input);
        final editable = tester.widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)));
        expect(editable.controller.text, income ? '2' : 'Учебная организация');
        final theme = Theme.of(tester.element(input));
        expect(editable.style.color, theme.colorScheme.onSurface);
        await preview(tester,
            'form-${income ? 'income' : 'organization'}-${brightness.name}');
        // The action stays reachable with the keyboard and enlarged text.
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        await tester.pumpAndSettle();
        final send = find.text('Отправить на обработку');
        await tester.scrollUntilVisible(send, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(send.hitTestable(), findsOneWidget);
        expect(tester.getRect(send).bottom, lessThan(540));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

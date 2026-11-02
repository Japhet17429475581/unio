import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/screens/gradebook_tab.dart';
import 'package:unio_app/services/portal_service.dart';
import 'package:unio_app/services/direct_portal_client.dart';
import 'package:unio_app/widgets/subject_card.dart';
import 'redesign_test.dart' show mount, preview;
import 'support/portal_fakes.dart';

// Structural fixture: header/classes from supplied HTML; rows are synthetic.
// Actual populated portal rows were not supplied and still need device validation.
String academicRow(String name, String points, String grade) => '''
<tr><td class="AcademicProgress-Subject">$name</td>
<td class="AcademicProgress-Section AcademicProgress1"><div class="tdRow"><div class="tdItem">19</div><div class="tdItem">0</div></div></td>
<td class="AcademicProgress-Section AcademicProgress2"><div class="tdRow"><div class="tdItem">54</div><div class="tdItem">2</div></div></td>
<td class="AcademicProgress-Section AcademicProgress3"><div class="tdRow"><div class="tdItem">60</div><div class="tdItem">2</div></div></td>
<td class="AcademicProgress-Result"><div class="tdRow"><div class="tdItem tdItemSmall">$points</div><div class="tdItem tdItemBig">$grade</div></div></td></tr>''';

const academicHeader =
    '<tr class="AcademicProgressHeaderTr"><td class="AcademicProgress-Subject">Дисциплина</td><td class="AcademicProgress1">1й срез</td></tr>';
String academicPage() => '''<div class="AcademicProgress">
<div class="AcademicProgress-Semester"><h3>2 семестр</h3><table>$academicHeader
${academicRow('Иностранный язык', '91', 'зачтено')}
${academicRow('История русской литературы', '82', 'хорошо')}
${academicRow('Педагогика', '', '')}</table></div>
<div class="AcademicProgress-Semester"><h3>1 семестр</h3><table>$academicHeader
${academicRow('Математика', '0', 'не зачтено')}</table></div></div>''';

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
  test('AcademicProgress keeps three cuts, absences, points and literal grades',
      () {
    final result = parsePortalGrades(academicPage());
    expect(result.subjects.length, 4);
    final subject = result.subjects.first;
    expect(subject.semester, 2);
    expect(subject.firstCut?.score, '19');
    expect(subject.firstCut?.hours, '0');
    expect(subject.secondCut?.hours, '2');
    expect(subject.thirdCut?.score, '60');
    expect(subject.exam?.points, '91');
    expect(subject.exam?.grade, 'зачтено');
    expect(result.subjects.last.exam?.points, '0');
    expect(result.subjects[2].exam?.points, '');
  });
  test(
      'Supplied empty table is an empty state, not a parsing error or fake subject',
      () {
    final result = parsePortalGrades(
        '<div class="AcademicProgress"><div class="AcademicProgress-Semester"><table>$academicHeader</table></div></div>');
    expect(result.success, isTrue);
    expect(result.subjects, isEmpty);
    expect(
        parsePortalGrades(
                '<div class="AcademicProgress"><div class="AcademicProgress-Semester"><table>${academicRow('Предмет', '', '')}</table></div></div>')
            .subjects
            .single
            .semester,
        0);
    expect(() => parsePortalGrades('<html>Temporary maintenance</html>'),
        throwsA(isA<DirectPortalException>()));
  });
  for (final brightness in Brightness.values) {
    testWidgets(
        'Gradebook semester switch and details on narrow screen: $brightness',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({
        'account_token': 'fixture',
        'portal_login': 'fixture',
        'portal_password': 'fixture',
        'is_portal_mode': 'true'
      });
      DirectPortalClient.testFactory = () => fakePortal((o) {
            if (o.uri.path == '/login')
              return page(
                  o.method == 'GET' ? portalLoginHtml : portalLoggedInHtml);
            expect(o.uri.path, '/progress/index');
            return page(academicPage());
          });
      addTearDown(() => DirectPortalClient.testFactory = null);
      await tester.runAsync(() => mount(
          tester,
          Scaffold(
              body: GradebookTab(
                  isPortalMode: true, onUpgradeToPortal: (_, __) async {})),
          brightness: brightness,
          settle: false));
      for (var i = 0;
          i < 100 && find.byType(SubjectCard).evaluate().isEmpty;
          i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 15)));
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pumpAndSettle();
      expect(find.text('91 б.'), findsOneWidget);
      expect(find.text('зачтено'), findsOneWidget);
      await preview(tester, 'gradebook-${brightness.name}');
      await tester.tap(find.text('Срезы и пропуски').first);
      await tester.pumpAndSettle();
      expect(find.text('Пропуски: 0 ч.'), findsOneWidget);
      expect(find.text('19 б.'), findsOneWidget);
      await preview(tester, 'gradebook-details-${brightness.name}');
      await tester.ensureVisible(find.text('1 семестр'));
      await tester.tap(find.text('1 семестр'));
      await tester.pumpAndSettle();
      expect(find.text('0 б.'), findsOneWidget);
      expect(find.text('не зачтено'), findsOneWidget);
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Срезы и пропуски'));
      await tester.tap(find.text('Срезы и пропуски'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

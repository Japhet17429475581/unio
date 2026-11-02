import 'package:html/parser.dart' as html;
import '../models/portal_progress.dart';
import 'direct_portal_client.dart';

typedef PortalApiException = DirectPortalException;

/// Personal grades go directly from the university to the device.
Future<PortalProgressResult> fetchPortalProgress(
        {required String login, required String password, String? uid}) =>
    withPortal(_readGrades, login: login, password: password);

Future<PortalProgressResult> fetchPortalGrades() =>
    withPortal(_readGrades, retryReadOnly: true);

Future<PortalProgressResult> _readGrades(DirectPortalClient client) async {
  final response = await client.request('/progress/index');
  return parsePortalGrades(response.data ?? '');
}

PortalProgressResult parsePortalGrades(String source) {
  final doc = html.parse(source);
  DirectPortalClient.requireSession(doc);
  final academic = doc.querySelector('.AcademicProgress');
  if (academic != null) {
    final subjects = <PortalSubject>[];
    for (final term
        in academic.querySelectorAll('.AcademicProgress-Semester')) {
      final heading = term.children
          .where((e) => ['h2', 'h3', 'h4'].contains(e.localName))
          .map((e) => portalText(e.text))
          .join(' ');
      final semesterMatch = RegExp(
              r'(\d+)\s*[-–]?\s*(?:й\s*)?семестр|семестр\s*(\d+)',
              caseSensitive: false)
          .firstMatch(heading);
      // Do not invent a semester if the portal supplies no label.
      final semester = int.tryParse(
              semesterMatch?.group(1) ?? semesterMatch?.group(2) ?? '') ??
          0;
      for (final row in term.querySelectorAll('tr')) {
        if (row.classes.contains('AcademicProgressHeaderTr')) continue;
        final name =
            portalText(row.querySelector('.AcademicProgress-Subject')?.text);
        if (name.isEmpty) continue;
        PortalCut? cut(int index) {
          final cell = row.querySelector('.AcademicProgress$index');
          if (cell == null) return null;
          final items = cell.querySelectorAll('.tdItem');
          return PortalCut(
              score: items.isNotEmpty ? portalText(items[0].text) : null,
              hours: items.length > 1 ? portalText(items[1].text) : null);
        }

        final result = row.querySelector('.AcademicProgress-Result');
        final items = result?.querySelectorAll('.tdItem') ?? [];
        subjects.add(PortalSubject(
            semester: semester,
            subject: name,
            firstCut: cut(1),
            secondCut: cut(2),
            thirdCut: cut(3),
            exam: result == null
                ? null
                : PortalExamResult(
                    points: items.isNotEmpty ? portalText(items[0].text) : null,
                    grade:
                        items.length > 1 ? portalText(items[1].text) : null)));
      }
    }
    return PortalProgressResult(success: true, message: '', subjects: subjects);
  }
  final terms = doc.querySelectorAll('.progress-term');
  if (terms.isEmpty && doc.querySelector('.progress-summary') == null) {
    throw const DirectPortalException(
        'Не удалось прочитать успеваемость. Попробуйте обновить страницу позже.');
  }
  final subjects = <PortalSubject>[];
  for (var i = 0; i < terms.length; i++) {
    final title =
        portalText(terms[i].querySelector('.progress-term-title')?.text);
    final semester =
        int.tryParse(RegExp(r'\d+').firstMatch(title)?.group(0) ?? '') ?? i + 1;
    for (final row in terms[i].querySelectorAll('table.progress-table tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 3) continue;
      subjects.add(PortalSubject(
          semester: semester,
          subject: portalText(cells[0].text),
          exam: PortalExamResult(grade: portalText(cells[2].text))));
    }
  }
  return PortalProgressResult(
      success: true,
      message: '',
      subjects: subjects,
      student: PortalStudent(
          name: portalText(doc
              .querySelector('.user-name, .username, .profile-name')
              ?.text)));
}

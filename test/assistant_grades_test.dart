import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:unio_app/models/portal_progress.dart';
import 'package:unio_app/services/assistant_grades.dart';
import 'package:unio_app/services/assistant_service.dart';
import 'package:unio_app/services/portal_grades_repository.dart';
import 'package:unio_app/screens/assistant_screen.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/l10n/app_localizations.dart';
import 'package:unio_app/services/locale_service.dart';

const grades = PortalProgressResult(
    success: true,
    message: '',
    student: PortalStudent(name: 'PRIVATE NAME', email: 'private@example.test'),
    subjects: [
      PortalSubject(
          semester: 1,
          subject: 'Современный русский язык',
          exam: PortalExamResult(points: 76, grade: 'хорошо')),
      PortalSubject(
          semester: 2,
          subject: 'Современный русский язык',
          firstCut: PortalCut(score: 0, hours: 0),
          secondCut: PortalCut(score: 34, hours: 2),
          thirdCut: PortalCut(score: 54, hours: 2),
          exam: PortalExamResult(points: 0, grade: 'не зачтено')),
      PortalSubject(
          semester: 2,
          subject: 'История русской литературы',
          exam: PortalExamResult(points: 82, grade: 'хорошо')),
      PortalSubject(
          semester: 2,
          subject: 'Математика',
          exam: PortalExamResult(points: 91, grade: 'зачтено')),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [320.0, 430.0]) {
    testWidgets('Checkpoint card fits at $width and opens existing grades',
        (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await appLocale.load();
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      final chat = AssistantConversation(
          hasPortal: () async => true,
          grades: () async => grades,
          client: MockClient((_) async =>
              throw StateError('Personal grades must stay local')));
      await tester.pumpWidget(MaterialApp(
          theme: buildTheme(Brightness.dark),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssistantScreen(
              conversation: chat,
              group: 'TEST-101',
              onOpenGrades: () => opened = true)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Что у меня по русскому?');
      await tester.pump();
      await tester.tap(find.byTooltip(l10n.aiSend));
      await tester.pumpAndSettle();
      expect(find.text('Современный русский язык'), findsOneWidget);
      expect(find.text('История русской литературы'), findsNothing);
      expect(find.text(l10n.uiCheckpoint('1')), findsOneWidget);
      expect(find.text(l10n.uiCheckpoint('2')), findsOneWidget);
      expect(find.text(l10n.uiCheckpoint('3')), findsOneWidget);
      expect(find.text(l10n.uiPts('34')), findsOneWidget);
      expect(find.text(l10n.aiPrivacyTitle), findsNothing);
      await tester.ensureVisible(find.text(l10n.aiOpenGrades));
      await tester.tap(find.text(l10n.aiOpenGrades));
      expect(opened, true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      chat.dispose();
    });
  }
  test(
      'Personal grade requests stay distinct from scholarship/document questions',
      () {
    for (final q in [
      'Что у меня по русскому?',
      'Покажи мою успеваемость',
      'мои баллы по математике',
      'What are my grades in Russian?'
    ]) {
      expect(isAssistantGradesRequest(q), true, reason: q);
    }
    expect(isAssistantGradesRequest('Какой балл нужен для стипендии?'), false);
    expect(isAssistantGradesRequest('А по математике?', followup: true), true);
    expect(isAssistantGradesRequest('А по математике?'), false);
  });
  test(
      'Subject matching keeps checkpoint zeros, literal grades and latest matching semester',
      () {
    final data = assistantGradesResult('Что у меня по русскому?', grades);
    final subjects = data['subjects'] as List;
    expect(subjects.length, 1);
    expect(subjects.single['subject'], 'Современный русский язык');
    expect(subjects.single['semester'], 2);
    expect(subjects.single['first_cut']['score'], 0);
    expect(subjects.single['first_cut']['hours'], 0);
    expect(subjects.single['second_cut']['score'], 34);
    expect(subjects.single['exam']['grade'], 'не зачтено');
    expect(data.toString(), isNot(contains('PRIVATE NAME')));
    expect(data.toString(), isNot(contains('private@example.test')));
    expect(
        (assistantGradesResult(
                    'Что у меня по русскому за 1 семестр?', grades)['subjects']
                as List)
            .single['semester'],
        1);
    expect(
        (assistantGradesResult('What are my grades in Russian for semester 2?',
                grades)['subjects'] as List)
            .single['subject'],
        'Современный русский язык');
  });
  test('Missing subject, empty portal and failed portal are distinct results',
      () {
    expect(assistantGradesResult('Что у меня по астрономии?', grades)['status'],
        'grades_not_found');
    expect(
        assistantGradesResult('Покажи мои баллы',
            const PortalProgressResult(success: true, message: ''))['status'],
        'grades_empty');
    expect(
        assistantGradesResult(
            'Покажи мои баллы',
            const PortalProgressResult(
                success: false, message: 'private error'))['status'],
        'grades_unavailable');
  });
  test(
      'Chat reads local portal data and never calls assistant API or reads its token',
      () async {
    var reads = 0;
    final repo = PortalGradesRepository(loader: () async {
      reads++;
      return grades;
    });
    final chat = AssistantConversation(
        hasPortal: () async => true,
        grades: () => repo.load(),
        token: () async =>
            throw StateError('Must not read token for grade question'),
        client: MockClient(
            (_) async => throw StateError('Must not call assistant API')));
    await chat.send('Что у меня по русскому?', 'TEST-101');
    expect(chat.messages.last.response?['status'], 'grades');
    await chat.send('А по математике?', 'TEST-101');
    expect(chat.messages.last.response?['status'], 'grades');
    expect(reads, 1);
    expect(chat.allowExternal, false);
    chat.dispose();
    repo.clear();
  });
  test('Guest grade request does not read portal or send a model request',
      () async {
    var reads = 0, calls = 0;
    final chat = AssistantConversation(
        hasPortal: () async => false,
        grades: () async {
          reads++;
          return grades;
        },
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }));
    await chat.send('Что у меня по русскому?', 'TEST-101');
    expect(chat.messages.last.response?['status'], 'grades_auth_required');
    expect(reads, 0);
    expect(calls, 0);
    chat.dispose();
  });
  test('Shared RAM cache deduplicates loading, expires, refreshes and clears',
      () async {
    var now = DateTime(2026, 10, 26, 12), reads = 0;
    final pending = Completer<PortalProgressResult>();
    final repo = PortalGradesRepository(
        loader: () {
          reads++;
          return reads == 1 ? pending.future : Future.value(grades);
        },
        clock: () => now);
    final first = repo.load(), second = repo.load();
    expect(reads, 1);
    pending.complete(grades);
    await first;
    await second;
    await repo.load();
    expect(reads, 1);
    now = now.add(const Duration(minutes: 3));
    await repo.load();
    expect(reads, 2);
    await repo.load(refresh: true);
    expect(reads, 3);
    repo.clear();
    await repo.load();
    expect(reads, 4);
    repo.clear();
  });
  test('Logout drops personal messages and ignores a pending grade result',
      () async {
    final pending = Completer<PortalProgressResult>();
    final chat = AssistantConversation(
        hasPortal: () async => true, grades: () => pending.future);
    final future = chat.send('Что у меня по русскому?', 'TEST-101');
    await Future<void>.delayed(Duration.zero);
    chat.dispose();
    pending.complete(grades);
    await future;
    expect(chat.messages, isEmpty);
  });
  test('Failed explicit refresh does not silently restore an old grade cache',
      () async {
    var reads = 0;
    final repo = PortalGradesRepository(loader: () async {
      reads++;
      if (reads == 2) throw StateError('synthetic portal failure');
      return grades;
    });
    await repo.load();
    await expectLater(repo.load(refresh: true), throwsStateError);
    await repo.load();
    expect(reads, 3);
    repo.clear();
  });
}

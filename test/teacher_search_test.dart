import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unio_app/models/teacher_directory.dart';
import 'package:unio_app/services/api_service.dart';
import 'package:unio_app/services/teachers_service.dart';

Map<String, dynamic> directoryData() => {
      'success': true,
      'updated_at': '2026-10-09T09:00:00Z',
      'stale': false,
      'teachers': [
        {
          'fio': 'Гуляева Ирина Ивановна',
          'schedule_fios': ['Гуляева Ирина Ивановна']
        },
        {
          'fio': 'Гуляева Марина Петровна',
          'schedule_fios': ['Гуляева Марина Петровна']
        },
        {
          'fio': 'Ёршов Иван Иванович',
          'schedule_fios': ['Ёршов Иван Иванович']
        },
      ],
    };

Map<String, dynamic> teacherScheduleData(List<Map<String, dynamic>> lessons) =>
    {
      'success': true,
      'lessons': lessons,
      'groups': {
        'preview': ['TEST'],
        'total': 1,
        'has_more': false
      },
    };

Map<String, dynamic> teacherLesson(String subject,
        {String start = '09:00',
        String end = '10:30',
        String date = '2026-10-09',
        String room = '314'}) =>
    {
      'date': date,
      'start': start,
      'end': end,
      'subject': subject,
      'room': room,
      'group': 'TEST',
      'lesson_type': 'lecture',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'Initial/full duplicate merges all schedule keys, including saved directory',
      () {
    const short = 'Багаева З.Г.';
    const full = 'Багаева Зарина Геннадьевна';
    const joint = '$short, Иванова Анна Петровна';
    final directory = TeacherDirectory.fromJson({
      'teachers': [
        {
          'fio': short,
          'schedule_fios': [short, joint]
        },
        {
          'fio': full,
          'schedule_fios': [full]
        },
        {
          'fio': 'багаева З. Г.',
          'schedule_fios': ['багаева З. Г.']
        },
      ]
    }, isSaved: true);
    expect(directory.search('багаева').single.fio, full);
    expect(directory.teachers.single.scheduleFios.toSet(),
        {short, full, joint, 'багаева З. Г.'});
    expect(
        directory
            .resolve(const TeacherEntry(fio: short, scheduleFios: [short]))
            .fio,
        full);
    expect(directory.isSaved, isTrue);
  });

  test('Ambiguous initials and different full names stay separate', () {
    final entries = [
      'Иванова А.П.',
      'Иванова Анна Петровна',
      'Иванова Алла Павловна'
    ].map((name) => TeacherEntry(fio: name, scheduleFios: [name]));
    expect(mergeTeacherEntries(entries), hasLength(3));
    expect(mergeTeacherEntries(entries.toList().reversed), hasLength(3));
  });

  test('Partial FIO search accepts case, е/ё and multiple name fragments', () {
    final directory = TeacherDirectory.fromJson(directoryData());
    expect(directory.search(' ГУЛЯ ').map((e) => e.fio),
        ['Гуляева Ирина Ивановна', 'Гуляева Марина Петровна']);
    expect(directory.search('ерш').single.fio, 'Ёршов Иван Иванович');
    expect(directory.search('Гуля Ири').single.fio, 'Гуляева Ирина Ивановна');
    expect(directory.search('Г'), isEmpty);
    expect(directory.search('Несуществующий'), isEmpty);
  });

  test('Directory survives network failure without further portal credentials',
      () async {
    var offline = false;
    final calls = <http.Request>[];
    await http.runWithClient(() async {
      final first = await fetchTeacherDirectory();
      expect(first.isSaved, isFalse);
      offline = true;
      final saved = await fetchTeacherDirectory();
      expect(saved.isSaved, isTrue);
      expect(saved.search('Гуляева'), hasLength(2));
      expect(saved.updatedAt, DateTime.utc(2026, 10, 9, 9));
    },
        () => MockClient((request) async {
              calls.add(request);
              expect(request.url.path, '/api/v1/teachers/directory');
              expect(request.body, isEmpty);
              return http.Response(offline ? '{}' : jsonEncode(directoryData()),
                  offline ? 503 : 200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
    expect(calls, hasLength(2));
  });

  test('First failure and malformed directory never become an empty success',
      () async {
    await http.runWithClient(() async {
      await expectLater(fetchTeacherDirectory(), throwsA(isA<ApiException>()));
    },
        () => MockClient(
            (_) async => http.Response('{"success":true,"teachers":[]}', 200)));
  });

  test('Joint and individual schedules merge without losing distinct groups',
      () async {
    const teacher = TeacherEntry(fio: 'Первый преподаватель', scheduleFios: [
      'Первый преподаватель',
      'Первый преподаватель, Второй преподаватель'
    ]);
    final duplicate = teacherLesson('Совместное занятие');
    final anotherGroup = {...duplicate, 'group': 'OTHER'};
    final requested = <String>[];
    await http.runWithClient(() async {
      final result = await fetchTeacherLookupSchedule(teacher,
          date: DateTime(2026, 10, 9));
      expect(result.lessons, hasLength(3));
      expect(result.isPartial, isFalse);
      expect(result.isSaved, isFalse);
    },
        () => MockClient((request) async {
              final fio = request.url.queryParameters['fio']!;
              requested.add(fio);
              expect(request.url.queryParameters['date'], '2026-10-05');
              expect(request.url.queryParameters['week'], 'true');
              final lessons = fio == teacher.fio
                  ? [duplicate, teacherLesson('Личное занятие', start: '11:00')]
                  : [duplicate, anotherGroup];
              return http.Response(
                  jsonEncode(teacherScheduleData(lessons)), 200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }));
    expect(requested.toSet(), teacher.scheduleFios.toSet());
  });

  test('Failed joint schedule is explicitly marked as incomplete', () async {
    const teacher = TeacherEntry(
        fio: 'Преподаватель',
        scheduleFios: ['Преподаватель', 'Совместная запись']);
    await http.runWithClient(() async {
      final result = await fetchTeacherLookupSchedule(teacher,
          date: DateTime(2026, 10, 9));
      expect(result.isPartial, isTrue);
      expect(result.lessons, isEmpty);
    },
        () => MockClient((request) async => http.Response(
            request.url.queryParameters['fio'] == 'Совместная запись'
                ? '{}'
                : jsonEncode(teacherScheduleData([])),
            request.url.queryParameters['fio'] == 'Совместная запись'
                ? 503
                : 200)));
  });

  test(
      'Cached teacher schedule is marked offline and recent searches do not change account mode',
      () async {
    const teacher = TeacherEntry(
        fio: 'Гуляева Ирина Ивановна',
        scheduleFios: ['Гуляева Ирина Ивановна']);
    SharedPreferences.setMockInitialValues({
      'teacher_fio': 'Другой аккаунт',
      'teacher_schedule_cache_${teacher.fio}_2026-10-05_week':
          jsonEncode(teacherScheduleData([teacherLesson('История')])),
    });
    await http.runWithClient(() async {
      final result = await fetchTeacherLookupSchedule(teacher,
          date: DateTime(2026, 10, 9));
      expect(result.isSaved, isTrue);
      expect(result.lessons.single.subject, 'История');
    }, () => MockClient((_) async => throw const FormatException('offline')));
    await saveRecentTeachers([teacher]);
    expect((await loadRecentTeachers()).single.fio, teacher.fio);
    expect((await SharedPreferences.getInstance()).getString('teacher_fio'),
        'Другой аккаунт');
  });
}

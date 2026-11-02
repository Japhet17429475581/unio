import '../models/portal_progress.dart';

bool isAssistantGradesRequest(String question, {bool followup = false}) {
  final q = question.toLowerCase();
  if (RegExp(r'новост|стипенд|scholarship|\bnews\b').hasMatch(q)) return false;
  final grade = RegExp(
          r'успеваем|балл|оценк|срез|зач[её]т|\bgrades?\b|\bscores?\b|\bmarks?\b')
      .hasMatch(q);
  final personal =
      RegExp(r'(?:^|\s)(?:меня|мои|мой|мо[яеёю]|мне|my|me)(?:\s|[?.,!]|$)')
          .hasMatch(q);
  return (grade &&
          (personal ||
              RegExp(r'покажи|посмотр|откро|show|check').hasMatch(q))) ||
      RegExp(r'что\s+у\s+меня\s+по\s|как\s+у\s+меня\s+(?:по|с)\s|how am i doing in|what are my')
          .hasMatch(q) ||
      (followup && RegExp(r'^(?:а\s+)?по\s|^and\s+(?:in|for)\s').hasMatch(q));
}

Map<String, dynamic> assistantGradesResult(
    String question, PortalProgressResult progress) {
  if (!progress.success) return {'status': 'grades_unavailable'};
  if (progress.subjects.isEmpty) return {'status': 'grades_empty'};
  final q = question.toLowerCase().replaceAll('ё', 'е');
  final term = RegExp(
          r'(\d{1,2})\s*[-–]?\s*(?:й\s*)?семестр|(?:semester|term)\s*(\d{1,2})')
      .firstMatch(q);
  final semester = int.tryParse(term?.group(1) ?? term?.group(2) ?? '');
  var subjectQuery =
      RegExp(r'(?:^|\s)по\s+(.+)|(?:\bin|\bfor)\s+(.+)', caseSensitive: false)
          .firstMatch(q);
  var query = (subjectQuery?.group(1) ?? subjectQuery?.group(2) ?? '')
      .replaceAll(
          RegExp(
              r'(?:за|в)\s+(?:этот|этом|прошлый|прошлом|\d+).*семестр.*|(?:semester|term)\s*\d+'),
          '')
      .replaceAll(RegExp(r'\d+\s*(?:й\s*)?семестр'), '')
      .replaceAll(RegExp(r'\b(?:for|in)\s*[?!.]*\s*$'), '')
      .trim();
  const translations = {
    'russian': 'русский',
    'language': 'язык',
    'mathematics': 'математика',
    'math': 'математика',
    'history': 'история',
    'physics': 'физика',
    'chemistry': 'химия',
    'biology': 'биология',
    'psychology': 'психология',
    'literature': 'литература',
    'english': 'английский'
  };
  query = query.replaceAllMapped(
      RegExp(r'\b[a-z]+\b'), (m) => translations[m[0]] ?? m[0]!);
  // Common short subject questions may omit "по".
  if (query.isEmpty && RegExp(r'русск|russian').hasMatch(q))
    query = 'русский язык';
  if (RegExp(r'^русск[а-я]*[?!.\s]*$').hasMatch(query)) query = 'русский язык';
  final stop = {
    'у',
    'меня',
    'мои',
    'мой',
    'баллы',
    'балл',
    'оценки',
    'оценка',
    'срезы',
    'срез',
    'предмету',
    'предмет',
    'please',
    'my',
    'scores',
    'grades'
  };
  final tokens = RegExp(r'[а-яa-z]+')
      .allMatches(query)
      .map((m) => m[0]!)
      .where((s) => s.length >= 3 && !stop.contains(s))
      .map((s) => s.length > 5
          ? s.substring(0, 5)
          : s.substring(0, s.length > 3 ? s.length - 1 : s.length))
      .toList();
  var subjects = progress.subjects.where((s) {
    if (semester != null && s.semester != semester) return false;
    final name = s.subject.toLowerCase().replaceAll('ё', 'е');
    return tokens.every(name.contains);
  }).toList();
  if (subjects.isEmpty) return {'status': 'grades_not_found'};
  if (semester == null) {
    final latest =
        subjects.map((s) => s.semester).reduce((a, b) => a > b ? a : b);
    subjects = subjects.where((s) => s.semester == latest).toList();
  }
  return {
    'status': 'grades',
    'subjects': subjects.take(8).map(_subject).toList(),
    'has_more': subjects.length > 8
  };
}

Map<String, dynamic> _subject(PortalSubject s) {
  Map<String, dynamic>? cut(PortalCut? c) =>
      c == null ? null : {'score': c.score, 'hours': c.hours};
  return {
    'subject': s.subject,
    'semester': s.semester,
    'first_cut': cut(s.firstCut),
    'second_cut': cut(s.secondCut),
    'third_cut': cut(s.thirdCut),
    'exam': s.exam == null
        ? null
        : {'points': s.exam!.points, 'grade': s.exam!.grade}
  };
}

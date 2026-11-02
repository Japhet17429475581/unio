/// Одна контрольная точка: накопленные баллы + пропущенные часы.
/// Оба поля могут быть числом, текстом ("зачёт", "—") или отсутствовать.
class PortalCut {
  final dynamic score;
  final dynamic hours;

  const PortalCut({this.score, this.hours});

  factory PortalCut.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PortalCut();
    return PortalCut(score: json['score'], hours: json['hours']);
  }

  bool get isEmpty => score == null && hours == null;
}

/// Итоговый результат по предмету: баллы + оценка/зачёт.
class PortalExamResult {
  final dynamic points;
  final dynamic grade;

  const PortalExamResult({this.points, this.grade});

  factory PortalExamResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PortalExamResult();
    return PortalExamResult(points: json['points'], grade: json['grade']);
  }

  bool get isEmpty => points == null && grade == null;
}

class PortalSubject {
  final int semester;
  final String subject;
  final PortalCut? firstCut;
  final PortalCut? secondCut;
  final PortalCut? thirdCut;
  final PortalExamResult? exam;

  const PortalSubject({
    required this.semester,
    required this.subject,
    this.firstCut,
    this.secondCut,
    this.thirdCut,
    this.exam,
  });

  factory PortalSubject.fromJson(Map<String, dynamic> json) {
    PortalCut? cut(String key) {
      final raw = json[key];
      return raw == null
          ? null
          : PortalCut.fromJson(raw as Map<String, dynamic>);
    }

    final rawExam = json['exam'];

    return PortalSubject(
      semester: (json['semester'] as num?)?.toInt() ?? 1,
      subject: (json['subject'] ?? '').toString(),
      firstCut: cut('first_cut'),
      secondCut: cut('second_cut'),
      thirdCut: cut('third_cut'),
      exam: rawExam == null
          ? null
          : PortalExamResult.fromJson(rawExam as Map<String, dynamic>),
    );
  }
}

class PortalStudent {
  final String? name;
  final String? email;

  const PortalStudent({this.name, this.email});

  factory PortalStudent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PortalStudent();
    return PortalStudent(
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}

class PortalProgressResult {
  final bool success;
  final String message;
  final PortalStudent? student;
  final String? uid;
  final List<PortalSubject> subjects;

  const PortalProgressResult({
    required this.success,
    required this.message,
    this.student,
    this.uid,
    this.subjects = const [],
  });

  factory PortalProgressResult.fromJson(Map<String, dynamic> json) {
    final rawSubjects = (json['subjects'] as List?) ?? const [];

    return PortalProgressResult(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      student: json['student'] == null
          ? null
          : PortalStudent.fromJson(json['student'] as Map<String, dynamic>),
      uid: json['uid'] as String?,
      subjects: rawSubjects
          .map((e) => PortalSubject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

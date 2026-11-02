import 'lesson.dart';

String normalizeTeacherSearch(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class TeacherEntry {
  final String fio;
  final List<String> scheduleFios;
  const TeacherEntry({required this.fio, required this.scheduleFios});

  factory TeacherEntry.fromJson(Map<String, dynamic> json) {
    final name = json['fio'];
    final keys = json['schedule_fios'];
    if (name is! String ||
        name.trim().isEmpty ||
        keys is! List ||
        keys.isEmpty ||
        keys.any((key) => key is! String || key.trim().isEmpty)) {
      throw const FormatException('Некорректная запись справочника');
    }
    return TeacherEntry(
        fio: name, scheduleFios: keys.cast<String>().toSet().toList());
  }

  Map<String, dynamic> toJson() => {'fio': fio, 'schedule_fios': scheduleFios};
}

List<String> _nameParts(String name) => RegExp(r'[а-яa-z-]+')
    .allMatches(normalizeTeacherSearch(name))
    .map((match) => match.group(0)!)
    .toList();

/// Only an unambiguous initial/full-name match is merged. All portal keys stay.
List<TeacherEntry> mergeTeacherEntries(Iterable<TeacherEntry> entries) {
  final unique = <String, TeacherEntry>{};
  String key(String name) => _nameParts(name).join(' ');
  void add(String target, TeacherEntry entry) {
    final previous = unique[target];
    unique[target] = TeacherEntry(
        fio: previous?.fio ?? entry.fio,
        scheduleFios:
            {...?previous?.scheduleFios, ...entry.scheduleFios}.toList());
  }

  for (final entry in entries) {
    add(key(entry.fio), entry);
  }
  final full = unique.entries.where((entry) {
    final parts = _nameParts(entry.value.fio);
    return parts.length >= 2 && parts.every((part) => part.length > 1);
  }).toList();
  for (final entry in unique.entries.toList()) {
    final parts = _nameParts(entry.value.fio);
    if (parts.length < 2 || !parts.skip(1).any((part) => part.length == 1)) {
      continue;
    }
    final candidates = full.where((candidate) {
      final other = _nameParts(candidate.value.fio);
      return parts.length == other.length &&
          parts.first == other.first &&
          List.generate(parts.length - 1, (i) => i + 1).every((i) =>
              parts[i] == other[i] ||
              (parts[i].length == 1 && other[i].startsWith(parts[i])));
    }).toList();
    if (candidates.length == 1) {
      add(candidates.single.key, entry.value);
      unique.remove(entry.key);
    }
  }
  return unique.values.toList();
}

class TeacherDirectory {
  final List<TeacherEntry> teachers;
  final bool isSaved;
  final DateTime? updatedAt;
  const TeacherDirectory(
      {required this.teachers, this.isSaved = false, this.updatedAt});

  factory TeacherDirectory.fromJson(Map<String, dynamic> json,
      {bool isSaved = false}) {
    final raw = json['teachers'];
    if (raw is! List || raw.isEmpty)
      throw const FormatException('Пустой справочник');
    return TeacherDirectory(
        teachers: mergeTeacherEntries(raw
            .map((item) => TeacherEntry.fromJson(item as Map<String, dynamic>))
            .toList()),
        isSaved: isSaved || json['stale'] == true,
        updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'));
  }

  TeacherEntry resolve(TeacherEntry entry) {
    final name = _nameParts(entry.fio).join(' ');
    final exact = teachers.where((t) => _nameParts(t.fio).join(' ') == name);
    if (exact.isNotEmpty) return exact.first;
    final aliases = teachers
        .where((teacher) => teacher.scheduleFios.any((fio) =>
            fio.split(',').any((part) => _nameParts(part).join(' ') == name)))
        .toList();
    return aliases.length == 1 ? aliases.single : entry;
  }

  List<TeacherEntry> search(String query) {
    final normalized = normalizeTeacherSearch(query);
    if (normalized.length < 2) return [];
    final tokens = normalized.split(' ');
    final matches = teachers.where((entry) {
      final name = normalizeTeacherSearch(entry.fio);
      return tokens.every(name.contains);
    }).toList();
    matches.sort((a, b) {
      final first = normalizeTeacherSearch(a.fio);
      final second = normalizeTeacherSearch(b.fio);
      final rank = (first.startsWith(normalized) ? 0 : 1)
          .compareTo(second.startsWith(normalized) ? 0 : 1);
      return rank != 0 ? rank : first.compareTo(second);
    });
    return matches;
  }
}

class TeacherLookupSchedule {
  final List<Lesson> lessons;
  final bool isSaved;
  final bool isPartial;
  const TeacherLookupSchedule(
      {required this.lessons, this.isSaved = false, this.isPartial = false});
}

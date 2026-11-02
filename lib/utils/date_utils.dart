import '../services/locale_service.dart';

List<String> get _weekdaysFull => [
      l10n.uiMonday,
      l10n.uiTuesday,
      l10n.uiWednesday,
      l10n.uiThursday,
      l10n.uiFriday,
      l10n.uiSaturday,
      l10n.uiSunday,
    ];

List<String> get _monthsGen => [
      l10n.uiJanuary,
      l10n.uiFebruary,
      l10n.uiMarch,
      l10n.uiApril,
      l10n.uiMay,
      l10n.uiJune,
      l10n.uiJuly,
      l10n.uiAugust,
      l10n.uiSeptember,
      l10n.uiOctober,
      l10n.uiNovember,
      l10n.uiDecember,
    ];

String _two(int n) => n.toString().padLeft(2, '0');

/// 2026-09-21 — формат, который бэк ждёт в параметре date
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Понедельник недели, в которую попадает [d]
DateTime mondayOf(DateTime d) =>
    DateTime(d.year, d.month, d.day - (d.weekday - 1));

/// «Понедельник»
String weekdayName(DateTime d) => _weekdaysFull[d.weekday - 1];

/// «21 сентября»
String dayMonthLabel(DateTime d) => '${d.day} ${_monthsGen[d.month - 1]}';

/// «Понедельник, 21 сентября»
String fullDateLabel(DateTime d) => '${weekdayName(d)}, ${dayMonthLabel(d)}';

/// «21 – 27 сентября» или «28 сентября – 4 октября»
String rangeLabel(DateTime a, DateTime b) {
  if (a.month == b.month) {
    return '${a.day} – ${b.day} ${_monthsGen[b.month - 1]}';
  }
  return '${dayMonthLabel(a)} – ${dayMonthLabel(b)}';
}

/// 1 пара, 2 пары, 5 пар
String pairsLabel(int n) {
  if (appLocale.locale.languageCode == 'en')
    return n == 1 ? l10n.uiClass497 : l10n.uiClasses;
  final m10 = n % 10;
  final m100 = n % 100;
  if (m10 == 1 && m100 != 11) return l10n.uiClass497;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return l10n.uiClasses;
  return l10n.uiClasses499;
}

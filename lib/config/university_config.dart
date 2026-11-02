/// Описание одного вуза внутри платформы Unio.
///
/// Сейчас в приложении активен только один вуз (ВГСПУ) — он захардкожен
/// в [currentUniversity] ниже. Когда появится реальный выбор вуза
/// (список, переключение), эту константу нужно будет заменить на
/// состояние (например, в App/SharedPreferences) и подставлять сюда
/// выбранный вузом объект вместо константы.
class UniversityConfig {
  /// Технический идентификатор — пригодится, когда бэк начнёт
  /// различать вузы (например, как параметр university_id в запросах).
  final String id;
 
  /// Короткое имя для текста в интерфейсе: "ВГСПУ".
  final String shortName;
 
  /// Полное официальное имя, на случай если понадобится для документов
  /// или официальных экранов.
  final String fullName;
 
  const UniversityConfig({
    required this.id,
    required this.shortName,
    required this.fullName,
  });
}
 
const currentUniversity = UniversityConfig(
  id: 'vgspu',
  shortName: 'ВГСПУ',
  fullName:
      'Волгоградский государственный социально-педагогический университет',
);
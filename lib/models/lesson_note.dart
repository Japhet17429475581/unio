import 'dart:typed_data';

class NotePhoto {
  final String id;
  // null means the local file is missing; the text remains editable.
  final Uint8List? bytes;

  const NotePhoto({required this.id, required this.bytes});
}

class LessonNote {
  final String text;
  final List<NotePhoto> photos;

  const LessonNote({this.text = '', this.photos = const []});

  bool get isEmpty => text.trim().isEmpty && photos.isEmpty;
}

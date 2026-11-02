import '../services/locale_service.dart';
import '../widgets/feature_header.dart';
import '../services/analytics_service.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/unio_loader.dart';
import 'package:image_picker/image_picker.dart';

import '../models/lesson.dart';
import '../models/lesson_note.dart';
import '../services/lesson_notes_service.dart';
import '../utils/date_utils.dart';
import '../widgets/lesson_actions.dart';
import '../widgets/message.dart';
import '../widgets/tap_feedback.dart';
import '../widgets/note_photo_gallery.dart';

/// Personal student notes. Teacher routes never open this screen.
class LessonNotesScreen extends StatefulWidget {
  final Lesson lesson;
  final String group;
  final LessonNotesService? service;
  final ImagePicker? picker;

  const LessonNotesScreen({
    super.key,
    required this.lesson,
    required this.group,
    this.service,
    this.picker,
  });

  @override
  State<LessonNotesScreen> createState() => _LessonNotesScreenState();
}

class _LessonNotesScreenState extends State<LessonNotesScreen> {
  final _text = TextEditingController();
  final _noteFocus = FocusNode();
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  LessonNotesService? _service;
  String? _key;
  List<NotePhoto> _photos = [];
  bool _loading = true;
  bool _busy = false;
  bool _dirty = false;
  bool _allowPop = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    analytics.screen(AnalyticsScreen.lessonNotes);
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _errorMessage(Object error, String fallback) =>
      error is NotesException ? error.message : fallback;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service =
          widget.service ?? await LessonNotesService.forCurrentStudent();
      final key = service.keyFor(widget.group, widget.lesson);
      final note = await service.load(key);
      if (!mounted) return;
      setState(() {
        _service = service;
        _key = key;
        _text.text = note.text;
        _photos = note.photos;
        _dirty = false;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _errorMessage(error, l10n.uiCouldNotOpenThisNoteOnYourDevice);
      });
    }
  }

  Future<bool> _persist() async {
    try {
      await _service!
          .save(_key!, LessonNote(text: _text.text, photos: _photos));
      if (mounted) setState(() => _dirty = false);
      return true;
    } catch (error) {
      _message(_errorMessage(
          error, l10n.uiCouldNotSaveTheNoteCheckAvailableStorage));
      return false;
    }
  }

  Future<bool> _save() async {
    if (_busy || _service == null) return false;
    setState(() => _busy = true);
    final saved = await _persist();
    analytics.track(AnalyticsEvent.noteSaved,
        outcome: saved ? AnalyticsOutcome.success : AnalyticsOutcome.failed,
        hasPhotos: _photos.isNotEmpty);
    if (mounted) {
      setState(() => _busy = false);
      if (saved) _message(l10n.uiSavedOnThisDevice);
    }
    return saved;
  }

  Future<void> _addPhotos({bool camera = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Save text before leaving the app for the picker, including on Android
      // where the OS may destroy this activity while the picker is open.
      if (!await _persist() || !mounted) return;
      await _service!.preparePicker(_key!);
      final List<XFile> files;
      if (camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        files = file == null ? [] : [file];
      } else {
        files = await _picker.pickMultiImage(
          maxWidth: 2400,
          maxHeight: 2400,
          imageQuality: 85,
          requestFullMetadata: false,
        );
      }
      if (!mounted) return;
      for (final file in files) {
        try {
          final photo = await _service!.importPhoto(file);
          // Ensure these are displayable images before committing their bytes.
          final codec = await ui.instantiateImageCodec(photo.bytes!,
              targetWidth: 1, targetHeight: 1);
          codec.dispose();
          if (!mounted) return;
          if (!_photos.any((existing) => existing.id == photo.id)) {
            setState(() {
              _photos = [..._photos, photo];
              _dirty = true;
            });
          }
        } catch (error) {
          _message(_errorMessage(
              error, l10n.uiCouldNotReadThePhotoChooseAnotherImage));
        }
      }
      if (await _persist()) await _service!.finishPicker();
    } catch (error) {
      _message(_errorMessage(
          error, l10n.uiCouldNotOpenPhotosCheckAppPermissionsAnd));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uiDeleteNote),
        content: Text(l10n.uiThisClassNoteAndItsAttachedPhotosWill),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.uiCancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.uiDelete,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service!.save(_key!, const LessonNote());
      if (!mounted) return;
      setState(() {
        _text.clear();
        _photos = [];
        _dirty = false;
      });
      _message(l10n.uiNoteDeleted);
    } catch (_) {
      _message(l10n.uiCouldNotDeleteTheNotePleaseTryAgain);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    if (_busy) return;
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.uiSaveChanges),
        content: Text(l10n.uiThisNoteHasUnsavedChanges),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.uiKeepEditing)),
          TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: Text(l10n.uiDiscardChanges)),
          TextButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(l10n.uiSave)),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'save' && !await _save()) return;
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _viewPhoto(NotePhoto photo) {
    tapFeedback();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => NotePhotoViewer(
          photos: List.unmodifiable(_photos),
          initialIndex: _photos.indexOf(photo)),
    ));
  }

  Widget _tools() {
    final canUseCamera = kIsWeb ||
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return LessonActions(actions: [
      LessonAction(
          label: l10n.uiAddHomework,
          icon: Icons.edit_note_rounded,
          selected: true,
          onTap: _busy ? null : () => _noteFocus.requestFocus()),
      LessonAction(
          label: l10n.uiFromGallery,
          icon: Icons.photo_library_outlined,
          onTap: _busy ? null : () => _addPhotos()),
      if (canUseCamera)
        LessonAction(
            label: l10n.uiTakeAPhoto,
            icon: Icons.camera_alt_outlined,
            onTap: _busy ? null : () => _addPhotos(camera: true)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.uiHomeworkAndNotes), actions: [
          if (!_loading &&
              _error == null &&
              (_text.text.isNotEmpty || _photos.isNotEmpty))
            IconButton(
                tooltip: l10n.uiDeleteNote59,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: _busy ? null : _delete),
        ]),
        body: SafeArea(
          child: _loading
              ? const Center(child: UnioLoader())
              : _error != null
                  ? SingleChildScrollView(
                      child: Message(
                          icon: Icons.error_outline_rounded,
                          title: l10n.uiNoteUnavailable,
                          text: _error!,
                          actionLabel: l10n.uiTryAgain,
                          onAction: _load))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        FeatureHeader(
                            compact: true,
                            eyebrow: widget.lesson.date == null
                                ? l10n.uiClassNote
                                : fullDateLabel(widget.lesson.date!),
                            title: widget.lesson.subject,
                            description:
                                '${widget.lesson.start}–${widget.lesson.end}${widget.lesson.room.isEmpty ? '' : ' · ${l10n.uiRoom224(widget.lesson.room)}'}',
                            icon: Icons.edit_note_rounded),
                        const SizedBox(height: 24),
                        TextField(
                          key: const ValueKey('lesson-note-editor'),
                          controller: _text,
                          focusNode: _noteFocus,
                          enabled: !_busy,
                          minLines: 5,
                          maxLines: null,
                          maxLength: LessonNotesService.maxTextLength,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              height: 1.6),
                          onChanged: (_) => setState(() => _dirty = true),
                          decoration: InputDecoration(
                              hintText:
                                  l10n.uiWhatIsTheAssignmentWriteDownHomeworkOr,
                              filled: false,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none),
                        ),
                        if (keyboard == 0) ...[
                          const SizedBox(height: 16),
                          _tools(),
                        ],
                        const SizedBox(height: 24),
                        Row(children: [
                          Expanded(
                              child: Text(l10n.uiPhotos,
                                  style: theme.textTheme.titleSmall)),
                          Text('${_photos.length}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant)),
                        ]),
                        const SizedBox(height: 12),
                        if (_photos.isEmpty)
                          Text(
                              l10n.uiAddAssignmentPhotosFromYourGalleryOrCamera,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant))
                        else
                          NotePhotoGallery(
                              photos: _photos,
                              busy: _busy,
                              onOpen: _viewPhoto,
                              onRemove: (photo) => setState(() {
                                    _photos = _photos
                                        .where((item) => item.id != photo.id)
                                        .toList();
                                    _dirty = true;
                                  })),
                        const SizedBox(height: 24),
                        Text(l10n.uiNotesAndPhotosAreStoredOnlyOnThis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
        ),
        bottomNavigationBar: _loading || _error != null
            ? null
            : Padding(
                padding: EdgeInsets.only(bottom: keyboard),
                child: Material(
                  color: colors.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          if (keyboard > 0) ...[
                            _tools(),
                            const SizedBox(height: 12)
                          ],
                          PrimaryButton(
                              label: l10n.uiSave,
                              loading: _busy,
                              onPressed: _dirty && !_busy ? _save : null),
                        ])),
                  ),
                ),
              ),
      ),
    );
  }
}

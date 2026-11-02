import '../services/locale_service.dart';
import 'package:flutter/material.dart';
import '../models/lesson_note.dart';

/// Opens at the tapped photo; zoomed images keep horizontal panning gestures.
class NotePhotoViewer extends StatefulWidget {
  final List<NotePhoto> photos;
  final int initialIndex;
  const NotePhotoViewer(
      {super.key, required this.photos, this.initialIndex = 0})
      : assert(photos.length > 0),
        assert(initialIndex >= 0 && initialIndex < photos.length);

  @override
  State<NotePhotoViewer> createState() => _NotePhotoViewerState();
}

class _NotePhotoViewerState extends State<NotePhotoViewer> {
  late int _index = widget.initialIndex;
  late final _pages = PageController(initialPage: widget.initialIndex);
  late final _transforms =
      List.generate(widget.photos.length, (_) => TransformationController());
  bool _zoomed = false;

  void _goTo(int index) {
    _transforms[_index].value = Matrix4.identity();
    setState(() => _zoomed = false);
    _pages.animateToPage(index,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final transform in _transforms) {
      transform.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.uiClassPhotos), actions: [
          if (widget.photos.length > 1) ...[
            IconButton(
                tooltip: l10n.uiPreviousPhoto,
                onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded)),
            Center(child: Text('${_index + 1}/${widget.photos.length}')),
            IconButton(
                tooltip: l10n.uiNextPhoto,
                onPressed: _index < widget.photos.length - 1
                    ? () => _goTo(_index + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded))
          ]
        ]),
        body: SafeArea(
            child: PageView.builder(
                key: const ValueKey('note-photo-pages'),
                controller: _pages,
                physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                itemCount: widget.photos.length,
                onPageChanged: (index) {
                  _transforms[_index].value = Matrix4.identity();
                  setState(() {
                    _index = index;
                    _zoomed = false;
                  });
                },
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return Center(
                      child: photo.bytes == null
                          ? Text(l10n.uiCouldNotOpenPhoto)
                          : InteractiveViewer(
                              transformationController: _transforms[index],
                              minScale: 1,
                              maxScale: 5,
                              onInteractionEnd: (_) {
                                final zoomed = _transforms[index]
                                        .value
                                        .getMaxScaleOnAxis() >
                                    1.01;
                                if (index == _index && zoomed != _zoomed) {
                                  setState(() => _zoomed = zoomed);
                                }
                              },
                              child: Semantics(
                                  image: true,
                                  label: l10n.uiPhoto((index + 1).toString()),
                                  child: Image.memory(photo.bytes!,
                                      errorBuilder: (_, __, ___) =>
                                          Text(l10n.uiCouldNotOpenPhoto)))));
                })));
  }
}

class NotePhotoGallery extends StatelessWidget {
  final List<NotePhoto> photos;
  final bool busy;
  final ValueChanged<NotePhoto> onOpen, onRemove;
  const NotePhotoGallery(
      {super.key,
      required this.photos,
      required this.busy,
      required this.onOpen,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 520 ? 3 : 2;
      return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: photos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.15),
          itemBuilder: (context, index) {
            final photo = photos[index];
            return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Stack(fit: StackFit.expand, children: [
                      InkWell(
                          onTap:
                              photo.bytes == null ? null : () => onOpen(photo),
                          child: Semantics(
                              label: l10n.uiPhoto((index + 1).toString()),
                              image: true,
                              child: photo.bytes == null
                                  ? const Center(
                                      child: Icon(Icons.broken_image_outlined))
                                  : Image.memory(photo.bytes!,
                                      fit: BoxFit.cover,
                                      cacheWidth: 540,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                              child: Icon(Icons
                                                  .broken_image_outlined))))),
                      Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton.filled(
                              style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xB3000000),
                                  foregroundColor: Colors.white),
                              tooltip: l10n.uiRemovePhoto,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: busy ? null : () => onRemove(photo)))
                    ])));
          });
    });
  }
}

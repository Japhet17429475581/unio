import 'package:flutter/material.dart';

/// A story animates when it actually enters the shelf, including after a feed
/// response or a horizontal page change. Its neighbour enters a little earlier.
class StoryEntrance extends StatefulWidget {
  final int orderFromRight;
  final Widget child;

  const StoryEntrance({
    super.key,
    required this.orderFromRight,
    required this.child,
  });

  @override
  State<StoryEntrance> createState() => _StoryEntranceState();
}

class _StoryEntranceState extends State<StoryEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 620 + widget.orderFromRight * 75),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delay = widget.orderFromRight * 75;
    final progress = _controller.drive(CurveTween(
      curve: Interval(delay / (620 + delay), 1, curve: Curves.easeOutCubic),
    ));
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress.drive(
          Tween<Offset>(begin: const Offset(.16, 0), end: Offset.zero),
        ),
        child: widget.child,
      ),
    );
  }
}

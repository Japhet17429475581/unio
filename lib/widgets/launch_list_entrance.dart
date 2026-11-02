import 'package:flutter/material.dart';

class LaunchListEntrance extends StatefulWidget {
  final bool ready;
  final Widget child;
  final Object? contentKey;

  const LaunchListEntrance({
    super.key,
    required this.child,
    this.ready = true,
    this.contentKey,
  });

  @override
  State<LaunchListEntrance> createState() => _LaunchListEntranceState();
}

class _LaunchListEntranceState extends State<LaunchListEntrance>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000), value: 1);
  bool _started = false;

  void _start() {
    if (!widget.ready || _started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant LaunchListEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started) {
      _start();
    } else if (widget.ready && oldWidget.contentKey != widget.contentKey) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _EntranceScope(animation: _controller, child: widget.child);
}

class _EntranceScope extends InheritedWidget {
  final Animation<double> animation;
  const _EntranceScope({required this.animation, required super.child});

  @override
  bool updateShouldNotify(_EntranceScope oldWidget) =>
      animation != oldWidget.animation;
}

class LaunchListItem extends StatelessWidget {
  final int index;
  final Widget child;
  const LaunchListItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation =
        context.dependOnInheritedWidgetOfExactType<_EntranceScope>()!.animation;
    // One shared timeline: rows built later by the lazy list appear immediately
    // once the entrance has finished; scrolling does not replay the animation.
    final start = index.clamp(0, 6) * .07;
    final progress = animation.drive(CurveTween(
        curve: Interval(start, start + .55, curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress.drive(
            Tween<Offset>(begin: const Offset(-.08, 0), end: Offset.zero)),
        child: child,
      ),
    );
  }
}

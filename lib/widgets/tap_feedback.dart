import 'package:flutter/material.dart';

import 'unio_loader.dart';
import 'package:flutter/services.dart';

import '../config/brand.dart';
import '../config/calm_depth.dart';

/// Тактильный отклик на нажатие: лёгкая вибрация + системный звук клика.
///
/// Это НЕ кастомный звуковой файл — SystemSoundType.click проигрывает
/// встроенный системный звук (тот же "щёлк", что у системной клавиатуры
/// iOS/Android), поэтому ничего не нужно паковать в приложение и он
/// сразу звучит нативно на любом устройстве.
void tapFeedback() {
  HapticFeedback.lightImpact();
  SystemSound.play(SystemSoundType.click);
}

/// Opens rows and disclosures without a pressed overlay; focus stays visible.
class QuietTap extends StatelessWidget {
  final Widget child;

  const QuietTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: child,
      );
}

/// Кнопка с заливкой (замена FilledButton) с более выраженным "импактом"
/// при нажатии: слегка сжимается и упруго возвращается, плюс звук и
/// вибрация. Поддерживает индикатор загрузки вместо текста/иконки.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget? child;

  /// Заливка фирменным градиентом вместо сплошного цвета. Используется
  /// точечно — для одной-двух главных кнопок на экран (вход, основной
  /// CTA), а не на каждой кнопке подряд.
  final bool gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.borderRadius = UnioRadius.control,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.child,
    this.gradient = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _handleTap() {
    if (!_enabled) return;
    tapFeedback();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
        Theme.of(context).extension<UnioSignature>() != null &&
                widget.borderRadius == UnioRadius.control
            ? CalmDepth.controlRadius
            : widget.borderRadius);
    final colors = Theme.of(context).colorScheme;
    final background = widget.backgroundColor ?? colors.primary;
    final foreground = widget.foregroundColor ??
        (widget.gradient || widget.backgroundColor != null
            ? Colors.white
            : colors.onPrimary);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      onTap: _enabled ? _handleTap : null,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Opacity(
          opacity: _enabled ? 1 : 0.5,
          child: Container(
            decoration: widget.gradient
                ? BoxDecoration(gradient: unioGradient, borderRadius: radius)
                : null,
            child: Material(
              color: widget.gradient ? Colors.transparent : background,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: _enabled ? _handleTap : null,
                onHighlightChanged: (value) {
                  if (!_enabled) return;
                  setState(() => _pressed = value);
                },
                child: Padding(
                  padding: widget.padding,
                  child: Center(
                    child: widget.loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: UnioLoader(color: foreground),
                          )
                        : widget.child ??
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(
                                    widget.icon,
                                    color: foreground,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(widget.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: foreground,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кнопка с обводкой (замена OutlinedButton) — та же логика "импакта".
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = unioError,
    this.icon,
    this.borderRadius = UnioRadius.control,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _handleTap() {
    if (!_enabled) return;
    tapFeedback();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
        Theme.of(context).extension<UnioSignature>() != null &&
                widget.borderRadius == UnioRadius.control
            ? CalmDepth.controlRadius
            : widget.borderRadius);

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: _enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: _enabled ? _handleTap : null,
            onHighlightChanged: (value) {
              if (!_enabled) return;
              setState(() => _pressed = value);
            },
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: widget.color),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.color, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                        child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

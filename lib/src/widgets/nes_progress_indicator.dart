import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:nes_ui/nes_ui.dart';

/// {@template nes_progress_indicator}
/// A widget that displays a progress amount.
/// {@endtemplate}
abstract class NesProgressIndicator extends StatefulWidget {
  /// {@macro nes_progress_indicator}
  const NesProgressIndicator({
    this.value,
    this.semantics,
    super.key,
  });

  /// If non-null, the value of this progress indicator.
  ///
  /// A value of 0.0 means no progress and 1.0 means that progress is complete.
  /// The value will be clamped to be in the range 0.0-1.0.
  ///
  /// If null, this progress indicator is indeterminate, which means the
  /// indicator displays a predetermined animation that does not indicate how
  /// much actual progress is being made.
  final double? value;

  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsLabel}
  /// The [SemanticsProperties.label] for this progress indicator.
  ///
  /// This value indicates the purpose of the progress bar, and will be
  /// read out by screen readers to indicate the purpose of this progress
  /// indicator.
  /// {@endtemplate}
  /// {@template flutter.progress_indicator.ProgressIndicator.semanticsValue}
  /// The [SemanticsProperties.value] for this progress indicator.
  ///
  /// This will be used in conjunction with the [SemanticsProperties.label] by
  /// screen reading software to identify the widget, and is primarily
  /// intended for use with determinate progress indicators to announce
  /// how far along they are.
  ///
  /// For determinate progress indicators, this will be defaulted to
  /// [ProgressIndicator.value] expressed as a percentage, i.e. `0.1` will
  /// become '10%'.
  /// {@endtemplate}
  final SemanticsProperties? semantics;

  Widget _buildSemanticsWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    var expandedSemanticsValue = semantics?.value;
    if (value != null) {
      expandedSemanticsValue ??= '${(value! * 100).round()}%';
    }
    return Semantics(
      label: semantics?.label ?? '',
      value: expandedSemanticsValue,
      child: child,
    );
  }
}

///
///
///
///
///
///
///
///
///
///
///
///

/// A progress bar, which is a linear [NesProgressIndicator].
class NesProgressBar extends NesProgressIndicator {
  /// Creates a progress bar.
  ///
  /// {@macro nes_ui.NesProgressIndicator.NesProgressBar}
  const NesProgressBar({super.key});

  @override
  State<NesProgressBar> createState() => _NesProgressBarState();
}

class _NesProgressBarState extends State<NesProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    if (widget.value == null) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NesProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == null && !_controller.isAnimating) {
      _controller.repeat();
    } else if (widget.value != null && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildIndicator(
    BuildContext context,
    double animationValue,
    TextDirection textDirection,
  ) {
    final progressIndicatorTheme =
        context.nesThemeExtension<NesProgressIndicatorTheme>();
    final nesTheme = context.nesThemeExtension<NesTheme>();

    return widget._buildSemanticsWrapper(
      context: context,
      child: CustomPaint(
        painter: _ProgressBarPainter(
          background: progressIndicatorTheme.background,
          color: progressIndicatorTheme.color,
          pixelSize: nesTheme.pixelSize.toDouble(),
          textDirection: textDirection,
          value: widget.value, // may be null
          animationValue: animationValue, // ignored if widget.value is not null
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    // indeterminate
    if (widget.value != null) {
      return _buildIndicator(context, _controller.value, textDirection);
    }

    // determinate
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (BuildContext context, Widget? child) {
        return _buildIndicator(context, _controller.value, textDirection);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter({
    required this.background,
    required this.color,
    required this.pixelSize,
    required this.textDirection,
    this.value,
    this.animationValue,
  });

  final Color background;
  final Color color;
  final double pixelSize;
  final TextDirection textDirection;
  final double? value;
  final double? animationValue;

  Size get size => Size(
        pixelSize * 4,
        pixelSize * 2,
      );

  @override
  void paint(Canvas canvas, Size childSize) {
    final backgroundPaint = Paint()..color = background;
    final progressPaint = Paint()..color = color;

    // void drawBar(double x, double width) {
    //   if (width <= 0.0) {
    //     return;
    //   }
    //   final left = switch (textDirection) {
    //     TextDirection.rtl => size.width - width - x,
    //     TextDirection.ltr => x,
    //   };
    //   canvas.drawRect(
    //     Offset(left, 0) & Size(width, size.height),
    //     progressPaint,
    //   );
    // }

    // if (value != null) {
    //   drawBar(0, clampDouble(value!, 0, 1) * size.width);
    // } else {
    //   drawBar(size.width, size.width);
    //   drawBar(size.width, size.width);
    // }

    // Draw progress bar.
    canvas
      ..save()
      // Draw progress bar background.
      ..drawRect(
        Offset.zero & Size(size.width, size.height),
        backgroundPaint,
      )
      // Draw top and bottom borders.
      ..drawRect(
        Offset(pixelSize, -pixelSize) &
            Size(size.width - pixelSize * 2, pixelSize),
        backgroundPaint,
      )
      ..drawRect(
        Offset(pixelSize, size.height) &
            Size(size.width - pixelSize * 2, pixelSize),
        backgroundPaint,
      )
      // Draw progress bar progress.
      ..drawRect(
        Offset.zero & Size((value ?? 0) * pixelSize, size.height),
        progressPaint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.pixelSize != pixelSize ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.value != value ||
      oldDelegate.animationValue != animationValue;
}

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:pull_up_club/common/themes/app_colors.dart";
import "package:pull_up_club/common/themes/app_spacing.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/common/themes/app_typography.dart";
import "package:pull_up_club/common/widgets/core/gradient_surface.dart";

class SetCards extends StatelessWidget {
  const SetCards({
    required this.values,
    super.key,
    final int? numExpectedCards,
    this.withContainer = true,
  }) : assert(
         numExpectedCards == null || numExpectedCards >= values.length,
         "if numExpectedCards is set it must be >= values.length",
       ),
       numExpectedCards = numExpectedCards ?? values.length;
  final List<String> values;
  final int numExpectedCards;
  final bool withContainer;

  static const int _maxCardsPerRow = 5;
  static const double _containerPadding = AppSpacing.paddingSmall;
  static const double _cardSpacing = AppSpacing.sm;

  @override
  Widget build(final BuildContext context) {
    final highlightCurrentGroup = numExpectedCards > values.length;
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final cardWidth =
            (constraints.maxWidth -
                _containerPadding * 2 -
                _cardSpacing * (_maxCardsPerRow - 1)) /
            _maxCardsPerRow;
        final cardHeight = 2 / 3 * cardWidth;

        final wrap = Wrap(
          alignment: WrapAlignment.center,
          spacing: _cardSpacing,
          runSpacing: AppSpacing.md,
          children: List.generate(
            numExpectedCards,
            (final i) => _SetCard(
              value: i < values.length ? values[i] : null,
              width: cardWidth,
              height: cardHeight,
              isHighlighted: highlightCurrentGroup && i == values.length,
            ),
          ),
        );

        if (withContainer) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            padding: const EdgeInsets.all(_containerPadding),
            child: wrap,
          );
        } else {
          return wrap;
        }
      },
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>("values", values))
      ..add(IntProperty("numExpectedCards", numExpectedCards))
      ..add(DiagnosticsProperty<bool>("withContainer", withContainer));
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({
    required this.width,
    required this.height,
    this.value,
    this.isHighlighted = false,
  });

  static const String _placeholderValue = "?";
  final String? value;
  final double width;
  final double height;
  final bool isHighlighted;

  @override
  Widget build(final BuildContext context) {
    return Opacity(
      opacity: value == null ? 0.1 : 1.0,
      child: GradientSurface(
        height: height,
        width: width,
        gradient: value == null ? AppGradients.light : AppGradients.secondary,
        border: isHighlighted ? Border.all(color: AppColors.glassBorderActive) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: defaultBoxShadows,
        child: Center(
          child: Text(value ?? _placeholderValue, style: AppTypography.headlineSmall),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty("value", value))
      ..add(DoubleProperty("width", width))
      ..add(DoubleProperty("height", height))
      ..add(DiagnosticsProperty<bool>("isHighlighted", isHighlighted));
  }
}

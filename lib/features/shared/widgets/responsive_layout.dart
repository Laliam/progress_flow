import 'package:flutter/material.dart';

/// Breakpoints for responsive layout decisions.
abstract class AppBreakpoints {
  /// Compact (phone portrait): < 600dp
  static const double compact = 600;

  /// Medium (phone landscape / small tablet): 600–840dp
  static const double medium = 840;

  /// Expanded (large tablet / desktop): > 840dp
  static const double expanded = 1200;

  /// Max content width on wide screens (centering constraint).
  static const double maxContentWidth = 720;

  /// Max width for auth/modal cards on tablet.
  static const double authCardWidth = 480;
}

/// Returns `true` if the current screen is tablet-sized (≥ 600dp wide).
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppBreakpoints.compact;

/// Returns `true` if the current screen is in landscape orientation.
bool isLandscape(BuildContext context) =>
    MediaQuery.orientationOf(context) == Orientation.landscape;

/// Responsive layout that switches between [phone] and [tablet] layouts.
///
/// Falls back to [phone] if [tablet] is not provided.
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;

  const ResponsiveLayout({super.key, required this.phone, this.tablet});

  @override
  Widget build(BuildContext context) {
    if (tablet != null && isTablet(context)) return tablet!;
    return phone;
  }
}

/// A widget that constrains its child to [AppBreakpoints.maxContentWidth]
/// and centers it on large screens.
class MaxWidthBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

/// Responsive grid that uses [crossAxisCount] columns on phone and
/// [tabletColumns] on tablet.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int phoneColumns;
  final int tabletColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.phoneColumns = 1,
    this.tabletColumns = 2,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final cols = isTablet(context) ? tabletColumns : phoneColumns;
    if (cols <= 1) {
      return Column(
        children: children
            .map((c) => Padding(
                  padding: EdgeInsets.only(bottom: runSpacing),
                  child: c,
                ))
            .toList(),
      );
    }
    return LayoutBuilder(
      builder: (_, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += cols) {
          final rowChildren = <Widget>[];
          for (var j = 0; j < cols; j++) {
            final idx = i + j;
            rowChildren.add(
              SizedBox(
                width: itemWidth,
                child: idx < children.length
                    ? children[idx]
                    : const SizedBox.shrink(),
              ),
            );
            if (j < cols - 1) rowChildren.add(SizedBox(width: spacing));
          }
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowChildren,
          ));
          if (i + cols < children.length) {
            rows.add(SizedBox(height: runSpacing));
          }
        }
        return Column(children: rows);
      },
    );
  }
}

/// Auth screen wrapper — centers content in a card on tablet.
class AuthPageWrapper extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const AuthPageWrapper({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF070B14),
  });

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) return child;

    // Tablet: centered card on solid background (no duplicate child)
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.authCardWidth),
          child: Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 48),
            color: const Color(0xFF0F1220),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            elevation: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

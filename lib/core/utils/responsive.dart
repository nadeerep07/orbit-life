import 'package:flutter/material.dart';

/// Breakpoints for responsive layouts
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive utility class — call once per build context
class Responsive {
  final BuildContext _context;

  Responsive(this._context);

  double get _width => MediaQuery.of(_context).size.width;

  bool get isMobile => _width < Breakpoints.mobile;
  bool get isTablet => _width >= Breakpoints.mobile && _width < Breakpoints.tablet;
  bool get isDesktop => _width >= Breakpoints.desktop;
  bool get isTabletOrDesktop => _width >= Breakpoints.mobile;

  /// Number of grid columns based on screen width
  int get gridColumns {
    if (_width >= Breakpoints.desktop) return 4;
    if (_width >= Breakpoints.tablet) return 3;
    if (_width >= Breakpoints.mobile) return 2;
    return 2;
  }

  /// Content max width for centered layouts on wide screens
  double get contentMaxWidth {
    if (_width >= Breakpoints.desktop) return 960;
    if (_width >= Breakpoints.tablet) return 720;
    return double.infinity;
  }

  /// Padding — larger on tablets
  EdgeInsets get screenPadding {
    if (isTabletOrDesktop) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  }

  /// Horizontal padding only
  double get horizontalPadding => isTabletOrDesktop ? 32 : 16;

  /// Card corner radius
  double get cardRadius => isTabletOrDesktop ? 20 : 16;

  /// Larger font scale for tablet
  double scaledFont(double base) => isTabletOrDesktop ? base * 1.15 : base;

  /// Card aspect ratio for grid items
  double get cardAspectRatio => isTabletOrDesktop ? 1.6 : 1.4;

  /// Whether to show a two-column layout (left panel + list)
  bool get showTwoPane => isTabletOrDesktop;

  /// Drawer width for tablet
  double get drawerWidth => isTabletOrDesktop ? 280 : 0;

  /// FAB location on tablet (inline vs floating)
  bool get useInlineFab => isTabletOrDesktop;
}

/// Extension for easy access
extension ResponsiveContext on BuildContext {
  Responsive get responsive => Responsive(this);
  bool get isMobile => Responsive(this).isMobile;
  bool get isTablet => Responsive(this).isTablet;
  bool get isTabletOrDesktop => Responsive(this).isTabletOrDesktop;
}

/// Centered constrained wrapper for wide screens
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? r.contentMaxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive two-pane layout (side nav + main content)
class ResponsiveTwoPane extends StatelessWidget {
  final Widget sidePanel;
  final Widget mainContent;
  final double sidePanelWidth;

  const ResponsiveTwoPane({
    super.key,
    required this.sidePanel,
    required this.mainContent,
    this.sidePanelWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    if (!r.isTabletOrDesktop) {
      return mainContent;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: sidePanelWidth,
          child: sidePanel,
        ),
        const VerticalDivider(width: 1),
        Expanded(child: mainContent),
      ],
    );
  }
}

/// Responsive grid that adapts columns to screen width
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: r.gridColumns,
      childAspectRatio: childAspectRatio ?? r.cardAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      padding: padding,
      children: children,
    );
  }
}

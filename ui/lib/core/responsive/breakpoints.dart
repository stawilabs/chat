/// Responsive breakpoints for the application
///
/// Defines screen size breakpoints and layout dimensions for:
/// - Mobile: Single-pane stack navigation (< 600px)
/// - Tablet: 2-panel layout (600-1200px): Rooms | Chat
/// - Desktop: 3-panel layout (>= 1200px): Rooms | Chat | Details
class AppBreakpoints {
  // Screen size breakpoints
  static const double mobile = 600; // < 600px: Single-pane
  static const double tablet = 1200; // 600-1200px: 2-panel
  static const double desktop = 1200; // >= 1200px: 3-panel

  // Panel widths
  static const double roomListWidth = 280;
  static const double detailPanelWidth = 320;

  // Helper methods to determine layout mode
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
  static bool showDetailPanel(double width) => width >= desktop;
}

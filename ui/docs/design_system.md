# Design System Documentation

## Overview

This document outlines the complete design system implemented for the AntInvestor Chat application, following Material 3 guidelines with custom branding and strict adherence to the specified design requirements.

## 🎨 Color Palette

### Primary Colors
- **Primary Green (Identity):** `#128C7E` - Teal Green used for primary branding and interactive elements
- **Bright Green (Success):** `#25D366` - Bright Green used for actions and success states

### Surface Colors

#### Light Theme
- **Surface Light:** `#FFFFFF` - Pure white for main backgrounds
- **Surface Light Alt:** `#ECE5DD` - Light beige for chat backgrounds and cards

#### Dark Theme
- **Surface Dark:** `#121B22` - Dark surface for main backgrounds
- **Surface Dark Alt:** `#0B141A` - Very dark for chat backgrounds and cards

### Message Colors
- **Own Messages:** Primary Green (`#128C7E`) with white text
- **Other Messages (Light):** `#E5DDD5` with dark text
- **Other Messages (Dark):** `#2A3942` with white text

## 📝 Typography System

### Font Stack
- **Android:** Roboto (system default)
- **iOS:** SF Pro (system default)

### Text Styles

| Style | Size | Weight | Use Case |
|--------|--------|-----------|
| **Header** | 20sp | FontWeight.w600 | Screen titles, section headers |
| **Body** | 16sp | FontWeight.w400 | Message content, descriptions |
| **Metadata** | 12sp | FontWeight.w400 | Timestamps, status text |
| **Button** | 16sp | FontWeight.w500 | Button labels, actions |

## 📏 Spacing System

### 8pt Grid System
All spacing follows a strict 8-point grid system:

| Type | Value | Usage |
|-------|--------|--------|
| **Standard Margin** | 16dp | Screen margins, section padding |
| **Element Gap** | 8dp | Between elements, list items |
| **Small Gap** | 4dp | Compact spacing |
| **Touch Target** | 48dp | Minimum interactive element size |

## 🎯 Interactive Elements

### Touch Targets
- **Minimum Size:** 48×48dp for all interactive elements
- **Avatar Size:** 48×48dp (meets touch target requirements)
- **Button Padding:** 12dp vertical, 24dp horizontal

### Visual Feedback
- **Splash Color:** 10% opacity of base color
- **Highlight Color:** Transparent
- **Splash Factory:** `InkRipple.splashFactory`

## 🌓 Theme System

### Light Theme
```dart
static ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTheme.primaryGreen,
    brightness: Brightness.light,
  ),
  // ... complete theme configuration
);
```

### Dark Theme
```dart
static ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppTheme.primaryGreen,
    brightness: Brightness.dark,
  ),
  // ... complete theme configuration
);
```

### System Detection
- **Automatic:** Follows system brightness setting
- **Manual Toggle:** Can be overridden by user preference
- **Implementation:** `ThemeMode.system` in MaterialApp

## 🧩 Component Specifications

### Room List Tile
- **Avatar:** 48×48dp circular, primary green background
- **Content Padding:** 16dp horizontal, 8dp vertical
- **Unread Badge:** Minimum 24×24dp, primary green background
- **Touch Feedback:** 10% opacity splash on interaction

### Chat Screen
- **App Bar:** Primary green background, white text
- **Message Input:** 16dp padding, rounded corners
- **Background:** Surface alt color (light beige or dark)
- **Back Button:** Standard navigation with proper touch target

### Buttons
- **Elevated Buttons:** Primary green background, white text
- **Text Buttons:** Primary green text, no background
- **Padding:** 12dp vertical, 24dp horizontal
- **Border Radius:** 8dp corners

## 📱 Responsive Design

### Breakpoints
- **Mobile:** Single panel navigation
- **Tablet:** Two-panel layout (rooms + chat)
- **Desktop:** Three-panel layout (rooms + chat + details)

### Adaptive Elements
- **Navigation:** Back button on mobile, panel navigation on desktop
- **Layouts:** Responsive grid system adapts to screen size
- **Touch Targets:** Consistent 48dp minimum across all devices

## ♿ Accessibility

### Color Contrast
- **Text on Primary:** White text on `#128C7E` (WCAG AA compliant)
- **Text on Surfaces:** Proper contrast ratios for light/dark themes
- **Interactive Elements:** Clear visual feedback with 10% opacity splashes

### Touch Targets
- **Minimum Size:** 48×48dp for all interactive elements
- **Spacing:** 8dp minimum between interactive elements
- **Feedback:** Visual and haptic feedback on interactions

### Typography
- **Readability:** 16sp minimum body text size
- **Hierarchy:** Clear distinction between header, body, and metadata
- **System Fonts:** Uses platform-appropriate system fonts

## 🎨 Implementation Details

### Theme Class Structure
```dart
class AppTheme {
  // Color constants
  static const Color primaryGreen = Color(0xFF128C7E);
  static const Color brightGreen = Color(0xFF25D366);
  // ... other colors
  
  // Text style constants
  static const TextStyle headerText = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle bodyText = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  // ... other styles
  
  // Spacing constants
  static const double standardMargin = 16.0;
  static const double elementGap = 8.0;
  static const double minTouchTarget = 48.0;
  
  // Theme getters
  static ThemeData get lightTheme => ThemeData(...);
  static ThemeData get darkTheme => ThemeData(...);
  
  // Helper methods
  static Color getSubtleColor(BuildContext context, Color baseColor) =>
    baseColor.withValues(alpha: 0.1);
  // ... other helpers
}
```

### Usage in Components
```dart
// Using theme colors
Container(
  color: AppTheme.primaryGreen,
  child: Text('Hello', style: AppTheme.headerText),
)

// Using spacing
Padding(
  padding: const EdgeInsets.all(AppTheme.standardMargin),
  child: Column(
    children: [
      Widget1(),
      SizedBox(height: AppTheme.elementGap),
      Widget2(),
    ],
  ),
)

// Using touch targets
GestureDetector(
  onTap: () => handleTap(),
  child: Container(
    width: AppTheme.minTouchTarget,
    height: AppTheme.minTouchTarget,
    child: Icon(Icons.add),
  ),
)
```

## 🔄 Maintenance

### Updating Colors
- Modify hex values in `AppTheme` class
- Colors automatically propagate to all components
- Test both light and dark themes

### Updating Typography
- Adjust font sizes in text style constants
- Weights remain consistent with design hierarchy
- Changes apply globally across the app

### Updating Spacing
- Modify spacing constants in `AppTheme` class
- 8pt grid system maintains consistency
- All components automatically use new values

## 📋 Design Principles

### 1. Simplicity
- Clean, minimal interface design
- Focus on content over chrome
- Intuitive navigation patterns

### 2. Consistency
- Unified color palette throughout
- Consistent spacing and typography
- Predictable interaction patterns

### 3. Accessibility
- WCAG AA compliant color contrast
- Proper touch targets for all users
- Clear visual hierarchy

### 4. Responsiveness
- Adaptive layouts for all screen sizes
- Touch-friendly interaction areas
- Platform-appropriate behaviors

## 🎯 Design Tokens

This design system uses design tokens to ensure consistency:

- **Colors:** Defined as static constants with semantic names
- **Typography:** Size and weight tokens for text hierarchy
- **Spacing:** 8pt grid system for consistent layout
- **Interactions:** Standardized feedback patterns

All components should use these tokens rather than hardcoded values to maintain design consistency and make updates easier.

---

*Last Updated: January 7, 2026*
*Design System Version: 1.0*

# Design System Quick Reference

## 🎨 Colors

```dart
// Primary Colors
AppTheme.primaryGreen     // #128C7E - Main branding
AppTheme.brightGreen     // #25D366 - Success/actions

// Surface Colors
AppTheme.surfaceLight     // #FFFFFF - Light background
AppTheme.surfaceLightAlt  // #ECE5DD - Light chat background
AppTheme.surfaceDark      // #121B22 - Dark background
AppTheme.surfaceDarkAlt   // #0B141A - Dark chat background
```

## 📝 Typography

```dart
AppTheme.headerText    // 20sp, w600 - Titles
AppTheme.bodyText      // 16sp, w400 - Content
AppTheme.metadataText  // 12sp, w400 - Secondary info
AppTheme.buttonText    // 16sp, w500 - Buttons
```

## 📏 Spacing

```dart
AppTheme.standardMargin  // 16dp - Default margins
AppTheme.elementGap     // 8dp  - Element spacing
AppTheme.minTouchTarget  // 48dp - Minimum touch size
```

## 🎯 Common Patterns

### Avatar
```dart
Container(
  width: AppTheme.minTouchTarget,
  height: AppTheme.minTouchTarget,
  decoration: BoxDecoration(
    color: AppTheme.primaryGreen,
    shape: BoxShape.circle,
  ),
  child: Center(
    child: Text(initial, style: AppTheme.headerText),
  ),
)
```

### Button
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: Text('Action', style: AppTheme.buttonText),
)
```

### Card/List Item
```dart
Padding(
  padding: const EdgeInsets.all(AppTheme.standardMargin),
  child: Container(
    decoration: BoxDecoration(
      color: AppTheme.surfaceLightAlt,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Widget1(),
        SizedBox(height: AppTheme.elementGap),
        Widget2(),
      ],
    ),
  )
```

### Interactive Element
```dart
InkWell(
  onTap: () {},
  borderRadius: BorderRadius.circular(8),
  splashColor: AppTheme.getSubtleColor(context, AppTheme.primaryGreen),
  child: Container(
    constraints: const BoxConstraints(
      minWidth: AppTheme.minTouchTarget,
      minHeight: AppTheme.minTouchTarget,
    ),
    child: Icon(Icons.add),
  ),
)
```

## 🌓 Theme Usage

```dart
// Get current theme
Theme.of(context)

// Get theme-appropriate color
AppTheme.getChatBackground(context)
AppTheme.getMessageBubbleColor(context, isOwnMessage)
AppTheme.getTextColor(context)

// Get subtle version (10% opacity)
AppTheme.getSubtleColor(context, baseColor)
```

## 📱 Responsive Tips

```dart
// Check screen width
final width = MediaQuery.of(context).size.width;

// Use responsive breakpoints
if (width < 600) {
  // Mobile layout
} else if (width < 1200) {
  // Tablet layout
} else {
  // Desktop layout
}
```

---

*Use these patterns to maintain design system consistency*

import 'package:flutter/material.dart';

/// App theme following the design system guidelines
class AppTheme {
  // Color Palette
  static const Color primaryGreen = Color(0xFF128C7E); // Teal Green - Identity
  static const Color brightGreen = Color(
    0xFF25D366,
  ); // Bright Green - Actions/Success
  static const Color surfaceLight = Color(0xFFFFFFFF); // Chat Background
  static const Color surfaceLightAlt = Color(
    0xFFECE5DD,
  ); // Alternative Light Surface
  static const Color surfaceDark = Color(0xFF121B22); // Dark Surface
  static const Color surfaceDarkAlt = Color(
    0xFF0B141A,
  ); // Alternative Dark Surface

  // WhatsApp-style message bubble colors
  static const Color sentBubbleDark = Color(0xFF005C4B);
  static const Color sentBubbleLight = Color(0xFFD9FDD3);
  static const Color receivedBubbleDark = Color(0xFF1F2C34);
  static const Color receivedBubbleLight = Color(0xFFFFFFFF);
  static const Color chatBackgroundDark = Color(0xFF0B141A);
  static const Color chatBackgroundLight = Color(0xFFECE5DD);
  static const Color readReceiptBlue = Color(0xFF53BDEB);

  // Sender name rotating color palette for group chats
  static const List<Color> senderNameColors = [
    Color(0xFF35CD96), // green
    Color(0xFFE542A3), // pink
    Color(0xFF6B7AED), // blue
    Color(0xFFE6A50A), // orange
    Color(0xFF00A0F2), // sky blue
    Color(0xFFEB6E4B), // red-orange
    Color(0xFF9B59B6), // purple
    Color(0xFF2EBBAD), // teal
  ];

  // Text Styles
  static const TextStyle headerText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const TextStyle metadataText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Spacing constants
  static const double standardMargin = 16;
  static const double elementGap = 8;
  static const double minTouchTarget = 48;

  // Light Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
    textTheme: const TextTheme(
      bodyLarge: bodyText,
      bodyMedium: bodyText,
      bodySmall: metadataText,
      headlineLarge: headerText,
      headlineMedium: headerText,
      headlineSmall: headerText,
      labelLarge: buttonText,
      labelMedium: buttonText,
      labelSmall: buttonText,
    ),
    scaffoldBackgroundColor: surfaceLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: headerText,
    ),
    cardTheme: CardThemeData(
      color: surfaceLightAlt,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: surfaceDarkAlt),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLightAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: surfaceDarkAlt),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: surfaceDarkAlt),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(color: surfaceDark, size: 24),
    dividerTheme: const DividerThemeData(
      color: surfaceDarkAlt,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
  );

  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      bodyLarge: bodyText,
      bodyMedium: bodyText,
      bodySmall: metadataText,
      headlineLarge: headerText,
      headlineMedium: headerText,
      headlineSmall: headerText,
      labelLarge: buttonText,
      labelMedium: buttonText,
      labelSmall: buttonText,
    ),
    scaffoldBackgroundColor: surfaceDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDarkAlt,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: headerText,
    ),
    cardTheme: CardThemeData(
      color: surfaceDarkAlt,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: surfaceLightAlt),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: buttonText,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDarkAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: surfaceLightAlt),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: surfaceLightAlt),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70, size: 24),
    dividerTheme: const DividerThemeData(
      color: surfaceLightAlt,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkRipple.splashFactory,
    highlightColor: Colors.transparent,
  );

  // Get theme based on system brightness
  static ThemeData getTheme(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Get subtle color (10% opacity)
  static Color getSubtleColor(BuildContext context, Color baseColor) =>
      baseColor.withValues(alpha: 0.1);

  // Get text color based on theme
  static Color getTextColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? Colors.white : surfaceDark;
  }

  // Get chat background color based on theme
  static Color getChatBackground(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    return brightness == Brightness.dark ? surfaceDarkAlt : surfaceLightAlt;
  }

  // Get message bubble color based on theme and ownership
  static Color getBubbleColor(bool isMe, bool isDark) {
    if (isMe) {
      return isDark ? sentBubbleDark : sentBubbleLight;
    } else {
      return isDark ? receivedBubbleDark : receivedBubbleLight;
    }
  }

  // Get message text color based on bubble ownership and theme
  static Color getBubbleTextColor(bool isMe, bool isDark) {
    if (isMe) {
      return isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    } else {
      return isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    }
  }

  // Get timestamp color based on bubble ownership and theme
  static Color getTimestampColor(bool isMe, bool isDark) {
    if (isMe) {
      return isDark
          ? const Color(0xFF7FCCB9) // light teal on dark sent bubble
          : const Color(0xFF667781); // grey-green on light sent bubble
    } else {
      return isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    }
  }

  // Get sender name color from rotating palette based on senderId
  static Color getSenderNameColor(String senderId) {
    final hash = senderId.hashCode.abs();
    return senderNameColors[hash % senderNameColors.length];
  }

  // Legacy aliases for backward compatibility
  static Color getMessageBubbleColor(BuildContext context, bool isOwnMessage) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return getBubbleColor(isOwnMessage, isDark);
  }

  static Color getMessageTextColor(BuildContext context, bool isOwnMessage) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return getBubbleTextColor(isOwnMessage, isDark);
  }
}

# Flutter-specific ProGuard rules

# Keep Flutter framework classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Google Play Core (required by Flutter deferred components)
-keep class com.google.android.play.core.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }

# SQLite/Drift
-keep class io.requery.** { *; }

# Keep native library classes
-keep class **.jni.** { *; }

# Sentry
-keep class io.sentry.** { *; }
-keepnames class io.sentry.** { *; }

# Keep annotation classes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses,EnclosingMethod

# Prevent R8 from stripping interface information
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Keep JSON serialization classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Don't warn about missing classes from optional dependencies
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# --- OAuth redirect (antinvestor_auth_runtime -> flutter_web_auth_2) ---
-keep class com.linusu.flutter_web_auth_2.** { *; }

# --- flutter_secure_storage (AndroidX EncryptedSharedPreferences) ---
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**

# --- WorkManager (background sync isolate) ---
-keep class androidx.work.** { *; }

# --- SQLCipher native bindings (when SQLCipher is enabled) ---
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# --- Protobuf / Connect RPC generated messages (reflection on fields) ---
-keep class com.google.protobuf.** { *; }
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
    <fields>;
}
-dontwarn com.google.protobuf.**

# --- Keep enum values()/valueOf used by serialization ---
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# --- Keep native (JNI) methods ---
-keepclasseswithmembernames class * {
    native <methods>;
}

# --- Keep Parcelable CREATOR fields ---
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

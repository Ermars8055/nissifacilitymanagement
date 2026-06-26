# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Flutter Play Store deferred components (not used, suppress missing class errors)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# mobile_scanner / ZXing / ML Kit
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

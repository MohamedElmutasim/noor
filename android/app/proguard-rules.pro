# قواعد حماية فئات ويدجتس أندرويد من الحذف أو التعتيم أثناء بناء نسخة Release
-keep class com.example.noor.*WidgetProvider { *; }
-keepclassmembers class com.example.noor.*WidgetProvider { *; }

# حماية مكتبة home_widget
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }

# حماية كلاسات Flutter والبلجنات الأساسية
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }


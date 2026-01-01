# Consumer ProGuard rules to keep vendor SDK classes when apps minify.
# Keep vendor SDK classes and suppress warnings to avoid R8 removing them.
-keep class com.example.hxjblinklibrary.** { *; }
-dontwarn com.example.hxjblinklibrary.**

-keep class com.example.hxlibraray.** { *; }
-dontwarn com.example.hxlibraray.**

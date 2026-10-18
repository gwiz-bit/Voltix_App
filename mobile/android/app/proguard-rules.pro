# shared_preferences_android được gọi từ Dart qua JNI (package:jni). JNI tìm class/method
# theo tên + chữ ký gốc (kể cả các class Kotlin như Continuation, Result$Failure), nên R8
# không được xoá hay đổi tên chúng; nếu không bản release sẽ lỗi NoSuchMethodError /
# ClassNotFoundException khi đọc/ghi token (bản debug không bị vì không rút gọn code).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

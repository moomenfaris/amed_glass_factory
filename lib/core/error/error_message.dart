import 'failures.dart';

String userErrorMessage(Object error) {
  if (error is Failure) {
    final msg = error.message.trim();
    return msg.isEmpty ? 'حدث خطأ غير متوقع' : msg;
  }

  final raw = error.toString().trim();
  if (raw.isEmpty) return 'حدث خطأ غير متوقع';

  final stripped = raw
      .replaceFirst(RegExp(r'^Failure\([^)]*\):\s*'), '')
      .replaceFirst(RegExp(r'^Failure:\s*'), '')
      .trim();

  return stripped.isEmpty ? 'حدث خطأ غير متوقع' : stripped;
}
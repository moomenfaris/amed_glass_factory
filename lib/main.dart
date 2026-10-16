import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/local_storage.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التخزين المحلي أولاً حتى يعمل التطبيق حتى لو فشلت خدمات Firebase.
  final prefs = await SharedPreferences.getInstance();
  LocalStorage.init(prefs);

  // تهيئة Firebase والإشعارات داخل try/catch حتى لا تتوقف الواجهة (الشاشة البيضاء)
  // في حال حدوث أي خطأ في الإعداد أو الأذونات.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    // Avoid exposing internal initialization details in production logs.
    debugPrint('Firebase/Notifications init failed.');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ProviderScope(child: AmedApp()));
}

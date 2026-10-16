// File generated to configure Firebase without relying on native config files
// being bundled. Use with `Firebase.initializeApp(
//   options: DefaultFirebaseOptions.currentPlatform,
// )`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtsagow_H31or-e_eyaIw5z1aJGogoalQ',
    appId: '1:58595269514:android:96a42382c23b40a0cd8673',
    messagingSenderId: '58595269514',
    projectId: 'glass-amed',
    storageBucket: 'glass-amed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDOxyhD7EZQqPQAILmQvBGRTf3mrdqBgp8',
    appId: '1:58595269514:ios:c3617a965c7ff714cd8673',
    messagingSenderId: '58595269514',
    projectId: 'glass-amed',
    storageBucket: 'glass-amed.firebasestorage.app',
    iosBundleId: 'com.moomen.glassamed',
  );
}

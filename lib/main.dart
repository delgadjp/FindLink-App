import 'core/app_export.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/network/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBtAa6znwld6hJdlBdDEPhqkECzuuyzzo8",
            authDomain: "missing-person-cap.firebaseapp.com",
            projectId: "missing-person-cap",
            storageBucket: "missing-person-cap.firebasestorage.app",
            messagingSenderId: "152637585017",
            appId: "1:152637585017:web:ec43d14d9b3224963386a8",
            measurementId: "G-KW3Q9T21GY"));
  } else {
    await Firebase.initializeApp();
  }
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await NotificationService().initialize();

  runApp(FindLinkApp());
}

class FindLinkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: SplashScreen(),
      routes: AppRoutes.routes,
    );
  }
}

import 'core/app_export.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/network/notification_service.dart';
import 'core/network/global_notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyCJgw142ugimVb30QUotOqYe_RYmzXgXMg",
            authDomain: "missingperson-345a8.firebaseapp.com",
            projectId: "missingperson-345a8",
            storageBucket: "missingperson-345a8.firebasestorage.app",
            messagingSenderId: "677216091931",
            appId: "1:677216091931:web:d0e23fbc10667039525dbe",
            measurementId: "G-56J5GH3P7K"));
  } else {
    await Firebase.initializeApp();
  }
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await NotificationService().initialize();
  await GlobalNotificationManager().initialize();

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

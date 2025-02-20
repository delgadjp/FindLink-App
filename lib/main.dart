import 'package:flutter/foundation.dart';
import 'core/app_export.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();

  if(kIsWeb) {
    await Firebase.initializeApp(options: FirebaseOptions
      (apiKey: "AIzaSyCnCZ7nxWsHAcdzo-y7cI5a42htHWQKWfc",
      authDomain: "findlink-449810.firebaseapp.com",
      projectId: "findlink-449810",
      storageBucket: "findlink-449810.firebasestorage.app",
      messagingSenderId: "62598723004",
      appId: "1:62598723004:web:83752f5f8b6877547827b9",
      measurementId: "G-8YQLN74HG6"));
  } else {
    await Firebase.initializeApp();
  }
  

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
      initialRoute: AppRoutes.home,  // Use named routes
      routes: AppRoutes.routes,       // Set the routes
    );
  }
}

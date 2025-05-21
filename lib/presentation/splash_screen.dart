import '../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => StreamBuilder<User?>(
            stream: AuthService().authStateChanges,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return HomeScreen();
              } else {
                return LoginPage();
              }
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D47A1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              ImageConstant.logoFinal,
              width: 140,
              height: 140,
            ),
            SizedBox(height: 24),
            Text(
              'FindLink',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

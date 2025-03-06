import '../core/app_export.dart';

class AppRoutes {
  static const String home = '/home';
  static const String missingPerson = '/missing-person';
  static const String profile = '/profile';
  static const String trackCase = '/track-case';
  static const String login = '/login';
  static const String register = '/register';
  static const String fillUpForm = '/fill-up-form';
  static const String chatbot = '/chatbot';  // Added chatbot route

  static Map<String, WidgetBuilder> routes = {
    home: (context) => HomeScreen(),
    missingPerson: (context) => MissingPersonScreen(),
    profile: (context) => ProfileScreen(),
    // Remove trackCase from static routes since it needs parameters
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    fillUpForm: (context) => FillUpFormScreen(),
    chatbot: (context) => ChatbotScreen(),
  };
}
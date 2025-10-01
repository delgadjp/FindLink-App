import '/core/app_export.dart';
import 'package:findlink/presentation/fill_up_form_screen.dart';
import 'package:findlink/presentation/profile_screen.dart';


class AppRoutes {
  static const String home = '/home';
  static const String missingPerson = '/missing-person';
  static const String profile = '/profile';
  static const String trackCase = '/track-case';
  static const String login = '/login';
  static const String register = '/register';
  static const String fillUpForm = '/fill-up-form';
  static const String chatbot = '/chatbot';  // Added chatbot route
  static const String idValidation = '/id-validation'; // Added ID validation route
  static const String confirmIdDetails = '/confirm-id-details'; // Added confirm ID details route
  static const String forgotPassword = '/forgot-password'; // Added forgot password route
  static const String findMeSettings = '/find-me-settings'; // FindMe settings route
  static const String findMyDevices = '/find-my-devices'; // Find My Devices screen
  static const String irfDetails = '/irf-details'; // IRF Details screen

  static Map<String, WidgetBuilder> routes = {
    home: (context) => HomeScreen(),
    missingPerson: (context) => MissingPersonScreen(),
    profile: (context) => ProfileScreen(),
    // Remove trackCase from static routes since it needs parameters
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    fillUpForm: (context) => FillUpFormScreen(),
    idValidation: (context) => IDValidationScreen(), // Added ID validation screen to routes
    forgotPassword: (context) => ForgotPasswordPage(), // Added forgot password screen to routes
    findMeSettings: (context) => FindMeSettingsScreen(), // FindMe settings screen
    findMyDevices: (context) => FindMyDevicesScreen(), // Find My Devices screen
    
  };
}
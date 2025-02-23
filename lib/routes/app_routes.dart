import '../core/app_export.dart';

class AppRoutes {
  static const String home = '/home';
  static const String missingPerson = '/missing-person';
  static const String profile = '/profile';
  static const String trackCase = '/track-case';
  static const String caseDetails = '/case-details';
  static const String login = '/login';
  static const String register = '/register';
  static const String submitTip = '/submit-tip';
  static const String fillUpForm = '/fill-up-form';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => HomeScreen(),
    missingPerson: (context) => MissingPersonScreen(),
    profile: (context) => ProfileScreen(),
    trackCase: (context) => TrackCaseScreen(),
    caseDetails: (context) => CaseDetailsScreen(report: {}),
    login: (context) => LoginPage(),
    register: (context) => RegisterPage(),
    submitTip: (context) => SubmitTipScreen(),
    fillUpForm: (context) => FillUpFormScreen(),
  };
}
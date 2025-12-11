import 'package:flutter/material.dart';
import '../../features/pricing/screens/pricing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/resumen/screens/home_screen.dart';

class AppRouter {
  static const String pricing = '/pricing';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case pricing:
        return MaterialPageRoute(builder: (_) => const PricingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => const PricingScreen());
    }
  }

  static Map<String, WidgetBuilder> get routes => {
    pricing: (context) => const PricingScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
  };
}

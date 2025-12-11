import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/routes/app_router.dart';
import 'src/shared/providers/auth_provider.dart';
import 'src/shared/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const MarketMoveApp());
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'MarketMove',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,
            initialRoute: _getInitialRoute(authProvider),
            onGenerateRoute: AppRouter.generateRoute,
            routes: AppRouter.routes,
          );
        },
      ),
    );
  }

  String _getInitialRoute(AuthProvider authProvider) {
    if (authProvider.isAuthenticated) {
      return AppRouter.home;
    }
    return AppRouter.pricing;
  }
}

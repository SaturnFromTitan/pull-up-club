import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:provider/provider.dart";
import "package:pull_up_club/common/constants/app_constants.dart";
import "package:pull_up_club/common/providers/auth_provider.dart";
import "package:pull_up_club/common/providers/navigation_provider.dart";
import "package:pull_up_club/common/providers/workout_history_provider.dart";
import "package:pull_up_club/common/screens/auth/login_screen.dart";
import "package:pull_up_club/common/screens/auth/signup_screen.dart";
import "package:pull_up_club/common/screens/shell_screen.dart";
import "package:pull_up_club/common/services/supabase_service.dart";
import "package:pull_up_club/common/services/sync_service.dart";
import "package:pull_up_club/common/services/workout_database.dart";
import "package:pull_up_club/common/themes/app_theme.dart";
import "package:pull_up_club/data/repositories/workout_repository.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
  Logger.root.onRecord.listen((final record) {
    debugPrint(
      "${DateTime.now().toUtc().toIso8601String()} ${record.level.name} ${record.loggerName}: ${record.message}",
    );
  });

  // Initialize Supabase
  try {
    await SupabaseService.initialize(
      supabaseUrl: AppConstants.supabaseUrl,
      supabaseAnonKey: AppConstants.supabaseAnonKey,
    );
  } catch (e) {
    Logger.root.severe("Failed to initialize Supabase: $e");
    // Continue anyway - app will show error if user tries to use features
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // Create repository and sync service as static instances
  static final _syncService = SyncService(WorkoutDatabase.instance);
  static final _workoutRepository = WorkoutRepository(
    WorkoutDatabase.instance,
    _syncService,
  );

  @override
  Widget build(final BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (final context) => AuthProvider()),
        ChangeNotifierProvider(create: (final context) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (final context) => WorkoutHistoryProvider(_workoutRepository),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appTitle,
        theme: appTheme,
        home: const AuthWrapper(),
        routes: {
          Shell.route: (final context) => const Shell(),
          "/login": (final context) => const LoginScreen(),
          "/signup": (final context) => const SignupScreen(),
        },
      ),
    );
  }
}

/// Wrapper widget that handles authentication state and routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(final BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authProvider.isAuthenticated) {
      // User is authenticated - show main app
      return const Shell();
    } else {
      // User is not authenticated - show login screen
      return const LoginScreen();
    }
  }
}

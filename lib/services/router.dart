import 'package:eye_focus/screens/dashboard/all_sessions_screen.dart';
import 'package:eye_focus/screens/dashboard/child_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eye_focus/screens/dashboard/music_library_screen.dart';
import 'package:eye_focus/screens/session/live_session_v2.dart';
import 'package:eye_focus/services/model_bridge.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/dashboard/children_screen.dart';
import '../screens/session/session_setup_screen.dart';
import '../screens/session/calibration_screen.dart';
import '../screens/results/results_screen.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final routerProvider = Provider<GoRouter>((ref) {
  // 2. الراوتر بيراقب الـ Stream
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // 3. السطر السحري: لو فايربيز لسه بيحمل (بيدور في الهارد)، متعملش توجيه واستنى!
      if (authState.isLoading) {
        return null; // ممكن قدام نبقى نعمل شاشة Splash بتلف، بس حالياً دي هتحل المشكلة
      }

      // 4. هنا فايربيز خلص تحميل، هنشوف في يوزر ولا لأ
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/signup');

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/children', builder: (_, __) => const ChildrenScreen()),
      GoRoute(
        path: '/session/setup',
        builder: (context, state) {
          final child = state.extra as ChildProfile?;
          return SessionSetupScreen(preselectedChild: child);
        },
      ),
      GoRoute(
        path: '/session/calibration',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return CalibrationScreen(
            child: args['child'] as ChildProfile,
            config: args['config'] as SessionConfig,
          );
        },
      ),
      GoRoute(
        path: '/session/live',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return LiveSessionScreen(
            child: args['child'] as ChildProfile,
            config: args['config'] as SessionConfig,
            bridge: args['bridge'] as ModelBridge?,
          );
        },
      ),
      GoRoute(
        path: '/results/:sessionId',
        builder: (context, state) {
          final result = state.extra as SessionResult;
          return ResultsScreen(result: result);
        },
      ),
      GoRoute(
        path: '/music-library',
        builder: (_, __) => const MusicLibraryScreen(),
      ),
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const AllSessionsScreen(),
      ),
      GoRoute(
        path: '/child-profile',
        builder: (context, state) {
          final child = state.extra as ChildProfile;
          return ChildProfileScreen(child: child);
        },
      ),
    ],
  );
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

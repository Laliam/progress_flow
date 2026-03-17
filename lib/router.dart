import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/application/auth_provider.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/tasks/domain/task.dart';
import 'features/tasks/presentation/task_creation_screen.dart';
import 'features/tasks/presentation/task_detail_screen.dart';
import 'features/tasks/presentation/leaderboard_screen.dart';
import 'features/tasks/presentation/join_goal_screen.dart';

/// A [ChangeNotifier] that fires whenever [isAuthenticatedProvider] changes,
/// allowing the router to re-evaluate its redirect without being recreated.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<bool>(isAuthenticatedProvider, (prev, next) => notifyListeners());
  }
}

/// Stable router provider — created once per [ProviderScope].
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/welcome' ||
          location.startsWith('/auth/');
      if (!isAuthenticated && !isAuthRoute) return '/welcome';
      if (isAuthenticated && isAuthRoute) return '/dashboard';
      if (location == '/') return isAuthenticated ? '/dashboard' : '/welcome';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/signin',
        name: 'sign_in',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/signup',
        name: 'sign_up',
        pageBuilder: (context, state) => const MaterialPage(
          child: SignUpScreen(),
        ),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        pageBuilder: (context, state) {
          final isSetup = (state.extra as Map?)?['setup'] == true;
          return MaterialPage(child: ProfileScreen(isSetup: isSetup));
        },
      ),
      GoRoute(
        path: '/task/new',
        name: 'task_new',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: TaskCreationScreen(),
        ),
      ),
      GoRoute(
        path: '/task/join',
        name: 'task_join',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: JoinGoalScreen(),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        name: 'task_detail',
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return MaterialPage(
            child: TaskDetailScreen(taskId: taskId),
          );
        },
      ),
      GoRoute(
        path: '/task/:id/edit',
        name: 'task_edit',
        pageBuilder: (context, state) {
          final task = state.extra as Task?;
          return MaterialPage(
            fullscreenDialog: true,
            child: TaskCreationScreen(taskToEdit: task),
          );
        },
      ),
      GoRoute(
        path: '/task/:id/leaderboard',
        name: 'task_leaderboard',
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return MaterialPage(
            child: LeaderboardScreen(taskId: taskId),
          );
        },
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});


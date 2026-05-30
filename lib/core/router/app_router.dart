import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/submit/presentation/submit_screen.dart';
import '../../features/thread/presentation/thread_screen.dart';

/// Application routes. Plain (non-redirecting) config — auth-gated actions guard
/// themselves and push `/signin` as needed.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: '/thread/:id',
        builder: (context, state) =>
            ThreadScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/submit',
        builder: (context, state) => const SubmitScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

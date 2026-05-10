import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/album/album_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/profiles/profiles_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/settings_page.dart';
import 'features/stats/stats_page.dart';

final _onboardedProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarded') ?? false;
});

class FigusApp extends ConsumerWidget {
  const FigusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardedAsync = ref.watch(_onboardedProvider);
    final router = GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final onboarded = onboardedAsync.value ?? true;
        if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
        return null;
      },
      routes: [
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingPage()),
        ShellRoute(
          builder: (_, __, child) => RootShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const AlbumPage()),
            GoRoute(path: '/stats', builder: (_, __) => const StatsPage()),
            GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
            GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
          ],
        ),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Figus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}

class RootShell extends StatelessWidget {
  final Widget child;
  const RootShell({super.key, required this.child});

  static const _tabs = ['/', '/stats', '/scan', '/settings'];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => loc == t || (t != '/' && loc.startsWith(t)));
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index < 0 ? 0 : index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Álbum'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Estatísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_rounded), label: 'Trocar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Config'),
        ],
      ),
    );
  }
}

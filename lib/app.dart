import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/album/album_page.dart';
import 'features/crafting/forge_page.dart';
import 'features/import/figuritas_import_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/profiles/profiles_page.dart';
import 'features/scan/scan_page.dart';
import 'features/settings/upgrade_page.dart';
import 'features/stats/stats_page.dart';
import 'features/trades/trades_page.dart';
import 'features/you/you_page.dart';

final onboardedProvider = FutureProvider<bool>((_) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarded') ?? false;
});

class FigusApp extends ConsumerWidget {
  const FigusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardedAsync = ref.watch(onboardedProvider);
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
            GoRoute(path: '/forge', builder: (_, __) => const ForgePage()),
            GoRoute(path: '/scan', builder: (_, __) => const ScanPage()),
            GoRoute(path: '/trades', builder: (_, __) => const TradesPage()),
            GoRoute(path: '/you', builder: (_, __) => const YouPage()),
            GoRoute(path: '/progress', builder: (_, __) => const StatsPage()),
          ],
        ),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesPage()),
        GoRoute(path: '/import', builder: (_, __) => const FiguritasImportPage()),
        GoRoute(path: '/upgrade', builder: (_, __) => const UpgradePage()),
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

  // 5-item nav with center FAB for Scan — distinct from Figuritas' flat 4-tabs.
  static const _navTabs = <_NavItem>[
    _NavItem('/', Icons.grid_view_rounded, 'Coleção'),
    _NavItem('/forge', Icons.auto_awesome_rounded, 'Forjar'),
    _NavItem('/scan', Icons.qr_code_scanner_rounded, '', isCenterFab: true),
    _NavItem('/trades', Icons.swap_horiz_rounded, 'Trocas'),
    _NavItem('/you', Icons.person_rounded, 'Você'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final activeIndex = _navTabs.indexWhere((t) => loc == t.path);
    return Scaffold(
      body: child,
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          heroTag: 'fab-scan',
          backgroundColor: AppTheme.seed,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 6,
          onPressed: () => context.go('/scan'),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: EdgeInsets.zero,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < _navTabs.length; i++)
              if (_navTabs[i].isCenterFab)
                const SizedBox(width: 60)
              else
                _NavButton(
                  item: _navTabs[i],
                  active: i == activeIndex,
                  onTap: () => context.go(_navTabs[i].path),
                ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final String label;
  final bool isCenterFab;
  const _NavItem(this.path, this.icon, this.label, {this.isCenterFab = false});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.seed : AppTheme.inkSoft;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

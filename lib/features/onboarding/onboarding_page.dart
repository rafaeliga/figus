import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Slide(
                    icon: Icons.touch_app_rounded,
                    title: 'Toque para colar',
                    subtitle: 'Marque a figurinha que você acabou de tirar do pacote.',
                  ),
                  _Slide(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Toque de novo se for repetida',
                    subtitle: 'O contador azul mostra quantas duplicatas você tem.',
                  ),
                  _Slide(
                    icon: Icons.delete_outline_rounded,
                    title: 'Pressione e segure pra remover',
                    subtitle: 'Errou? Sem stress, é só segurar.',
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppTheme.seed : AppTheme.slot,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () async {
                  if (_index < 2) {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
                  } else {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarded', true);
                    if (mounted) context.go('/');
                  }
                },
                child: Text(_index < 2 ? 'Próximo' : 'Entendi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Slide({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: AppTheme.seed),
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.inkSoft, fontSize: 16)),
        ],
      ),
    );
  }
}

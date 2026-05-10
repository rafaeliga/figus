import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text('Obter Pro (R\$ 9,90 lifetime)'),
            subtitle: const Text('Remove banner + temas premium'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Como funciona?'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHowItWorks(context),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline_rounded),
            title: const Text('Perfis (família)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profiles'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Sync entre dispositivos'),
            subtitle: const Text('Em breve'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Importar do Figuritas'),
            subtitle: const Text('Em breve'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tema'),
            subtitle: const Text('Segue o sistema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.coffee_outlined),
            title: const Text('Me paga um cafezinho'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _comingSoon(context),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Versão'),
            subtitle: Text('0.1.0 (alpha)'),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext c) {
    ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Em breve')));
  }

  void _showHowItWorks(BuildContext c) {
    showModalBottomSheet<void>(
      context: c,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text('Como funciona?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            SizedBox(height: 16),
            _HowRow(text: 'Toque para adicionar à sua coleção'),
            _HowRow(text: 'Toque novamente para marcar como repetida'),
            _HowRow(text: 'Pressione e segure para remover'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HowRow extends StatelessWidget {
  final String text;
  const _HowRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF1F66FF)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

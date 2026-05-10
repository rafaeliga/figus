import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfiles = ref.watch(profilesListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfis')),
      body: asyncProfiles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (profiles) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final p in profiles)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(p.avatarColor),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: p.isActive
                      ? const Chip(
                          label: Text('Ativo'),
                          backgroundColor: Color(0x221F66FF),
                          side: BorderSide.none,
                        )
                      : TextButton(
                          onPressed: () async {
                            await ref.read(profileRepoProvider).setActive(p.id);
                            ref.read(collectionVersionProvider.notifier).state++;
                          },
                          child: const Text('Ativar'),
                        ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Novo perfil'),
              onPressed: () => _addProfile(context, ref),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.slotSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off_outlined, color: AppTheme.inkSoft),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sync multi-device chega em breve. Você poderá fazer login e acessar o mesmo perfil em vários celulares.',
                      style: TextStyle(color: AppTheme.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProfile(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Novo perfil'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nome (ex.: Filho)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(profileRepoProvider).create(name);
    ref.read(collectionVersionProvider.notifier).state++;
  }
}

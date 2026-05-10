import 'package:flutter/material.dart';

/// Stub for the OCR scan flow — full pipeline (warp + glare + multi-frame +
/// album-lock) lands in night 2 per the plan.
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trocar / Scan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_rounded, size: 80, color: Color(0xFF1F66FF)),
            const SizedBox(height: 24),
            const Text(
              'Scan de página inteira',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tire foto da página do álbum físico — o app reconhece a seleção '
              'e marca automaticamente as figurinhas que você já colou.\n\n'
              'Sempre pede confirmação antes de salvar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF455066)),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('OCR completo chega na próxima atualização')),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Abrir câmera'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Importação Figuritas chega em breve')),
                );
              },
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Importar do Figuritas'),
            ),
          ],
        ),
      ),
    );
  }
}

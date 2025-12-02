import 'package:flutter/material.dart';

/// 親権者同意フロー（MVP外）
class ParentalConsentScreen extends StatelessWidget {
  const ParentalConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保護者同意（未実装）'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'MVPでは保護者同意フローを提供していません。\n\n'
            '今後のリリースで対応予定です。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

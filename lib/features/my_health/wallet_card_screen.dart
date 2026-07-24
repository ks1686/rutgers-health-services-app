import 'package:flutter/material.dart';

import '../../data/demo_health.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';

class WalletCardScreen extends StatelessWidget {
  const WalletCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Card'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: CwcColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle(
                style: const TextStyle(color: Colors.white, height: 1.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Health Snapshot',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sample data · works offline',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Medications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final med in demoMedications)
                      Text('• ${med.name} — ${med.purpose}'),
                    const SizedBox(height: 12),
                    const Text(
                      'Providers',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    for (final provider in demoProviders)
                      Text('• ${provider.name} (${provider.phone})'),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency contact',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(demoWalletEmergencyContact),
                    const SizedBox(height: 12),
                    const Text(
                      'Conditions (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Text(demoWalletConditions),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

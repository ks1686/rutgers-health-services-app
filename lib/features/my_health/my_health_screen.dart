import 'package:flutter/material.dart';

import '../../data/demo_health.dart';
import '../../theme/cwc_theme.dart';
import '../../widgets/demo_snackbar.dart';
import 'wallet_card_screen.dart';

class MyHealthScreen extends StatelessWidget {
  const MyHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CwcColors.primaryTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Sample only — this build does not lock My Health yet.',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Appointments',
          onAdd: () => showDemoOnlySnackBar(context, 'Add appointment'),
          children: [
            for (final appt in demoAppointments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(appt.provider),
                subtitle: Text(
                  '${appt.whenLabel}\n${appt.location}'
                  '${appt.note != null ? '\n${appt.note}' : ''}',
                ),
                isThreeLine: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Medications',
          onAdd: () => showDemoOnlySnackBar(context, 'Add medication'),
          children: [
            for (final med in demoMedications)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(med.name),
                subtitle: Text('${med.purpose}\n${med.schedule}'),
                isThreeLine: true,
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Providers & Portals',
          onAdd: () => showDemoOnlySnackBar(context, 'Add provider'),
          children: [
            for (final provider in demoProviders)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(provider.name),
                subtitle: Text(
                  '${provider.role}'
                  '${provider.portalLabel != null ? ' · ${provider.portalLabel}' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Call',
                  icon: const Icon(Icons.phone_outlined),
                  onPressed: () => showDemoOnlySnackBar(context, 'Call'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WalletCardScreen()),
            );
          },
          icon: const Icon(Icons.wallet_outlined),
          label: const Text('Show My Wallet Card'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Works offline — sample card for co-design review',
          textAlign: TextAlign.center,
          style: TextStyle(color: CwcColors.sub, fontSize: 13),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

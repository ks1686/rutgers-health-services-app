import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/help_now_button.dart';
import 'data/health_controller.dart';
import 'data/health_models.dart';
import 'health_scope.dart';

class ProviderFormScreen extends StatefulWidget {
  const ProviderFormScreen({super.key, this.existing});

  final HealthProvider? existing;

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _phone;
  late final TextEditingController _portalLabel;
  late final TextEditingController _portalUrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _role = TextEditingController(text: e?.role ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _portalLabel = TextEditingController(text: e?.portalLabel ?? '');
    _portalUrl = TextEditingController(text: e?.portalUrl ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _phone.dispose();
    _portalLabel.dispose();
    _portalUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = HealthScope.of(context);
    final id = widget.existing?.id ?? HealthController.newId();
    final label = _portalLabel.text.trim();
    final url = _portalUrl.text.trim();
    await controller.upsertProvider(
      HealthProvider(
        id: id,
        name: _name.text.trim(),
        role: _role.text.trim(),
        phone: _phone.text.trim(),
        portalLabel: label.isEmpty ? null : label,
        portalUrl: url.isEmpty ? null : url,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete provider?'),
        content: const Text('This removes the contact from this phone only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await HealthScope.of(context).deleteProvider(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit provider' : 'Add provider'),
        actions: const [HelpNowButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _role,
              decoration: const InputDecoration(
                labelText: 'Role (for example, Primary care)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a role' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+()\-\s]')),
              ],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portalLabel,
              decoration: const InputDecoration(
                labelText: 'Portal name (optional)',
                border: OutlineInputBorder(),
                helperText: 'We never save your portal password.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _portalUrl,
              decoration: const InputDecoration(
                labelText: 'Portal web address (optional)',
                border: OutlineInputBorder(),
                hintText: 'https://',
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final uri = Uri.tryParse(t);
                if (uri == null ||
                    (uri.scheme != 'https' && uri.scheme != 'http') ||
                    uri.host.isEmpty) {
                  return 'Use a full http or https address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
            if (editing) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _delete, child: const Text('Delete')),
            ],
          ],
        ),
      ),
    );
  }
}

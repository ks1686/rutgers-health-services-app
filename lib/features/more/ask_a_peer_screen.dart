import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import '../../widgets/link_launcher.dart';
import '../my_health/data/health_launchers.dart';
import '../settings/app_preferences.dart';
import 'peer_contact.dart';

/// People this member asks about the app. No partner number is built in.
class AskAPeerScreen extends StatelessWidget {
  const AskAPeerScreen({super.key, this.launcher});

  final LinkLauncher? launcher;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final open = launcher ?? _launchExternal;
    final opened = await open(uri);
    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open that on this phone.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesScope.of(context);
    final contacts = prefs.peerContacts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask a Peer'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'Add a person you can ask about this app. That can be your '
            'wellness-center peer support specialist, or a friend who helps '
            'with tech. These stay on this phone.',
            style: TextStyle(fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            const Text(
              'No one is saved on this phone yet.',
              style: TextStyle(fontSize: 18, height: 1.4, color: CwcColors.sub),
            ),
          for (final contact in contacts) ...[
            _PeerTile(
              contact: contact,
              onCall: _digits(contact.phone).isEmpty
                  ? null
                  : () => _open(context, healthTelUri(contact.phone)),
              onText: _digits(contact.phone).isEmpty
                  ? null
                  : () => _open(context, healthSmsUri(contact.phone)),
              onEdit: () => _edit(context, prefs, contact),
              onRemove: () => _remove(prefs, contact.id),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('add-peer-contact'),
            onPressed: () => _edit(context, prefs, null),
            child: const Text('Add a contact'),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    AppPreferences prefs,
    PeerContact? existing,
  ) async {
    final saved = await Navigator.of(context).push<PeerContact>(
      MaterialPageRoute(builder: (_) => _PeerContactForm(existing: existing)),
    );
    if (saved == null) return;
    final next = [...prefs.peerContacts];
    final index = next.indexWhere((contact) => contact.id == saved.id);
    if (index >= 0) {
      next[index] = saved;
    } else {
      next.add(saved);
    }
    await prefs.setPeerContacts(next);
  }

  Future<void> _remove(AppPreferences prefs, String id) {
    return prefs.setPeerContacts([
      for (final contact in prefs.peerContacts)
        if (contact.id != id) contact,
    ]);
  }
}

String _digits(String phone) => healthDigitsOnly(phone);

Future<bool> _launchExternal(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({
    required this.contact,
    required this.onCall,
    required this.onText,
    required this.onEdit,
    required this.onRemove,
  });

  final PeerContact contact;
  final VoidCallback? onCall;
  final VoidCallback? onText;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (contact.phone.isNotEmpty) contact.phone,
      if (contact.reach.isNotEmpty) contact.reach,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                lines.join('\n'),
                style: const TextStyle(fontSize: 18, height: 1.35),
              ),
            ],
            Wrap(
              children: [
                if (onCall != null)
                  TextButton(
                    key: ValueKey('peer-call-${contact.id}'),
                    onPressed: onCall,
                    child: const Text('Call'),
                  ),
                if (onText != null)
                  TextButton(
                    key: ValueKey('peer-text-${contact.id}'),
                    onPressed: onText,
                    child: const Text('Text'),
                  ),
                TextButton(
                  key: ValueKey('peer-edit-${contact.id}'),
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
                TextButton(
                  key: ValueKey('peer-remove-${contact.id}'),
                  onPressed: onRemove,
                  child: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerContactForm extends StatefulWidget {
  const _PeerContactForm({this.existing});

  final PeerContact? existing;

  @override
  State<_PeerContactForm> createState() => _PeerContactFormState();
}

class _PeerContactFormState extends State<_PeerContactForm> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _reach;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _reach = TextEditingController(text: existing?.reach ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _reach.dispose();
    super.dispose();
  }

  void _save() {
    final contact = PeerContact.tryCreate(
      id:
          widget.existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text,
      phone: _phone.text,
      reach: _reach.text,
    );
    if (contact == null) {
      setState(() {
        _error = 'Add a name, and a phone number or how you reach them.';
      });
      return;
    }
    Navigator.of(context).pop(contact);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit contact' : 'Add a contact'),
        actions: const [HelpNowButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            key: const ValueKey('peer-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('peer-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              helperText: 'Optional if you write another way to reach them.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('peer-reach'),
            controller: _reach,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'How you reach them',
              helperText:
                  'Text, in person, or another way. Optional if you add a phone.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 16)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            key: const ValueKey('save-peer-contact'),
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/cwc_theme.dart';
import '../../widgets/help_now_button.dart';
import 'data/document_file_picker.dart';
import 'data/health_controller.dart';
import 'data/health_models.dart';
import 'health_scope.dart';

class DocumentFormScreen extends StatefulWidget {
  const DocumentFormScreen({super.key, this.existing, this.pickFile});

  final HealthDocument? existing;

  /// Tests pass a stand-in. The app uses the phone's file picker.
  final Future<PickedPaperFile?> Function()? pickFile;

  @override
  State<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends State<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late HealthDocumentKind _kind;
  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _body = TextEditingController(text: e?.body ?? '');
    _kind = e?.kind ?? HealthDocumentKind.pad;
    _fileName = e?.fileName;
    final encoded = e?.fileBase64;
    if (encoded != null && encoded.isNotEmpty) {
      try {
        _fileBytes = base64Decode(encoded);
      } on FormatException {
        _fileBytes = null;
        _fileName = null;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final controller = HealthScope.of(context);
    final bytes = _fileBytes;
    await controller.upsertDocument(
      HealthDocument(
        id: widget.existing?.id ?? HealthController.newId(),
        kind: _kind,
        title: _title.text.trim(),
        body: _body.text.trim(),
        fileName: bytes == null ? null : _fileName,
        fileBase64: bytes == null ? null : base64Encode(bytes),
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
        title: const Text('Remove this paper?'),
        content: const Text('This deletes it from this phone only.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await HealthScope.of(context).deleteDocument(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _chooseFile() async {
    final pick = widget.pickFile ?? pickPaperFileFromPhone;
    try {
      final picked = await pick();
      if (!mounted || picked == null) return;
      setState(() {
        _fileName = picked.name;
        _fileBytes = picked.bytes;
      });
    } on PaperFileTooLarge {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That file is too big to keep with My Health. '
            'Choose one under 500 KB.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Open paper' : 'Add a paper'),
        actions: const [HelpNowButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Stays on this phone with the rest of My Health. '
              'It is not sent anywhere.',
              style: TextStyle(color: CwcColors.sub, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'What kind of paper',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            RadioGroup<HealthDocumentKind>(
              groupValue: _kind,
              onChanged: (next) {
                if (next == null) return;
                setState(() => _kind = next);
              },
              child: Column(
                children: [
                  for (final kind in HealthDocumentKind.values)
                    RadioListTile<HealthDocumentKind>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(kind.label),
                      value: kind,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Name for this paper',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              decoration: const InputDecoration(
                labelText: 'What you want to keep',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              minLines: 6,
              maxLines: 14,
              validator: (v) {
                final hasWords = v != null && v.trim().isNotEmpty;
                if (hasWords || _fileBytes != null) return null;
                return 'Write the words, or choose a file from this phone';
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _fileName == null
                    ? 'Choose a file from this phone'
                    : 'Replace file',
              ),
            ),
            if (_fileName != null && _fileBytes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Saved with this paper: $_fileName',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_isImageName(_fileName!)) ...[
                const SizedBox(height: 8),
                Image.memory(_fileBytes!, height: 160, fit: BoxFit.contain),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() {
                    _fileName = null;
                    _fileBytes = null;
                  }),
                  child: const Text('Remove file'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
            if (editing) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _delete, child: const Text('Remove')),
            ],
          ],
        ),
      ),
    );
  }
}

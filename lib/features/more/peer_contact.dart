import 'dart:convert';

/// A person this member asks about the app. Saved on the phone only.
class PeerContact {
  const PeerContact({
    required this.id,
    required this.name,
    this.phone = '',
    this.reach = '',
  });

  final String id;
  final String name;
  final String phone;
  final String reach;

  /// Name plus a phone or another way to reach them. Nothing is filled in.
  static PeerContact? tryCreate({
    required String id,
    required String name,
    String phone = '',
    String reach = '',
  }) {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final trimmedReach = reach.trim();
    if (trimmedName.isEmpty) return null;
    if (trimmedPhone.isEmpty && trimmedReach.isEmpty) return null;
    return PeerContact(
      id: id,
      name: trimmedName,
      phone: trimmedPhone,
      reach: trimmedReach,
    );
  }

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'reach': reach,
  };

  @override
  bool operator ==(Object other) {
    return other is PeerContact &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.reach == reach;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, reach);
}

String peerContactsToStored(List<PeerContact> contacts) {
  return jsonEncode([for (final contact in contacts) contact.toJson()]);
}

List<PeerContact> peerContactsFromStored(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return const [];
  final decoded = _decode(trimmed);
  if (decoded is! List) return const [];
  final contacts = <PeerContact>[];
  for (final item in decoded) {
    if (item is! Map) continue;
    final contact = PeerContact.tryCreate(
      id: '${item['id'] ?? ''}',
      name: '${item['name'] ?? ''}',
      phone: '${item['phone'] ?? ''}',
      reach: '${item['reach'] ?? ''}',
    );
    if (contact == null || contact.id.isEmpty) continue;
    contacts.add(contact);
  }
  return contacts;
}

Object? _decode(String raw) {
  try {
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

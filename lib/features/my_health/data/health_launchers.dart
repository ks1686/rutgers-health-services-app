/// External-link helpers for My Health call / text / portal (MYH-3).
String healthDigitsOnly(String phone) =>
    phone.replaceAll(RegExp(r'[^0-9]'), '');

Uri healthTelUri(String phone) =>
    Uri(scheme: 'tel', path: healthDigitsOnly(phone));

Uri healthSmsUri(String phone) =>
    Uri(scheme: 'sms', path: healthDigitsOnly(phone));

/// Returns an http(s) URI or null if the string is missing / unsafe for link-out.
Uri? healthPortalUri(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}

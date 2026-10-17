/// External-link helper for My Health portal link-outs (MYH-3).
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

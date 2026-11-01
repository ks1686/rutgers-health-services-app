/// Digits, tel, and sms for any phone number this app opens.
/// The member still places the call. Portal links stay in My Health.
String phoneDigitsOnly(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

Uri phoneTelUri(String phone) =>
    Uri(scheme: 'tel', path: phoneDigitsOnly(phone));

Uri phoneSmsUri(String phone) =>
    Uri(scheme: 'sms', path: phoneDigitsOnly(phone));

/// A number written the way people read it aloud: 988, 732-555-0100,
/// 1-800-222-1222. Anything else is shown as digits.
String phoneForDisplay(String phone) {
  final d = phoneDigitsOnly(phone);
  if (d.length == 10) {
    return '${d.substring(0, 3)}-${d.substring(3, 6)}-${d.substring(6)}';
  }
  if (d.length == 11 && d.startsWith('1')) {
    return '1-${phoneForDisplay(d.substring(1))}';
  }
  return d;
}

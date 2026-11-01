/// Digits, tel, and sms for any phone number this app opens.
/// The member still places the call. Portal links stay in My Health.
String phoneDigitsOnly(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

/// Digits for a tel or sms link, keeping a leading '+' so a number written
/// in international form (+44 ...) still reaches the right country.
String phoneDialable(String phone) {
  final digits = phoneDigitsOnly(phone);
  return phone.trimLeft().startsWith('+') ? '+$digits' : digits;
}

Uri phoneTelUri(String phone) => Uri(scheme: 'tel', path: phoneDialable(phone));

Uri phoneSmsUri(String phone) => Uri(scheme: 'sms', path: phoneDialable(phone));

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

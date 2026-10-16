/// Digits, tel, and sms for any phone number this app opens.
/// The member still places the call. Portal links stay in My Health.
String phoneDigitsOnly(String phone) => phone.replaceAll(RegExp(r'[^0-9]'), '');

Uri phoneTelUri(String phone) =>
    Uri(scheme: 'tel', path: phoneDigitsOnly(phone));

Uri phoneSmsUri(String phone) =>
    Uri(scheme: 'sms', path: phoneDigitsOnly(phone));

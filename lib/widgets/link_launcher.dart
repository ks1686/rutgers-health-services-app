/// Opens an external URI (tel, sms, http). Injected in tests.
typedef LinkLauncher = Future<bool> Function(Uri uri);

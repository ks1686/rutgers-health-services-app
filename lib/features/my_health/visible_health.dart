import 'package:flutter/widgets.dart';

import '../settings/app_preferences.dart';
import 'data/health_models.dart';
import 'health_scope.dart';

/// Shown in place of a record list while Helper Mode is on.
const kHelperHiddenHint = 'Hidden while someone is helping you.';

/// The My Health records a screen may show.
///
/// While Helper Mode is on every list is empty and the wallet is blank, so a
/// new section that reads from here cannot show details by forgetting a check.
/// [hidden] only picks the hint text and whether Add is offered.
class VisibleHealth {
  VisibleHealth({required HealthSnapshot snapshot, required this.hidden})
    : snapshot = hidden ? const HealthSnapshot() : snapshot;

  /// Reads Helper Mode from [AppPreferencesScope] and records from
  /// [HealthScope]. Either scope may be missing in a widget test.
  factory VisibleHealth.of(BuildContext context) {
    return VisibleHealth(
      snapshot:
          HealthScope.maybeOf(context)?.snapshot ?? const HealthSnapshot(),
      hidden: AppPreferencesScope.maybeOf(context)?.helperHiding ?? false,
    );
  }

  final bool hidden;
  final HealthSnapshot snapshot;

  List<HealthAppointment> get appointments => snapshot.appointments;
  List<HealthMedication> get medications => snapshot.medications;
  List<HealthProvider> get providers => snapshot.providers;
  List<HealthDocument> get documents => snapshot.documents;
  HealthWallet get wallet => snapshot.wallet;
}

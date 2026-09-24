/// On-device My Health models (MYH-1..4). No credentials, no cloud ids.
library;

class HealthAppointment {
  const HealthAppointment({
    required this.id,
    required this.provider,
    required this.whenLabel,
    required this.location,
    required this.phone,
    this.note,
    this.remind = false,
    this.when,
    this.remindAt,
  });

  final String id;
  final String provider;
  final String whenLabel;
  final String location;
  final String phone;
  final String? note;

  /// When true, this phone schedules an on-device alert for this visit.
  final bool remind;

  /// Appointment instant, local time. The display string stays in [whenLabel].
  final DateTime? when;

  /// When the alert fires. Defaults to [when] when the person has not picked
  /// a different time. Null means "use the appointment time."
  final DateTime? remindAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'whenLabel': whenLabel,
    'location': location,
    'phone': phone,
    if (note != null) 'note': note,
    'remind': remind,
    if (when != null) 'when': when!.toIso8601String(),
    if (remindAt != null) 'remindAt': remindAt!.toIso8601String(),
  };

  factory HealthAppointment.fromJson(Map<String, dynamic> json) {
    return HealthAppointment(
      id: json['id'] as String,
      provider: json['provider'] as String,
      whenLabel: json['whenLabel'] as String,
      location: json['location'] as String,
      phone: json['phone'] as String,
      note: json['note'] as String?,
      remind: json['remind'] as bool? ?? false,
      when: _parseIso(json['when']),
      remindAt: _parseIso(json['remindAt']),
    );
  }

  HealthAppointment copyWith({
    String? id,
    String? provider,
    String? whenLabel,
    String? location,
    String? phone,
    String? note,
    bool? remind,
    DateTime? when,
    DateTime? remindAt,
    bool clearNote = false,
  }) {
    return HealthAppointment(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      whenLabel: whenLabel ?? this.whenLabel,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      note: clearNote ? null : (note ?? this.note),
      remind: remind ?? this.remind,
      when: when ?? this.when,
      remindAt: remindAt ?? this.remindAt,
    );
  }
}

class HealthMedication {
  const HealthMedication({
    required this.id,
    required this.name,
    required this.purpose,
    required this.schedule,
    this.remind = false,
    this.remindMinutes = const [],
  });

  final String id;
  final String name;
  final String purpose;
  final String schedule;

  /// When true, this phone schedules a daily on-device alert for this medicine.
  final bool remind;

  /// Local minutes from midnight. The saved [name] and [schedule] are the alert.
  final List<int> remindMinutes;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'purpose': purpose,
    'schedule': schedule,
    'remind': remind,
    if (remindMinutes.isNotEmpty) 'remindMinutes': remindMinutes,
  };

  factory HealthMedication.fromJson(Map<String, dynamic> json) {
    return HealthMedication(
      id: json['id'] as String,
      name: json['name'] as String,
      purpose: json['purpose'] as String,
      schedule: json['schedule'] as String,
      remind: json['remind'] as bool? ?? false,
      remindMinutes: [
        for (final row in (json['remindMinutes'] as List? ?? const []))
          if (row is num) row.toInt(),
      ],
    );
  }

  HealthMedication copyWith({
    String? id,
    String? name,
    String? purpose,
    String? schedule,
    bool? remind,
    List<int>? remindMinutes,
  }) {
    return HealthMedication(
      id: id ?? this.id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      schedule: schedule ?? this.schedule,
      remind: remind ?? this.remind,
      remindMinutes: remindMinutes ?? this.remindMinutes,
    );
  }
}

DateTime? _parseIso(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

class HealthProvider {
  const HealthProvider({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.portalLabel,
    this.portalUrl,
  });

  final String id;
  final String name;
  final String role;
  final String phone;
  final String? portalLabel;

  /// Login page URL only — never credentials (MYH-3).
  final String? portalUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'phone': phone,
    if (portalLabel != null) 'portalLabel': portalLabel,
    if (portalUrl != null) 'portalUrl': portalUrl,
  };

  factory HealthProvider.fromJson(Map<String, dynamic> json) {
    return HealthProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String,
      portalLabel: json['portalLabel'] as String?,
      portalUrl: json['portalUrl'] as String?,
    );
  }

  HealthProvider copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? portalLabel,
    String? portalUrl,
    bool clearPortalLabel = false,
    bool clearPortalUrl = false,
  }) {
    return HealthProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      portalLabel: clearPortalLabel ? null : (portalLabel ?? this.portalLabel),
      portalUrl: clearPortalUrl ? null : (portalUrl ?? this.portalUrl),
    );
  }
}

/// A paper the person keeps in My Health, on this phone only.
enum HealthDocumentKind {
  pad,
  livingWill,
  serviceAnimal,
  ratPlan,
  chargeIt,
  otherPaper,
}

extension HealthDocumentKindLabel on HealthDocumentKind {
  String get label => switch (this) {
    HealthDocumentKind.pad => 'Psychiatric advance directive',
    HealthDocumentKind.livingWill => 'Living will',
    HealthDocumentKind.serviceAnimal => 'Service or support animal',
    HealthDocumentKind.ratPlan => 'RAT plan',
    HealthDocumentKind.chargeIt => 'Charge It workbook',
    HealthDocumentKind.otherPaper => 'Other personal paper',
  };

  static HealthDocumentKind parse(String? raw) {
    for (final kind in HealthDocumentKind.values) {
      if (kind.name == raw) return kind;
    }
    return HealthDocumentKind.otherPaper;
  }
}

class HealthDocument {
  const HealthDocument({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.fileName,
    this.fileBase64,
  });

  /// Files live inside the same encrypted My Health record. Keep each one
  /// small enough for that record.
  static const maxFileBytes = 512 * 1024;

  final String id;
  final HealthDocumentKind kind;
  final String title;
  final String body;
  final String? fileName;

  /// Base64 file bytes. Null when the paper is words only.
  final String? fileBase64;

  bool get hasFile =>
      fileName != null &&
      fileName!.isNotEmpty &&
      fileBase64 != null &&
      fileBase64!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'body': body,
    if (fileName != null) 'fileName': fileName,
    if (fileBase64 != null) 'fileBase64': fileBase64,
  };

  factory HealthDocument.fromJson(Map<String, dynamic> json) {
    return HealthDocument(
      id: json['id'] as String,
      kind: HealthDocumentKindLabel.parse(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      fileName: json['fileName'] as String?,
      fileBase64: json['fileBase64'] as String?,
    );
  }

  HealthDocument copyWith({
    String? id,
    HealthDocumentKind? kind,
    String? title,
    String? body,
    String? fileName,
    String? fileBase64,
    bool clearFile = false,
  }) {
    return HealthDocument(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      fileName: clearFile ? null : (fileName ?? this.fileName),
      fileBase64: clearFile ? null : (fileBase64 ?? this.fileBase64),
    );
  }
}

class HealthWallet {
  const HealthWallet({this.emergencyContact = '', this.conditions = ''});

  final String emergencyContact;
  final String conditions;

  Map<String, dynamic> toJson() => {
    'emergencyContact': emergencyContact,
    'conditions': conditions,
  };

  factory HealthWallet.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HealthWallet();
    return HealthWallet(
      emergencyContact: (json['emergencyContact'] as String?) ?? '',
      conditions: (json['conditions'] as String?) ?? '',
    );
  }

  HealthWallet copyWith({String? emergencyContact, String? conditions}) {
    return HealthWallet(
      emergencyContact: emergencyContact ?? this.emergencyContact,
      conditions: conditions ?? this.conditions,
    );
  }
}

/// What Help Now may show without opening the rest of My Health.
/// Every flag starts off so a new or older save discloses nothing.
class EmergencyCardChoices {
  const EmergencyCardChoices({
    this.showEmergencyContact = false,
    this.showConditions = false,
    this.showMedications = false,
    this.showProviders = false,
    this.showAppointmentNotes = false,
    this.showPsychiatricAdvanceDirective = false,
  });

  final bool showEmergencyContact;
  final bool showConditions;
  final bool showMedications;
  final bool showProviders;
  final bool showAppointmentNotes;
  final bool showPsychiatricAdvanceDirective;

  bool get sharesAnything =>
      showEmergencyContact ||
      showConditions ||
      showMedications ||
      showProviders ||
      showAppointmentNotes ||
      showPsychiatricAdvanceDirective;

  Map<String, dynamic> toJson() => {
    'showEmergencyContact': showEmergencyContact,
    'showConditions': showConditions,
    'showMedications': showMedications,
    'showProviders': showProviders,
    'showAppointmentNotes': showAppointmentNotes,
    'showPsychiatricAdvanceDirective': showPsychiatricAdvanceDirective,
  };

  factory EmergencyCardChoices.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmergencyCardChoices();
    bool flag(String key) => json[key] == true;
    return EmergencyCardChoices(
      showEmergencyContact: flag('showEmergencyContact'),
      showConditions: flag('showConditions'),
      showMedications: flag('showMedications'),
      showProviders: flag('showProviders'),
      showAppointmentNotes: flag('showAppointmentNotes'),
      showPsychiatricAdvanceDirective: flag('showPsychiatricAdvanceDirective'),
    );
  }

  EmergencyCardChoices copyWith({
    bool? showEmergencyContact,
    bool? showConditions,
    bool? showMedications,
    bool? showProviders,
    bool? showAppointmentNotes,
    bool? showPsychiatricAdvanceDirective,
  }) {
    return EmergencyCardChoices(
      showEmergencyContact: showEmergencyContact ?? this.showEmergencyContact,
      showConditions: showConditions ?? this.showConditions,
      showMedications: showMedications ?? this.showMedications,
      showProviders: showProviders ?? this.showProviders,
      showAppointmentNotes: showAppointmentNotes ?? this.showAppointmentNotes,
      showPsychiatricAdvanceDirective:
          showPsychiatricAdvanceDirective ??
          this.showPsychiatricAdvanceDirective,
    );
  }
}

class HealthSnapshot {
  const HealthSnapshot({
    this.appointments = const [],
    this.medications = const [],
    this.providers = const [],
    this.documents = const [],
    this.wallet = const HealthWallet(),
    this.emergencyCard = const EmergencyCardChoices(),
    this.pinHash,
    this.initialized = false,
  });

  final List<HealthAppointment> appointments;
  final List<HealthMedication> medications;
  final List<HealthProvider> providers;
  final List<HealthDocument> documents;
  final HealthWallet wallet;
  final EmergencyCardChoices emergencyCard;
  final String? pinHash;

  /// True after first seed or erase — prevents re-seeding demo data.
  final bool initialized;

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'appointments': [for (final a in appointments) a.toJson()],
    'medications': [for (final m in medications) m.toJson()],
    'providers': [for (final p in providers) p.toJson()],
    'documents': [for (final d in documents) d.toJson()],
    'wallet': wallet.toJson(),
    'emergencyCard': emergencyCard.toJson(),
    if (pinHash != null) 'pinHash': pinHash,
    'initialized': initialized,
  };

  factory HealthSnapshot.fromJson(Map<String, dynamic> json) {
    return HealthSnapshot(
      appointments: [
        for (final row in (json['appointments'] as List? ?? const []))
          if (row is Map)
            HealthAppointment.fromJson(Map<String, dynamic>.from(row)),
      ],
      medications: [
        for (final row in (json['medications'] as List? ?? const []))
          if (row is Map)
            HealthMedication.fromJson(Map<String, dynamic>.from(row)),
      ],
      providers: [
        for (final row in (json['providers'] as List? ?? const []))
          if (row is Map)
            HealthProvider.fromJson(Map<String, dynamic>.from(row)),
      ],
      documents: [
        for (final row in (json['documents'] as List? ?? const []))
          if (row is Map)
            HealthDocument.fromJson(Map<String, dynamic>.from(row)),
      ],
      wallet: HealthWallet.fromJson(
        json['wallet'] is Map
            ? Map<String, dynamic>.from(json['wallet'] as Map)
            : null,
      ),
      emergencyCard: EmergencyCardChoices.fromJson(
        json['emergencyCard'] is Map
            ? Map<String, dynamic>.from(json['emergencyCard'] as Map)
            : null,
      ),
      pinHash: json['pinHash'] as String?,
      initialized: json['initialized'] as bool? ?? false,
    );
  }

  HealthSnapshot copyWith({
    List<HealthAppointment>? appointments,
    List<HealthMedication>? medications,
    List<HealthProvider>? providers,
    List<HealthDocument>? documents,
    HealthWallet? wallet,
    EmergencyCardChoices? emergencyCard,
    String? pinHash,
    bool? initialized,
    bool clearPinHash = false,
  }) {
    return HealthSnapshot(
      appointments: appointments ?? this.appointments,
      medications: medications ?? this.medications,
      providers: providers ?? this.providers,
      documents: documents ?? this.documents,
      wallet: wallet ?? this.wallet,
      emergencyCard: emergencyCard ?? this.emergencyCard,
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      initialized: initialized ?? this.initialized,
    );
  }
}

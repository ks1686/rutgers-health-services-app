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
  });

  final String id;
  final String provider;
  final String whenLabel;
  final String location;
  final String phone;
  final String? note;

  /// Stored preference only — OS notifications are out of scope this award.
  final bool remind;

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'whenLabel': whenLabel,
    'location': location,
    'phone': phone,
    if (note != null) 'note': note,
    'remind': remind,
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
  });

  final String id;
  final String name;
  final String purpose;
  final String schedule;
  final bool remind;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'purpose': purpose,
    'schedule': schedule,
    'remind': remind,
  };

  factory HealthMedication.fromJson(Map<String, dynamic> json) {
    return HealthMedication(
      id: json['id'] as String,
      name: json['name'] as String,
      purpose: json['purpose'] as String,
      schedule: json['schedule'] as String,
      remind: json['remind'] as bool? ?? false,
    );
  }

  HealthMedication copyWith({
    String? id,
    String? name,
    String? purpose,
    String? schedule,
    bool? remind,
  }) {
    return HealthMedication(
      id: id ?? this.id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      schedule: schedule ?? this.schedule,
      remind: remind ?? this.remind,
    );
  }
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

class HealthSnapshot {
  const HealthSnapshot({
    this.appointments = const [],
    this.medications = const [],
    this.providers = const [],
    this.wallet = const HealthWallet(),
    this.pinHash,
    this.initialized = false,
  });

  final List<HealthAppointment> appointments;
  final List<HealthMedication> medications;
  final List<HealthProvider> providers;
  final HealthWallet wallet;
  final String? pinHash;

  /// True after first seed or erase — prevents re-seeding demo data.
  final bool initialized;

  bool get hasPin => pinHash != null && pinHash!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'appointments': [for (final a in appointments) a.toJson()],
    'medications': [for (final m in medications) m.toJson()],
    'providers': [for (final p in providers) p.toJson()],
    'wallet': wallet.toJson(),
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
      wallet: HealthWallet.fromJson(
        json['wallet'] is Map
            ? Map<String, dynamic>.from(json['wallet'] as Map)
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
    HealthWallet? wallet,
    String? pinHash,
    bool? initialized,
    bool clearPinHash = false,
  }) {
    return HealthSnapshot(
      appointments: appointments ?? this.appointments,
      medications: medications ?? this.medications,
      providers: providers ?? this.providers,
      wallet: wallet ?? this.wallet,
      pinHash: clearPinHash ? null : (pinHash ?? this.pinHash),
      initialized: initialized ?? this.initialized,
    );
  }
}

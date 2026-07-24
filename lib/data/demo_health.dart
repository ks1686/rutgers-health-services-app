class DemoAppointment {
  const DemoAppointment({
    required this.provider,
    required this.whenLabel,
    required this.location,
    required this.phone,
    this.note,
  });

  final String provider;
  final String whenLabel;
  final String location;
  final String phone;
  final String? note;
}

class DemoMedication {
  const DemoMedication({
    required this.name,
    required this.purpose,
    required this.schedule,
  });

  final String name;
  final String purpose;
  final String schedule;
}

class DemoProvider {
  const DemoProvider({
    required this.name,
    required this.role,
    required this.phone,
    this.portalLabel,
  });

  final String name;
  final String role;
  final String phone;
  final String? portalLabel;
}

const demoAppointments = <DemoAppointment>[
  DemoAppointment(
    provider: 'Dr. Rivera',
    whenLabel: 'Thu, Aug 7 · 10:30 AM',
    location: 'Community Health Clinic',
    phone: '(732) 555-0198',
    note: 'Bring medication list',
  ),
  DemoAppointment(
    provider: 'Counseling — Peer group',
    whenLabel: 'Mon, Aug 11 · 2:00 PM',
    location: 'New Brunswick Wellness Center',
    phone: '(732) 555-0177',
  ),
];

const demoMedications = <DemoMedication>[
  DemoMedication(
    name: 'Metformin',
    purpose: 'Blood sugar',
    schedule: '1 tablet morning and evening with food',
  ),
  DemoMedication(
    name: 'Sertraline',
    purpose: 'Mood',
    schedule: '1 tablet each morning',
  ),
];

const demoProviders = <DemoProvider>[
  DemoProvider(
    name: 'Dr. Rivera',
    role: 'Primary care',
    phone: '(732) 555-0198',
    portalLabel: 'Clinic patient portal',
  ),
  DemoProvider(
    name: 'Main Street Pharmacy',
    role: 'Pharmacy',
    phone: '(732) 555-0142',
  ),
];

const demoWalletEmergencyContact = 'Alex M. · (732) 555-0100';
const demoWalletConditions = 'Diabetes · Anxiety';

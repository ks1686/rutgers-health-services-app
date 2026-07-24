class DemoResource {
  const DemoResource({
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.description,
    required this.walkTime,
    this.transitHint,
    this.status = 'Open today',
  });

  final String name;
  final String category;
  final String address;
  final String phone;
  final String description;
  final String walkTime;
  final String? transitHint;
  final String status;
}

const demoTown = 'New Brunswick';

const demoCategories = <String>[
  'All',
  'Pharmacy',
  'Clinic',
  'Urgent care',
  'CWC',
  'Wellness',
];

const demoResources = <DemoResource>[
  DemoResource(
    name: 'Main Street Pharmacy',
    category: 'Pharmacy',
    address: '214 Main St, New Brunswick, NJ',
    phone: '(732) 555-0142',
    description: 'Prescriptions, over-the-counter care, and flu shots.',
    walkTime: 'about a 12 min walk',
    transitHint: 'Near NJ Transit bus stop',
    status: 'Open until 7pm',
  ),
  DemoResource(
    name: 'Community Health Clinic',
    category: 'Clinic',
    address: '88 Somerset St, New Brunswick, NJ',
    phone: '(732) 555-0198',
    description: 'Primary care and walk-in hours for uninsured patients.',
    walkTime: 'about a 18 min walk',
    status: 'Open today',
  ),
  DemoResource(
    name: 'Riverside Urgent Care',
    category: 'Urgent care',
    address: '15 Albany St, New Brunswick, NJ',
    phone: '(732) 555-0110',
    description: 'Same-day care for non-emergency illness and injury.',
    walkTime: 'about a 25 min walk',
    transitHint: 'Bus 810 nearby',
    status: 'Open until 9pm',
  ),
  DemoResource(
    name: 'New Brunswick Wellness Center',
    category: 'CWC',
    address: 'Peer-run recovery support — sample listing',
    phone: '(732) 555-0177',
    description: 'Peer support, wellness groups, and drop-in hours.',
    walkTime: 'about a 10 min walk',
    status: 'Drop-in welcome',
  ),
  DemoResource(
    name: 'Riverwalk Fitness Room',
    category: 'Wellness',
    address: 'Community center gym (sample)',
    phone: '(732) 555-0166',
    description: 'Free open gym hours and beginner movement classes.',
    walkTime: 'about a 20 min walk',
    status: 'Open evenings',
  ),
];

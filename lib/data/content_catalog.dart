import 'dart:convert';

import 'demo_health.dart';
import 'demo_help_now.dart';
import 'demo_learn.dart';
import 'demo_resources.dart';

List<DemoLearnTopic> parseLearnTopics(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) {
    throw const FormatException('learn.json must be a list');
  }
  return [
    for (final row in decoded)
      if (row is Map)
        DemoLearnTopic(
          title: row['title'] as String,
          iconLabel: row['iconLabel'] as String,
          summary: row['summary'] as String,
          body: row['body'] as String,
          source: row['source'] as String,
        ),
  ];
}

List<DemoHelpAction> parseHelpNowActions(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) {
    throw const FormatException('help_now.json must be an object');
  }
  final demo = decoded['demo'];
  if (demo is! List) {
    throw const FormatException('help_now.json demo must be a list');
  }
  return [
    for (final row in demo)
      if (row is Map)
        DemoHelpAction(
          label: row['label'] as String,
          detail: row['detail'] as String,
          style: DemoHelpStyle.values.byName(row['style'] as String),
        ),
  ];
}

({
  List<DemoAppointment> appointments,
  List<DemoMedication> medications,
  List<DemoProvider> providers,
  String walletEmergencyContact,
  String walletConditions,
})
parseHealthCatalog(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) {
    throw const FormatException('health.json must be an object');
  }
  return (
    appointments: [
      for (final row in decoded['appointments'] as List)
        if (row is Map)
          DemoAppointment(
            provider: row['provider'] as String,
            whenLabel: row['whenLabel'] as String,
            location: row['location'] as String,
            phone: row['phone'] as String,
            note: row['note'] as String?,
          ),
    ],
    medications: [
      for (final row in decoded['medications'] as List)
        if (row is Map)
          DemoMedication(
            name: row['name'] as String,
            purpose: row['purpose'] as String,
            schedule: row['schedule'] as String,
          ),
    ],
    providers: [
      for (final row in decoded['providers'] as List)
        if (row is Map)
          DemoProvider(
            name: row['name'] as String,
            role: row['role'] as String,
            phone: row['phone'] as String,
            portalLabel: row['portalLabel'] as String?,
          ),
    ],
    walletEmergencyContact: decoded['walletEmergencyContact'] as String,
    walletConditions: decoded['walletConditions'] as String,
  );
}

({String town, List<String> categories, List<DemoResource> resources})
parseResourceCatalog(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map) {
    throw const FormatException('resources.json must be an object');
  }
  return (
    town: decoded['town'] as String,
    categories: [for (final row in decoded['categories'] as List) '$row'],
    resources: [
      for (final row in decoded['resources'] as List)
        if (row is Map)
          DemoResource(
            name: row['name'] as String,
            category: row['category'] as String,
            address: row['address'] as String,
            phone: row['phone'] as String,
            description: row['description'] as String,
            walkTime: row['walkTime'] as String,
            transitHint: row['transitHint'] as String?,
            status: (row['status'] as String?) ?? 'Open today',
          ),
    ],
  );
}

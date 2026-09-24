import 'health_models.dart';

/// Words Help Now may show from the locked record. Omitted fields are absent,
/// including their labels, so a locked screen cannot reveal them.
String emergencyCardPreview(HealthSnapshot snapshot) {
  final choices = snapshot.emergencyCard;
  if (!choices.sharesAnything) {
    return 'Emergency card\n'
        'Nothing from My Health is on this card yet.';
  }

  final lines = <String>['Emergency card'];
  if (choices.showEmergencyContact) {
    lines.add('Contact: ${_orEmpty(snapshot.wallet.emergencyContact)}');
  }
  if (choices.showConditions) {
    lines.add('Conditions: ${_orEmpty(snapshot.wallet.conditions)}');
  }
  if (choices.showMedications) {
    if (snapshot.medications.isEmpty) {
      lines.add('Medications: None saved yet');
    } else {
      lines.add('Medications:');
      for (final med in snapshot.medications) {
        lines.add('• ${med.name} — ${med.purpose}');
      }
    }
  }
  if (choices.showProviders) {
    if (snapshot.providers.isEmpty) {
      lines.add('Providers: None saved yet');
    } else {
      lines.add('Providers:');
      for (final provider in snapshot.providers) {
        lines.add('• ${provider.name} (${provider.phone})');
      }
    }
  }
  if (choices.showAppointmentNotes) {
    final notes = [
      for (final appointment in snapshot.appointments)
        if (appointment.note != null && appointment.note!.trim().isNotEmpty)
          appointment.note!.trim(),
    ];
    if (notes.isEmpty) {
      lines.add('Appointment notes: None saved yet');
    } else {
      lines.add('Appointment notes:');
      lines.addAll(notes);
    }
  }
  if (choices.showPsychiatricAdvanceDirective) {
    final papers = [
      for (final paper in snapshot.documents)
        if (paper.kind == HealthDocumentKind.pad) paper,
    ];
    if (papers.isEmpty) {
      lines.add('Psychiatric advance directive: None saved yet');
    } else {
      lines.add('Psychiatric advance directive:');
      for (final paper in papers) {
        lines.add(paper.title);
        if (paper.body.trim().isNotEmpty) lines.add(paper.body.trim());
        if (paper.hasFile) {
          lines.add('File on this phone: ${paper.fileName}');
        }
      }
    }
  }
  return lines.join('\n');
}

String _orEmpty(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'None saved yet' : trimmed;
}

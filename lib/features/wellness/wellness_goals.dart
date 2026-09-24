import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../settings/app_preferences.dart';

const kWellnessGoalsPref = 'cwc_wellness_goals';

/// Optional in-app nudges. All switches start off. Not part of Learn.
class WellnessGoals {
  const WellnessGoals({
    this.water = false,
    this.breath = false,
    this.steps = false,
    this.steadySleep = false,
    this.stepGoal = 4000,
    this.nudgeWhenClose = false,
    this.stepsToday = 0,
    this.waterMinutes = 9 * 60,
    this.breathMinutes = 15 * 60,
    this.wakeMinutes = 7 * 60,
    this.bedMinutes = 22 * 60,
  });

  final bool water;
  final bool breath;
  final bool steps;
  final bool steadySleep;
  final int stepGoal;
  final bool nudgeWhenClose;
  final int stepsToday;
  final int waterMinutes;
  final int breathMinutes;
  final int wakeMinutes;
  final int bedMinutes;

  /// Close means at least 80% of the goal, and not there yet.
  bool get showCloseNudge {
    if (!steps || !nudgeWhenClose || stepGoal <= 0) return false;
    final closeAt = (stepGoal * 4) ~/ 5;
    return stepsToday >= closeAt && stepsToday < stepGoal;
  }

  WellnessGoals copyWith({
    bool? water,
    bool? breath,
    bool? steps,
    bool? steadySleep,
    int? stepGoal,
    bool? nudgeWhenClose,
    int? stepsToday,
    int? waterMinutes,
    int? breathMinutes,
    int? wakeMinutes,
    int? bedMinutes,
  }) {
    return WellnessGoals(
      water: water ?? this.water,
      breath: breath ?? this.breath,
      steps: steps ?? this.steps,
      steadySleep: steadySleep ?? this.steadySleep,
      stepGoal: stepGoal ?? this.stepGoal,
      nudgeWhenClose: nudgeWhenClose ?? this.nudgeWhenClose,
      stepsToday: stepsToday ?? this.stepsToday,
      waterMinutes: waterMinutes ?? this.waterMinutes,
      breathMinutes: breathMinutes ?? this.breathMinutes,
      wakeMinutes: wakeMinutes ?? this.wakeMinutes,
      bedMinutes: bedMinutes ?? this.bedMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'water': water,
    'breath': breath,
    'steps': steps,
    'steadySleep': steadySleep,
    'stepGoal': stepGoal,
    'nudgeWhenClose': nudgeWhenClose,
    'stepsToday': stepsToday,
    'waterMinutes': waterMinutes,
    'breathMinutes': breathMinutes,
    'wakeMinutes': wakeMinutes,
    'bedMinutes': bedMinutes,
  };

  factory WellnessGoals.fromJson(Map<String, dynamic> json) {
    return WellnessGoals(
      water: json['water'] as bool? ?? false,
      breath: json['breath'] as bool? ?? false,
      steps: json['steps'] as bool? ?? false,
      steadySleep: json['steadySleep'] as bool? ?? false,
      stepGoal: json['stepGoal'] as int? ?? 4000,
      nudgeWhenClose: json['nudgeWhenClose'] as bool? ?? false,
      stepsToday: json['stepsToday'] as int? ?? 0,
      waterMinutes: json['waterMinutes'] as int? ?? 9 * 60,
      breathMinutes: json['breathMinutes'] as int? ?? 15 * 60,
      wakeMinutes: json['wakeMinutes'] as int? ?? 7 * 60,
      bedMinutes: json['bedMinutes'] as int? ?? 22 * 60,
    );
  }
}

class WellnessGoalsStore extends ChangeNotifier {
  WellnessGoalsStore(this._store);

  final PreferenceStore _store;
  WellnessGoals _goals = const WellnessGoals();

  WellnessGoals get goals => _goals;

  void load() {
    final raw = _store.values[kWellnessGoalsPref];
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _goals = WellnessGoals.fromJson(Map<String, dynamic>.from(decoded));
      }
    }
    notifyListeners();
  }

  Future<void> update(WellnessGoals next) async {
    _goals = next;
    await _store.write(kWellnessGoalsPref, jsonEncode(next.toJson()));
    notifyListeners();
  }
}

String formatMinutes(int minutes) {
  final hour24 = minutes ~/ 60;
  final minute = minutes % 60;
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final mm = minute.toString().padLeft(2, '0');
  return '$hour12:$mm $suffix';
}

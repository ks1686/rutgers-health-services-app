/// New Jersey area, then a town, for Nearby (#37).
///
/// These are municipalities Nominatim can geocode. They are not a claim that
/// each town has a Community Wellness Center.
enum NjRegion {
  north,
  central,
  south;

  String get label => switch (this) {
    NjRegion.north => 'North',
    NjRegion.central => 'Central',
    NjRegion.south => 'South',
  };

  static NjRegion? tryParse(String? raw) {
    for (final region in NjRegion.values) {
      if (region.name == raw) return region;
    }
    return null;
  }
}

const kNjTowns = <NjRegion, List<String>>{
  NjRegion.north: [
    'Clifton',
    'East Orange',
    'Elizabeth',
    'Hackensack',
    'Hoboken',
    'Jersey City',
    'Newark',
    'Passaic',
    'Paterson',
    'Union City',
  ],
  NjRegion.central: [
    'Edison',
    'Long Branch',
    'New Brunswick',
    'Perth Amboy',
    'Piscataway',
    'Plainfield',
    'Princeton',
    'Sayreville',
    'Trenton',
    'Woodbridge',
  ],
  NjRegion.south: [
    'Atlantic City',
    'Bridgeton',
    'Camden',
    'Cherry Hill',
    'Glassboro',
    'Millville',
    'Pleasantville',
    'Toms River',
    'Vineland',
    'Willingboro',
  ],
};

/// Region that lists [town], when the town is one of the picker choices.
NjRegion? regionForTown(String town) {
  final trimmed = town.trim();
  if (trimmed.isEmpty) return null;
  for (final entry in kNjTowns.entries) {
    if (entry.value.contains(trimmed)) return entry.key;
  }
  return null;
}

class NearbyPlacePreference {
  const NearbyPlacePreference({required this.region, required this.town});

  final NjRegion region;
  final String town;

  static const fallback = NearbyPlacePreference(
    region: NjRegion.central,
    town: 'New Brunswick',
  );

  static NearbyPlacePreference resolve({String? regionName, String? town}) {
    final region = NjRegion.tryParse(regionName);
    if (region == null || town == null) return fallback;
    final towns = kNjTowns[region];
    if (towns == null || !towns.contains(town)) return fallback;
    return NearbyPlacePreference(region: region, town: town);
  }
}

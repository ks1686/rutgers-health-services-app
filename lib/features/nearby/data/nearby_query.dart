/// Town-scoped lookup for live Nearby (v1 uses Nominatim, not GPS).
class NearbyQuery {
  const NearbyQuery({this.town = 'New Brunswick', this.stateCode = 'NJ'});

  final String town;
  final String stateCode;
}

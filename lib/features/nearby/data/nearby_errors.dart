/// Member-facing Nearby failure copy. Never interpolate exceptions here.
const kNearbyMemberLookupFailed = 'We could not look up that town right now.';
const kNearbyMemberLoadFailed = 'We could not load places right now.';

/// Empty live result around the member's own coordinates (no town name known).
const kNearbyNoPlacesNearYou =
    'We did not find any of those places close to you right now.';

/// Default town used when a caller has no query yet (matches [NearbyQuery]).
const kNearbyDefaultTown = 'New Brunswick';

/// Device location refused — never re-ask automatically after a "no".
String nearbyLocationDeniedMessage([String town = kNearbyDefaultTown]) =>
    'That is okay. We went back to places near $town. '
    'You can turn location on any time in your phone settings.';

/// Location services switched off system-wide.
String nearbyLocationOffMessage([String town = kNearbyDefaultTown]) =>
    'Location is turned off on this phone, so we looked near $town instead.';

/// The fix itself failed (timeout / radio trouble) — fell back to town copy.
String nearbyLocationUnavailableMessage([String town = kNearbyDefaultTown]) =>
    'We could not get your location just now, so these are the saved '
    '$town places.';

/// Back-compat aliases for tests and older call sites (default town).
final kNearbyLocationDenied = nearbyLocationDeniedMessage();
final kNearbyLocationOff = nearbyLocationOffMessage();
final kNearbyLocationUnavailable = nearbyLocationUnavailableMessage();

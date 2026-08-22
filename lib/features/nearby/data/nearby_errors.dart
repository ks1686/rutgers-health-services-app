/// Member-facing Nearby failure copy. Never interpolate exceptions here.
const kNearbyMemberLookupFailed = 'We could not look up that town right now.';
const kNearbyMemberLoadFailed = 'We could not load places right now.';

/// Empty live result around the member's own coordinates (no town name known).
const kNearbyNoPlacesNearYou =
    'We did not find any of those places close to you right now.';

/// Device location refused — never re-ask automatically after a "no".
const kNearbyLocationDenied =
    'That is okay. We went back to places near New Brunswick. '
    'You can turn location on any time in your phone settings.';

/// Location services switched off system-wide.
const kNearbyLocationOff =
    'Location is turned off on this phone, so we looked near New Brunswick '
    'instead.';

/// The fix itself failed (timeout / radio trouble) — fell back to town copy.
const kNearbyLocationUnavailable =
    'We could not get your location just now, so these are the saved '
    'New Brunswick places.';

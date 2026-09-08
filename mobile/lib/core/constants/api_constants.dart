class ApiConstants {
  // Auth & Sessions
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String sessions = '/auth/sessions/';

  // Discovery & Inventory
  static const String destinations = '/destinations/';
  static const String experiences = '/experiences/';
  static const String accommodations = '/accommodations/';
  static const String search = '/search/';
  static const String inventoryAvailability = '/inventory/availability/';
  static const String inventoryHolds = '/inventory/holds/';
  static const String inventoryHoldItinerary = '/inventory/holds/itinerary/';
  static const String inventoryHold = '/inventory/hold/';
  static String inventoryHoldDetail(String id) => '/inventory/holds/$id/';
  static String inventoryHoldRelease(String id) => '/inventory/holds/$id/release/';
  static String inventoryHoldExtend(String id) => '/inventory/holds/$id/extend/';

  // AI Travel Architect & Plan Versioning
  static const String parsePrompt = '/ai/parse-prompt/';
  static const String generateItinerary = '/ai/generate-itinerary/';
  static const String substituteRain = '/ai/substitute-rain/';
  static const String optimizeRoute = '/ai/optimize-route/';
  static String aiPlan(String id) => '/ai/plans/$id/';
  static String aiPlanCustomize(String id) => '/ai/plans/$id/customize/';
  static String aiPlanRegenerate(String id) => '/ai/plans/$id/regenerate/';
  static String aiPlanSubstituteRain(String id) => '/ai/plans/$id/substitute-rain/';
  static String aiPlanVersions(String id) => '/ai/plans/$id/versions/';
  static String aiPlanVersion(String id, int version) => '/ai/plans/$id/versions/$version/';
  static String aiPlanValidate(String id) => '/ai/plans/$id/validate/';
  static String aiPlanDiff(String id) => '/ai/plans/$id/diff/';
  static String aiPlanRevert(String id) => '/ai/plans/$id/revert/';
  static String aiPlanCandidates(String id) => '/ai/plans/$id/candidates/';

  // Live Trip Companion
  static const String companionChat = '/companion/chat/';

  // Bookings, Payments & Trips
  static const String bookings = '/bookings/';
  static const String digitalPass = '/bookings/pass/';
  static const String createPayment = '/payments/create-order/';
  static const String verifyPayment = '/payments/verify/';
  static const String trips = '/trips/';
  static String tripDetail(String reference) => '/trips/$reference/';
  static String tripPass(String reference) => '/bookings/pass/$reference/';
  static String tripContext(String reference) => '/trips/$reference/context/';

  // Location
  static const String locationUpdate = '/location/update/';
  static const String locationCurrent = '/location/current/';
  static String tripLocations(String reference) => '/location/trips/$reference/';

  // Maps & Routing
  static const String mapsRoute = '/maps/route/';
  static const String mapsNearby = '/maps/nearby/';
  static const String mapsGeocode = '/maps/geocode/';

  // Weather & Monsoon
  static const String weatherCurrent = '/weather/current/';
  static const String weatherForecast = '/weather/forecast/';
  static String weatherTrip(String reference) => '/weather/trip/$reference/';
  static const String weatherRisk = '/weather/risk/';

  // Safety & Emergency
  static const String safetyDirectory = '/safety/directory/';
  static const String safetySos = '/safety/sos/';
  static const String safetyShare = '/safety/share/';
  static String safetyShareRevoke(String token) => '/safety/share/$token/revoke/';
  static String safetySharedPublic(String token) => '/safety/shared/$token/';

  // Notifications & Proximity
  static const String notifications = '/notifications/';
  static const String notificationPreferences = '/notifications/preferences/';
  static const String deviceToken = '/notifications/device-token/';
  static const String proximityCheck = '/notifications/proximity-check/';
}

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
  static const String inventoryHold = '/inventory/hold/';

  // AI Travel Architect
  static const String parsePrompt = '/ai/parse-prompt/';
  static const String generateItinerary = '/ai/generate-itinerary/';
  static const String substituteRain = '/ai/substitute-rain/';
  static const String optimizeRoute = '/ai/optimize-route/';

  // Live Trip Companion
  static const String companionChat = '/companion/chat/';

  // Bookings & Payments
  static const String bookings = '/bookings/';
  static const String digitalPass = '/bookings/pass/';
  static const String createPayment = '/payments/create-order/';
  static const String verifyPayment = '/payments/verify/';
}

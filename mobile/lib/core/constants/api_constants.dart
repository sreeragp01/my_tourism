class ApiConstants {
  static const String baseUrl = 'https://api.keralink.org/api/v1';
  static const String devBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android Emulator loopback

  // Auth & Sessions
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

  // Live Trip Companion
  static const String companionChat = '/companion/chat/';

  // Bookings & Payments
  static const String bookings = '/bookings/';
  static const String createPayment = '/payments/create-order/';
  static const String verifyPayment = '/payments/verify/';
  static const String digitalPass = '/bookings/pass/';
}

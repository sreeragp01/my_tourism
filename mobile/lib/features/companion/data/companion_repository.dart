import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/companion_models.dart';

abstract class ICompanionRepository {
  Future<CompanionMessage> sendQuery({
    required String query,
    String destinationSlug = 'munnar',
    int tripDay = 2,
    String? bookingReference,
  });
}

class CompanionRepository implements ICompanionRepository {
  final ApiClient apiClient;

  CompanionRepository({required this.apiClient});

  @override
  Future<CompanionMessage> sendQuery({
    required String query,
    String destinationSlug = 'munnar',
    int tripDay = 2,
    String? bookingReference,
  }) async {
    final response = await apiClient.post(
      ApiConstants.companionChat,
      body: {
        'query': query,
        'destination_slug': destinationSlug,
        'trip_day': tripDay,
        if (bookingReference != null) 'booking_reference': bookingReference,
      },
    );
    return CompanionMessage.fromJson(response);
  }
}

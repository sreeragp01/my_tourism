import 'package:keralink_mobile/core/constants/api_constants.dart';
import 'package:keralink_mobile/core/network/api_client.dart';
import '../models/weather_models.dart';

abstract class IWeatherRepository {
  Future<WeatherReport> getCurrentWeather(String destinationSlug);
  Future<List<WeatherReport>> getForecast(String destinationSlug, {int days = 3});
  Future<ActivityWeatherValidation> validateActivity({
    required String activityType,
    required String destinationSlug,
    required int rainProbability,
  });
}

class WeatherRepository implements IWeatherRepository {
  final ApiClient apiClient;

  WeatherRepository({required this.apiClient});

  @override
  Future<WeatherReport> getCurrentWeather(String destinationSlug) async {
    final response = await apiClient.get(
      ApiConstants.weatherCurrent,
      queryParameters: {'destination': destinationSlug},
    );
    return WeatherReport.fromJson(response);
  }

  @override
  Future<List<WeatherReport>> getForecast(String destinationSlug, {int days = 3}) async {
    final response = await apiClient.get(
      ApiConstants.weatherForecast,
      queryParameters: {'destination': destinationSlug, 'days': days.toString()},
    );
    if (response is List) {
      return response.map((w) => WeatherReport.fromJson(w as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<ActivityWeatherValidation> validateActivity({
    required String activityType,
    required String destinationSlug,
    required int rainProbability,
  }) async {
    final response = await apiClient.post(
      ApiConstants.substituteRain,
      body: {
        'activity_type': activityType,
        'destination': destinationSlug,
        'rain_probability': rainProbability,
      },
    );
    return ActivityWeatherValidation.fromJson(response);
  }
}

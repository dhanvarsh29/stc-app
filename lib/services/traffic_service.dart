import 'package:http/http.dart' as http;
import '../models/traffic_models.dart';

class TrafficService {
  static const String _apiBaseUrl =
      'https://smart-traffic-congestion-msez.onrender.com';
  static const String _predictEndpoint = '/predict';

  /// Predict traffic congestion based on location and time
  /// Returns the congestion level: 'Low', 'Medium', or 'High'
  static Future<String> predictTraffic(Map<String, dynamic> data) async {
    try {
      final Uri url = Uri.parse('$_apiBaseUrl$_predictEndpoint');

      final request = TrafficPredictionRequest(
        latitude: data['latitude'] as double,
        longitude: data['longitude'] as double,
        hour: data['hour'] as int,
        dayType: data['day_type'] as int? ?? 0,
        vehicleCount: data['vehicle_count'] as int,
        avgSpeed: data['avg_speed'] as int,
      );

      // Retry logic for cold starts
      int retries = 3;
      Duration delay = const Duration(seconds: 2);
      
      while (retries > 0) {
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: request.toJsonString(),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'API request timed out. Please check your internet connection.',
              );
            },
          );

          if (response.statusCode == 200) {
            final responseData = TrafficPredictionResponse.fromJsonString(
              response.body,
            );
            return responseData.congestionLevel;
          } else if (response.statusCode == 503) {
            // Service unavailable - likely cold start, retry
            retries--;
            if (retries > 0) {
              await Future.delayed(delay);
              delay = Duration(seconds: delay.inSeconds * 2);
              continue;
            }
            throw ApiException(
              'API Service is starting up. Please try again in a moment.',
              statusCode: response.statusCode,
              responseBody: response.body,
            );
          } else {
            throw ApiException(
              'API Error: ${response.statusCode}',
              statusCode: response.statusCode,
              responseBody: response.body,
            );
          }
        } on TimeoutException {
          retries--;
          if (retries > 0) {
            await Future.delayed(delay);
            delay = Duration(seconds: delay.inSeconds * 2);
            continue;
          }
          rethrow;
        }
      }

      throw ApiException('Failed after multiple retries');
    } on TimeoutException catch (e) {
      throw ApiException(e.message);
    } catch (e) {
      throw ApiException('Error calling traffic prediction API: $e');
    }
  }

  /// Get message based on congestion level
  static String getMessageForCongestionLevel(String congestionLevel) {
    switch (congestionLevel.toLowerCase()) {
      case 'low':
        return 'Smooth Traffic';
      case 'medium':
        return 'Moderate Congestion';
      case 'high':
        return 'Heavy Traffic Ahead';
      default:
        return 'Traffic Status Unknown';
    }
  }

  /// Get color based on congestion level
  static String getCongestionLevelForDisplay(String apiResponse) {
    final normalized = apiResponse.toLowerCase();
    if (normalized.contains('low')) return 'LOW';
    if (normalized.contains('medium')) return 'MEDIUM';
    if (normalized.contains('high')) return 'HIGH';
    return 'UNKNOWN';
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  @override
  String toString() => 'ApiException: $message';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

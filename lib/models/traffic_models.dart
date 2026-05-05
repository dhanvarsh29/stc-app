import 'dart:convert';

class TrafficPredictionRequest {
  final double latitude;
  final double longitude;
  final int hour;
  final int dayType;
  final int vehicleCount;
  final int avgSpeed;

  TrafficPredictionRequest({
    required this.latitude,
    required this.longitude,
    required this.hour,
    required this.dayType,
    required this.vehicleCount,
    required this.avgSpeed,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'hour': hour,
      'day_type': dayType,
      'vehicle_count': vehicleCount,
      'avg_speed': avgSpeed,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

class TrafficPredictionResponse {
  final String congestionLevel;

  TrafficPredictionResponse({required this.congestionLevel});

  factory TrafficPredictionResponse.fromJson(Map<String, dynamic> json) {
    return TrafficPredictionResponse(
      congestionLevel: json['congestion_level'] as String? ?? 'Unknown',
    );
  }

  factory TrafficPredictionResponse.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return TrafficPredictionResponse.fromJson(json);
  }

  String getDisplayMessage() {
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
}

class LocationCoordinates {
  final String name;
  final double latitude;
  final double longitude;

  const LocationCoordinates({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

class LocationDatabase {
  static const Map<String, LocationCoordinates> locations = {
    'Adyar': LocationCoordinates(
      name: 'Adyar',
      latitude: 13.0067,
      longitude: 80.2570,
    ),
    'Besant Nagar': LocationCoordinates(
      name: 'Besant Nagar',
      latitude: 13.0003,
      longitude: 80.2667,
    ),
    'IIT Madras': LocationCoordinates(
      name: 'IIT Madras',
      latitude: 12.9916,
      longitude: 80.2337,
    ),
    'Thiruvanmiyur': LocationCoordinates(
      name: 'Thiruvanmiyur',
      latitude: 12.9830,
      longitude: 80.2594,
    ),
  };

  static LocationCoordinates? getCoordinates(String locationName) {
    return locations[locationName];
  }

  static List<String> getAllLocations() {
    return locations.keys.toList();
  }
}

class TrafficMetrics {
  final int vehicleCount;
  final int avgSpeed;
  final String timeType; // Peak, Normal, Night

  const TrafficMetrics({
    required this.vehicleCount,
    required this.avgSpeed,
    required this.timeType,
  });

  factory TrafficMetrics.fromTimeOfDay(int hour) {
    if ((hour >= 8 && hour < 10) || (hour >= 17 && hour < 20)) {
      // Peak hours
      return const TrafficMetrics(
        vehicleCount: 100,
        avgSpeed: 20,
        timeType: 'Peak',
      );
    } else if ((hour >= 7 && hour < 8) ||
        (hour >= 10 && hour < 12) ||
        (hour >= 16 && hour < 17)) {
      // Normal hours
      return const TrafficMetrics(
        vehicleCount: 60,
        avgSpeed: 35,
        timeType: 'Normal',
      );
    } else {
      // Night hours
      return const TrafficMetrics(
        vehicleCount: 30,
        avgSpeed: 50,
        timeType: 'Night',
      );
    }
  }
}

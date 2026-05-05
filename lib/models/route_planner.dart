import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'traffic_models.dart';

enum RouteType {
  shortest,
  recommended,
  leastCongested,
}

class RoutePlan {
  final RouteType type;
  final String title;
  final String routeText;
  final String distanceText;
  final String timeText;
  final List<LatLng> points;

  const RoutePlan({
    required this.type,
    required this.title,
    required this.routeText,
    required this.distanceText,
    required this.timeText,
    required this.points,
  });
}

class RoutePlanner {
  static List<RoutePlan> buildPlans({
    required String source,
    required String destination,
    required String trafficLevel,
    required int hour,
  }) {
    final sourceCoords = LocationDatabase.getCoordinates(source);
    final destinationCoords = LocationDatabase.getCoordinates(destination);

    if (sourceCoords == null || destinationCoords == null) {
      return const [];
    }

    final routeSeeds = _buildRouteSeeds(sourceCoords, destinationCoords);
    final baseDistance = _distanceKm(sourceCoords, destinationCoords);
    final metrics = TrafficMetrics.fromTimeOfDay(hour);

    final shortestPoints = routeSeeds.shortest;
    final recommendedPoints = trafficLevel.toLowerCase() == 'high'
        ? routeSeeds.leastCongested
        : routeSeeds.recommended;
    final leastCongestedPoints = routeSeeds.leastCongested;

    final shortestDistance = _formatDistance(baseDistance * 1.05);
    final recommendedDistance = _formatDistance(baseDistance * 1.12);
    final leastCongestedDistance = _formatDistance(baseDistance * 1.18);

    return [
      RoutePlan(
        type: RouteType.shortest,
        title: 'Shortest Route',
        routeText: _describeRoute(source, destination, shortestPoints),
        distanceText: shortestDistance,
        timeText: _estimateTimeText(baseDistance, metrics.avgSpeed, factor: 1.05),
        points: shortestPoints,
      ),
      RoutePlan(
        type: RouteType.recommended,
        title: trafficLevel.toLowerCase() == 'high'
            ? 'Best Route for Traffic'
            : 'Recommended Route',
        routeText: _describeRoute(source, destination, recommendedPoints),
        distanceText: recommendedDistance,
        timeText: _estimateTimeText(baseDistance, metrics.avgSpeed, factor: 1.12),
        points: recommendedPoints,
      ),
      RoutePlan(
        type: RouteType.leastCongested,
        title: 'Least Congested Route',
        routeText: _describeRoute(source, destination, leastCongestedPoints),
        distanceText: leastCongestedDistance,
        timeText: _estimateTimeText(baseDistance, metrics.avgSpeed, factor: 1.18),
        points: leastCongestedPoints,
      ),
    ];
  }

  static RoutePlan? pickNavigationRoute({
    required String source,
    required String destination,
    required String trafficLevel,
    required int hour,
  }) {
    final plans = buildPlans(
      source: source,
      destination: destination,
      trafficLevel: trafficLevel,
      hour: hour,
    );

    if (plans.isEmpty) {
      return null;
    }

    if (trafficLevel.toLowerCase() == 'high') {
      return plans.firstWhere((plan) => plan.type == RouteType.leastCongested);
    }

    return plans.firstWhere((plan) => plan.type == RouteType.recommended);
  }

  static String _describeRoute(
    String source,
    String destination,
    List<LatLng> points,
  ) {
    final waypointNames = <String>[];
    for (final point in points.skip(1).take(points.length - 2)) {
      final locationName = _nearestLocation(point);
      if (locationName != null && locationName != source && locationName != destination) {
        waypointNames.add(locationName);
      }
    }

    if (waypointNames.isEmpty) {
      return '$source → $destination';
    }

    return '$source → ${waypointNames.join(' → ')} → $destination';
  }

  static String _nearestLocation(LatLng point) {
    String? bestName;
    double bestDistance = double.infinity;

    for (final entry in LocationDatabase.locations.entries) {
      final distance = _distanceToLatLng(
        point,
        LatLng(entry.value.latitude, entry.value.longitude),
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestName = entry.key;
      }
    }

    return bestName ?? "";
  }

  static _RouteSeeds _buildRouteSeeds(
    LocationCoordinates source,
    LocationCoordinates destination,
  ) {
    final sourcePoint = LatLng(source.latitude, source.longitude);
    final destinationPoint = LatLng(destination.latitude, destination.longitude);

    final midpoint = LatLng(
      (source.latitude + destination.latitude) / 2,
      (source.longitude + destination.longitude) / 2,
    );

    final offsetNorth = LatLng(midpoint.latitude + 0.0035, midpoint.longitude + 0.0020);
    final offsetSouth = LatLng(midpoint.latitude - 0.0030, midpoint.longitude - 0.0025);
    final offsetEast = LatLng(midpoint.latitude + 0.0015, midpoint.longitude + 0.0040);
    final offsetWest = LatLng(midpoint.latitude - 0.0022, midpoint.longitude + 0.0032);

    final shortest = [
      sourcePoint,
      offsetNorth,
      destinationPoint,
    ];

    final recommended = [
      sourcePoint,
      offsetWest,
      offsetEast,
      destinationPoint,
    ];

    final leastCongested = [
      sourcePoint,
      offsetSouth,
      offsetWest,
      destinationPoint,
    ];

    return _RouteSeeds(
      shortest: shortest,
      recommended: recommended,
      leastCongested: leastCongested,
    );
  }

  static String _estimateTimeText(double distanceKm, int avgSpeed, {double factor = 1.0}) {
    final adjustedSpeed = max(avgSpeed, 10);
    final minutes = ((distanceKm * factor) / adjustedSpeed * 60).round();
    return '$minutes min';
  }

  static String _formatDistance(double distanceKm) {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  static double _distanceKm(LocationCoordinates a, LocationCoordinates b) {
    return _distanceToLatLng(
      LatLng(a.latitude, a.longitude),
      LatLng(b.latitude, b.longitude),
    );
  }

  static double _distanceToLatLng(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final haversine =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(haversine), sqrt(1 - haversine));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

class _RouteSeeds {
  final List<LatLng> shortest;
  final List<LatLng> recommended;
  final List<LatLng> leastCongested;

  const _RouteSeeds({
    required this.shortest,
    required this.recommended,
    required this.leastCongested,
  });
}

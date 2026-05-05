import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/route_planner.dart';
import '../models/traffic_models.dart';

class RouteService {
  static const String _directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  static const String _mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'AIzaSyBsN8w3cSVfirnfLgTOImiRkY1-OGMLimo',
  );

  static Future<List<RoutePlan>> getRoutePlans({
    required String source,
    required String destination,
    required String trafficLevel,
    required int hour,
  }) async {
    final sourceCoords = LocationDatabase.getCoordinates(source);
    final destinationCoords = LocationDatabase.getCoordinates(destination);

    if (sourceCoords == null || destinationCoords == null || _mapsApiKey.isEmpty) {
      return const [];
    }

    try {
      final uri = Uri.parse(_directionsBaseUrl).replace(
        queryParameters: {
          'origin': '${sourceCoords.latitude},${sourceCoords.longitude}',
          'destination': '${destinationCoords.latitude},${destinationCoords.longitude}',
          'mode': 'driving',
          'alternatives': 'true',
          'key': _mapsApiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 20));
      debugPrint('Directions API response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('Response body: ${response.body.substring(0, 500)}...');
        return const [];
      }

      final jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (jsonMap['status'] as String?) ?? '';
      debugPrint('API status: $status, routes count: ${(jsonMap['routes'] as List?)?.length ?? 0}');
      if (status != 'OK') {
        return const [];
      }

      final routes = (jsonMap['routes'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (routes.isEmpty) {
        return const [];
      }

      final parsedRoutes = <_ParsedRoute>[];
      var routeIndex = 0;
      for (final route in routes) {
        routeIndex++;
        final legs = (route['legs'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        if (legs.isEmpty) {
          debugPrint('Route $routeIndex has no legs.');
          continue;
        }

        final points = _decodeRoutePoints(route, legs);
        if (points.length < 2) {
          debugPrint('Route $routeIndex has insufficient decoded points: ${points.length}');
          continue;
        }

        // Debug visibility for validating that route is road-detailed.
        debugPrint('Total points (route $routeIndex): ${points.length} (legs: ${legs.length}, steps total: ${legs.map((l) => (l['steps'] as List?)?.length ?? 0).reduce((a, b) => a + b)})');

        final primaryLeg = legs.first;
        final distance = (primaryLeg['distance'] as Map<String, dynamic>? ?? {});
        final duration = (primaryLeg['duration'] as Map<String, dynamic>? ?? {});
        final durationInTraffic =
            (primaryLeg['duration_in_traffic'] as Map<String, dynamic>? ?? duration);

        final distanceValue = (distance['value'] as num?)?.toInt() ?? 1 << 30;
        final durationValue = (durationInTraffic['value'] as num?)?.toInt() ??
            (duration['value'] as num?)?.toInt() ??
            1 << 30;

        parsedRoutes.add(
          _ParsedRoute(
            summary: (route['summary'] as String?) ?? '',
            points: points,
            distanceText: (distance['text'] as String?) ?? '-',
            timeText: (durationInTraffic['text'] as String?) ??
                (duration['text'] as String?) ??
                '-',
            distanceValue: distanceValue,
            durationValue: durationValue,
          ),
        );
      }

      if (parsedRoutes.isEmpty) {
        debugPrint('Directions parsedRoutes is empty. status=OK routes=${routes.length}');
        return const [];
      }

      return _buildPlansFromParsedRoutes(
        parsedRoutes: parsedRoutes,
        source: source,
        destination: destination,
        trafficLevel: trafficLevel,
      );
    } catch (e) {
      print('Directions exception: $e');
      return const [];
    }
  }

  static Future<RoutePlan?> getPreferredRoute({
    required String source,
    required String destination,
    required String trafficLevel,
    required int hour,
  }) async {
    final plans = await getRoutePlans(
      source: source,
      destination: destination,
      trafficLevel: trafficLevel,
      hour: hour,
    );

    if (plans.isEmpty) {
      return null;
    }

    if (trafficLevel.toLowerCase() == 'high') {
      return plans.firstWhere(
        (plan) => plan.type == RouteType.leastCongested,
        orElse: () => plans.first,
      );
    }

    return plans.firstWhere(
      (plan) => plan.type == RouteType.recommended,
      orElse: () => plans.first,
    );
  }

  static List<RoutePlan> _buildPlansFromParsedRoutes({
    required List<_ParsedRoute> parsedRoutes,
    required String source,
    required String destination,
    required String trafficLevel,
  }) {
    final sortedByDistance = [...parsedRoutes]
      ..sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
    final shortest = sortedByDistance.first;

    final sortedByDuration = [...parsedRoutes]
      ..sort((a, b) => a.durationValue.compareTo(b.durationValue));
    final leastCongested = sortedByDuration.first;

    final recommended = trafficLevel.toLowerCase() == 'high'
        ? leastCongested
        : shortest;

    return <RoutePlan>[
      _toPlan(
        parsed: shortest,
        type: RouteType.shortest,
        title: 'Shortest Route',
        source: source,
        destination: destination,
      ),
      _toPlan(
        parsed: recommended,
        type: RouteType.recommended,
        title: trafficLevel.toLowerCase() == 'high'
            ? 'Best Route for Traffic'
            : 'Recommended Route',
        source: source,
        destination: destination,
      ),
      _toPlan(
        parsed: leastCongested,
        type: RouteType.leastCongested,
        title: 'Least Congested Route',
        source: source,
        destination: destination,
      ),
    ];
  }

  static RoutePlan _toPlan({
    required _ParsedRoute parsed,
    required RouteType type,
    required String title,
    required String source,
    required String destination,
  }) {
    final summary = parsed.summary.trim();
    final routeText = summary.isEmpty
        ? '$source -> $destination'
        : '$source -> $summary -> $destination';

    return RoutePlan(
      type: type,
      title: title,
      routeText: routeText,
      distanceText: parsed.distanceText,
      timeText: parsed.timeText,
      points: parsed.points,
    );
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final decoded = PolylinePoints().decodePolyline(encoded);
    return decoded
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
  }

  static List<LatLng> _decodeRoutePoints(
    Map<String, dynamic> route,
    List<Map<String, dynamic>> legs,
  ) {
    final routePoints = <LatLng>[];

    for (final leg in legs) {
      final steps = (leg['steps'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final step in steps) {
        final encoded =
            ((step['polyline'] as Map<String, dynamic>?)?['points'] as String?) ??
                '';
        if (encoded.isEmpty) {
          continue;
        }

        final decoded = _decodePolyline(encoded);
        if (decoded.isEmpty) {
          continue;
        }

        // Append decoded points, avoid duplicates
        for (var point in decoded) {
          if (routePoints.isEmpty || routePoints.last.latitude != point.latitude || routePoints.last.longitude != point.longitude) {
            routePoints.add(point);
          }
        }
        debugPrint('POINT COUNT: ${routePoints.length} after step');
      }
    }

    if (routePoints.length < 2) {
      final summary = (route['summary'] as String?) ?? 'unknown';
      debugPrint('Decoded route has <2 points. summary=$summary');
      return const [];
    }

    return routePoints;
  }
}

class _ParsedRoute {
  final String summary;
  final List<LatLng> points;
  final String distanceText;
  final String timeText;
  final int distanceValue;
  final int durationValue;

  const _ParsedRoute({
    required this.summary,
    required this.points,
    required this.distanceText,
    required this.timeText,
    required this.distanceValue,
    required this.durationValue,
  });
}

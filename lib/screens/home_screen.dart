import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/traffic_models.dart';
import '../services/route_service.dart';
import '../services/traffic_service.dart';
import '../widgets/traffic_icon.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? source;
  String? destination;
  TimeOfDay? travelTime;
  bool isLoading = false;
  String? errorMessage;
  final TextEditingController _timeController = TextEditingController();
  late GoogleMapController mapController;
  bool isMapReady = false;
  LatLngBounds? pendingBounds;
  int _routeRequestId = 0;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  final List<String> locations = LocationDatabase.getAllLocations();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _initializeMap() {
    markers = {};
    polylines = {};
  }

  Future<void> _updateMapMarkers() async {
    final requestId = ++_routeRequestId;

    markers.clear();
    polylines.clear();

    if (source != null) {
      final sourceCoords = LocationDatabase.getCoordinates(source!);
      if (sourceCoords != null) {
        markers.add(
          Marker(
            markerId: MarkerId('source'),
            position: LatLng(sourceCoords.latitude, sourceCoords.longitude),
            infoWindow: InfoWindow(title: source),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }

    if (destination != null) {
      final destCoords = LocationDatabase.getCoordinates(destination!);
      if (destCoords != null) {
        markers.add(
          Marker(
            markerId: MarkerId('destination'),
            position: LatLng(destCoords.latitude, destCoords.longitude),
            infoWindow: InfoWindow(title: destination),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    // Draw multiple route paths between source and destination
    if (source != null && destination != null) {
      final previewTrafficLevel = _trafficLevelForPreview();
      final hour = travelTime?.hour ?? TimeOfDay.now().hour;
      final plans = await RouteService.getRoutePlans(
        source: source!,
        destination: destination!,
        trafficLevel: previewTrafficLevel,
        hour: hour,
      );

      if (!mounted || requestId != _routeRequestId) {
        return;
      }

      if (plans.length >= 1 && plans[0].points.isNotEmpty) {
        // Shortest - Yellow
        polylines.add(
          Polyline(
            polylineId: const PolylineId('shortest'),
            points: plans[0].points,
            color: Colors.blue,
            width: 6,
            geodesic: false,
          ),
        );
      }
      if (plans.length >= 2 && plans[1].points.isNotEmpty) {
        // Recommended - Orange
        polylines.add(
          Polyline(
            polylineId: const PolylineId('recommended'),
            points: plans[1].points,
            color: Colors.orange,
            width: 5,
            geodesic: false,
          ),
        );
      }
      if (plans.length >= 3 && plans[2].points.isNotEmpty) {
        // Least Congested - Purple
        polylines.add(
          Polyline(
            polylineId: const PolylineId('leastCongested'),
            points: plans[2].points,
            color: Colors.purple,
            width: 5,
            geodesic: false,
          ),
        );
      }

      // Bounds from all plans
      final allPoints = plans.expand((p) => p.points).toList();
      if (allPoints.isNotEmpty) {
        final bounds = _calculateBoundsFromPoints(allPoints);
        _animateCameraToBounds(bounds);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }



  LatLngBounds _calculateBoundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _animateCameraToBounds(LatLngBounds bounds) async {
    if (!isMapReady) {
      pendingBounds = bounds;
      return;
    }

    try {
      await mapController.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    } catch (e) {
      // Fallback for occasional bounds timing issues on first map frame.
      await mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
              (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
            ),
            zoom: 12,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TrafficIcon(size: 40),
                const SizedBox(width: 12),
                Text(
                  'Smart Traffic Predictor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Google Map
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(13.0065, 80.2366),
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                      isMapReady = true;
                      if (pendingBounds != null) {
                        _animateCameraToBounds(pendingBounds!);
                        pendingBounds = null;
                      }
                    },
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Input Form Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'Source Location',
                      value: source,
                      icon: Icons.location_on,
                      onChanged: (val) {
                        source = val;
                        _updateMapMarkers();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'Destination Location',
                      value: destination,
                      icon: Icons.flag,
                      onChanged: (val) {
                        destination = val;
                        _updateMapMarkers();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTimePicker(context),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          border: Border.all(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        width: double.infinity,
                        child: isLoading
                            ? ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  backgroundColor: Colors.blueAccent,
                                  disabledBackgroundColor: Colors.blueAccent,
                                ),
                                child: const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                icon: const Icon(Icons.traffic),
                                label: const Text('Predict Traffic'),
                                onPressed: () => _handlePredictTraffic(context),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shadowColor:
                                      Colors.blueAccent.withOpacity(0.4),
                                  elevation: 12,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: locations
          .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: travelTime ?? TimeOfDay.now(),
        );
        if (picked != null) {
          setState(() {
            travelTime = picked;
            _timeController.text = picked.format(context);
          });
          if (source != null && destination != null) {
            _updateMapMarkers();
          }
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Travel Time',
            prefixIcon: const Icon(
              Icons.access_time,
              color: Colors.greenAccent,
            ),
            hintText: travelTime != null
                ? travelTime!.format(context)
                : 'Select Time',
          ),
          controller: _timeController,
        ),
      ),
    );
  }

  Future<void> _handlePredictTraffic(BuildContext context) async {
    // Validate inputs
    if (source == null || destination == null || travelTime == null) {
      setState(() {
        errorMessage = 'Please select all fields (source, destination, and time)';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get coordinates
      final sourceCoords = LocationDatabase.getCoordinates(source!);
      final destCoords = LocationDatabase.getCoordinates(destination!);

      if (sourceCoords == null || destCoords == null) {
        throw Exception('Invalid location selected');
      }

      // Generate traffic metrics based on time
      final metrics = TrafficMetrics.fromTimeOfDay(travelTime!.hour);

      // Prepare request data
      final requestData = {
        'latitude': (sourceCoords.latitude + destCoords.latitude) / 2,
        'longitude': (sourceCoords.longitude + destCoords.longitude) / 2,
        'hour': travelTime!.hour,
        'day_type': 0,
        'vehicle_count': metrics.vehicleCount,
        'avg_speed': metrics.avgSpeed,
      };

      // Call API
      final congestionLevel = await TrafficService.predictTraffic(requestData);
      final displayLevel =
          TrafficService.getCongestionLevelForDisplay(congestionLevel);
      final message =
          TrafficService.getMessageForCongestionLevel(congestionLevel);

      setState(() => isLoading = false);

      if (!mounted) return;

      // Navigate to result screen
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              FadeTransition(
            opacity: animation,
            child: ResultScreen(
              trafficLevel: displayLevel,
              message: message,
              estimatedTime: _estimateTravelTime(),
              source: source!,
              destination: destination!,
              hour: travelTime!.hour,
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  String _estimateTravelTime() {
    if (source == null || destination == null || travelTime == null) {
      return '30 min';
    }

    // Simple calculation based on metrics
    final metrics = TrafficMetrics.fromTimeOfDay(travelTime!.hour);
    final distance = 10.0; // km (example)
    final estimatedMinutes = (distance / (metrics.avgSpeed / 60)).toInt();

    return '$estimatedMinutes min';
  }

  String _trafficLevelForPreview() {
    if (travelTime == null) {
      return 'medium';
    }

    final hour = travelTime!.hour;
    if ((hour >= 8 && hour < 10) || (hour >= 17 && hour < 20)) {
      return 'high';
    }
    if ((hour >= 7 && hour < 8) ||
        (hour >= 10 && hour < 12) ||
        (hour >= 16 && hour < 17)) {
      return 'medium';
    }
    return 'low';
  }
}

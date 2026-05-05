import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_planner.dart';

class NavigationScreen extends StatefulWidget {
  final String source;
  final String destination;
  final RoutePlan routePlan;

  const NavigationScreen({
    Key? key,
    required this.source,
    required this.destination,
    required this.routePlan,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? mapController;
  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _buildMapData();
  }

  void _buildMapData() {
    if (widget.routePlan.points.isEmpty) {
      return;
    }

    final sourcePoint = widget.routePlan.points.first;
    final destinationPoint = widget.routePlan.points.last;

    markers.add(
      Marker(
        markerId: const MarkerId('source'),
        position: sourcePoint,
        infoWindow: InfoWindow(title: widget.source),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationPoint,
        infoWindow: InfoWindow(title: widget.destination),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    polylines.add(
      Polyline(
        polylineId: const PolylineId('navigation_route'),
        points: widget.routePlan.points,
        color: Colors.yellow,
        width: 6,
        geodesic: true,
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.routePlan.points.isNotEmpty
        ? LatLng(
            (widget.routePlan.points.first.latitude + widget.routePlan.points.last.latitude) / 2,
            (widget.routePlan.points.first.longitude + widget.routePlan.points.last.longitude) / 2,
          )
        : const LatLng(13.0065, 80.2366);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: center,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      mapController = controller;
                      if (widget.routePlan.points.length > 1) {
                        Future.microtask(() {
                          try {
                            mapController?.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                _boundsFromPoints(widget.routePlan.points),
                                80,
                              ),
                            );
                          } catch (_) {
                            // Fallback: keep the initial center if bounds animation is not ready.
                          }
                        });
                      }
                    },
                    markers: markers,
                    polylines: polylines,
                    zoomControlsEnabled: false,
                    myLocationEnabled: false,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.routePlan.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.routePlan.routeText,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.directions, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Text(widget.routePlan.distanceText, style: const TextStyle(color: Colors.white)),
                          const SizedBox(width: 20),
                          const Icon(Icons.access_time, color: Colors.greenAccent),
                          const SizedBox(width: 8),
                          Text(widget.routePlan.timeText, style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop'),
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

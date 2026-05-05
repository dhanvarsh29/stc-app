import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_planner.dart';
import '../services/route_service.dart';
import 'navigation_screen.dart';

class RouteSuggestionScreen extends StatefulWidget {
  final String source;
  final String destination;
  final String trafficLevel;
  final int hour;

  const RouteSuggestionScreen({
    Key? key,
    required this.source,
    required this.destination,
    required this.trafficLevel,
    required this.hour,
  }) : super(key: key);

  @override
  State<RouteSuggestionScreen> createState() => _RouteSuggestionScreenState();
}

class _RouteSuggestionScreenState extends State<RouteSuggestionScreen> {
  bool isLoading = true;
  String? loadError;
  List<RoutePlan> plans = [];
  RoutePlan? selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final routePlans = await RouteService.getRoutePlans(
        source: widget.source,
        destination: widget.destination,
        trafficLevel: widget.trafficLevel,
        hour: widget.hour,
      );

      if (!mounted) {
        return;
      }

      if (routePlans.isEmpty) {
        setState(() {
          plans = [];
          selectedPlan = null;
          isLoading = false;
          loadError = 'No routes available for this pair of locations.';
        });
        return;
      }

      setState(() {
        plans = routePlans;
        selectedPlan = widget.trafficLevel.toLowerCase() == 'high'
            ? routePlans.firstWhere(
                (plan) => plan.type == RouteType.leastCongested,
                orElse: () => routePlans.first,
              )
            : routePlans.firstWhere(
                (plan) => plan.type == RouteType.recommended,
                orElse: () => routePlans.first,
              );
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        isLoading = false;
        loadError = 'Failed to fetch road routes. Please retry.';
      });
    }
  }

  Color _accentForPlan(RoutePlan plan) {
    switch (plan.type) {
      case RouteType.shortest:
        return Colors.blueAccent;
      case RouteType.recommended:
        return Colors.greenAccent;
      case RouteType.leastCongested:
        return Colors.amberAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = selectedPlan;
    final sourcePoint =
        activePlan != null && activePlan.points.isNotEmpty
            ? activePlan.points.first
            : const LatLng(13.0067, 80.2570);
    final destinationPoint =
        activePlan != null && activePlan.points.isNotEmpty
            ? activePlan.points.last
            : const LatLng(12.9916, 80.2337);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Suggestions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 220,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (sourcePoint.latitude + destinationPoint.latitude) / 2,
                        (sourcePoint.longitude + destinationPoint.longitude) / 2,
                      ),
                      zoom: 12,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('source'),
                        position: sourcePoint,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                      Marker(
                        markerId: const MarkerId('destination'),
                        position: destinationPoint,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed,
                        ),
                      ),
                    },
                    polylines: {
                      if (activePlan != null && activePlan.points.isNotEmpty)
                        Polyline(
                          polylineId: const PolylineId('selected_route'),
                          points: activePlan.points,
                          color: Colors.yellow,
                          width: 6,
                          geodesic: true,
                        ),
                    },
                    zoomControlsEnabled: false,
                    myLocationEnabled: false,
                  ),
                ),
              ),
            ),
            if (isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (loadError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadPlans,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final isSelected = activePlan != null &&
                        plan.type == activePlan.type &&
                        plan.routeText == activePlan.routeText;
                    final accent = _accentForPlan(plan);

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => selectedPlan = plan),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        elevation: isSelected ? 14 : 6,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.route,
                                    color: accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      plan.title,
                                      style: TextStyle(
                                        color: accent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                plan.routeText,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions,
                                    color: Colors.blueAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    plan.distanceText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 18),
                                  const Icon(
                                    Icons.access_time,
                                    color: Colors.greenAccent,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    plan.timeText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation'),
                onPressed: selectedPlan == null || selectedPlan!.points.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 500),
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    FadeTransition(
                              opacity: animation,
                              child: NavigationScreen(
                                source: widget.source,
                                destination: widget.destination,
                                routePlan: selectedPlan!,
                              ),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

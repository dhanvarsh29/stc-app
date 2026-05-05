import 'package:flutter/material.dart';


import 'route_suggestion_screen.dart';

class ResultScreen extends StatelessWidget {
  final String trafficLevel; // 'LOW', 'MEDIUM', 'HIGH'
  final String message;
  final String estimatedTime;
  final String source;
  final String destination;
  final int hour;

  const ResultScreen({
    Key? key,
    required this.trafficLevel,
    required this.message,
    required this.estimatedTime,
    required this.source,
    required this.destination,
    required this.hour,
  }) : super(key: key);

  Color getLevelColor() {
    switch (trafficLevel) {
      case 'LOW':
        return Colors.greenAccent;
      case 'MEDIUM':
        return Colors.amberAccent;
      case 'HIGH':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  IconData getLevelIcon() {
    switch (trafficLevel) {
      case 'LOW':
        return Icons.check_circle;
      case 'MEDIUM':
        return Icons.warning_amber_rounded;
      case 'HIGH':
        return Icons.error;
      default:
        return Icons.traffic;
    }
  }

  String _getRecommendation() {
    switch (trafficLevel) {
      case 'LOW':
        return 'Safe to travel! Roads are clear.';
      case 'MEDIUM':
        return 'Consider alternative routes if available.';
      case 'HIGH':
        return 'Recommend taking alternate route to avoid delays.';
      default:
        return 'Check traffic conditions.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Traffic Prediction Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.greenAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                source,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.flag,
                            color: Colors.redAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                destination,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: getLevelColor().withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: getLevelColor(), width: 2),
              ),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Icon(getLevelIcon(), color: getLevelColor(), size: 60),
                    const SizedBox(height: 16),
                    Text(
                      trafficLevel,
                      style: TextStyle(
                        color: getLevelColor(),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Est. Time: $estimatedTime',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: getLevelColor().withOpacity(0.1),
                border: Border.all(color: getLevelColor()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: getLevelColor()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getRecommendation(),
                      style: TextStyle(
                        color: getLevelColor(),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.route),
              label: const Text('View Route Suggestions'),
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: RouteSuggestionScreen(
                        source: source,
                        destination: destination,
                        trafficLevel: trafficLevel,
                        hour: hour,
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: getLevelColor(),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                elevation: 8,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

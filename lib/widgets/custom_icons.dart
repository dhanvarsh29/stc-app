import 'package:flutter/material.dart';

class LocationIcon extends StatelessWidget {
  final double size;
  const LocationIcon({Key? key, this.size = 28}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.location_on, color: Colors.blueAccent, size: size);
  }
}

class TimeIcon extends StatelessWidget {
  final double size;
  const TimeIcon({Key? key, this.size = 28}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.access_time, color: Colors.greenAccent, size: size);
  }
}

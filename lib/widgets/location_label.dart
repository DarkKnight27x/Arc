import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../data/location_service.dart';
import '../theme_ctrl.dart';

class LocationLabel extends StatefulWidget {
  const LocationLabel({super.key, required this.c});

  final ArcColors c;

  @override
  State<LocationLabel> createState() => _LocationLabelState();
}

class _LocationLabelState extends State<LocationLabel> {
  String _location = 'LOCATING...';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await LocationService.displayLocation();
    debugPrint('[LocationLabel] displaying location: $location');
    if (!mounted) return;
    setState(() => _location = location);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _location,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: widget.c.faint,
      ),
    );
  }
}

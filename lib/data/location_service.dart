import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._();

  static Future<String>? _displayLocation;

  static Future<String> displayLocation() {
    debugPrint(
      '[LocationService] displayLocation: '
      '${_displayLocation == null ? 'requesting position' : 'reusing in-memory result'}',
    );
    return _displayLocation ??= _loadDisplayLocation();
  }

  static Future<String> _loadDisplayLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[LocationService] service enabled: $serviceEnabled');
      if (!serviceEnabled) {
        debugPrint('[LocationService] final city/locality: LOCATION OFF');
        return 'LOCATION OFF';
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[LocationService] permission status: $permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[LocationService] permission after request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] final city/locality: LOCATION OFF');
        return 'LOCATION OFF';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      debugPrint(
        '[LocationService] position: latitude=${position.latitude}, '
        'longitude=${position.longitude}, timestamp=${position.timestamp}',
      );
      final places = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      debugPrint('[LocationService] reverse-geocoded placemarks: $places');
      if (places.isEmpty) {
        debugPrint('[LocationService] final city/locality: LOCATION');
        return 'LOCATION';
      }

      final place = places.first;
      for (final candidate in <String?>[
        place.locality,
        place.subAdministrativeArea,
      ]) {
        final displayName = candidate?.trim();
        if (displayName != null && displayName.isNotEmpty) {
          final result = displayName.toUpperCase();
          debugPrint('[LocationService] final city/locality: $result');
          return result;
        }
      }
      debugPrint('[LocationService] final city/locality: LOCATION');
      return 'LOCATION';
    } catch (error, stackTrace) {
      debugPrint('[LocationService] error: $error');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('[LocationService] final city/locality: LOCATION');
      return 'LOCATION';
    }
  }
}

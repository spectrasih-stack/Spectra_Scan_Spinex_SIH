import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Structured forensic location data with verified human-readable place name
class ForensicLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String locationName;
  final String fullAddress;
  final bool isLiveGps;
  final DateTime timestamp;

  const ForensicLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.locationName,
    required this.fullAddress,
    this.isLiveGps = true,
    required this.timestamp,
  });

  /// Deterministic fallback if GPS is not yet acquired
  factory ForensicLocation.fallback() {
    return ForensicLocation(
      latitude: 6.9271,
      longitude: 79.8612,
      accuracyMeters: 5.0,
      locationName: 'Metropolitan District, Regional Field Sector',
      fullAddress: 'Metropolitan Sector • Forensic Field Division',
      isLiveGps: false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMeters': accuracyMeters,
        'locationName': locationName,
        'fullAddress': fullAddress,
        'isLiveGps': isLiveGps,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ForensicLocation.fromJson(Map<String, dynamic> json) => ForensicLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: (json['accuracyMeters'] as num).toDouble(),
        locationName: json['locationName'] as String,
        fullAddress: json['fullAddress'] as String,
        isLiveGps: json['isLiveGps'] as bool? ?? false,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Centralized Location Service querying real device GPS hardware
/// and translating coordinates into human-readable place names.
class LocationService {
  static const String _prefKey = 'spectra_cached_location';
  static ForensicLocation? _currentCached;

  /// Returns the current GPS location with reverse geocoded place name.
  /// Falls back smoothly to last known cache if hardware is temporarily cold.
  static Future<ForensicLocation> getCurrentLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && _currentCached != null) {
      return _currentCached!;
    }

    // Try loading cached first for instant baseline
    final cached = await getLastCachedLocation();
    if (cached != null && !forceRefresh) {
      _currentCached = cached;
    }

    try {
      // 1. Check if location services are enabled on phone
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location service disabled on device');
        return _currentCached ?? ForensicLocation.fallback();
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user');
          return _currentCached ?? ForensicLocation.fallback();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions permanently denied');
        return _currentCached ?? ForensicLocation.fallback();
      }

      // 3. Query native GPS position with 8-second timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (e) {
        debugPrint('[LocationService] High accuracy position timed out, trying last known: $e');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return _currentCached ?? ForensicLocation.fallback();
      }

      // 4. Reverse Geocode coordinates to human-readable location name
      final placeDetails = await _reverseGeocode(position.latitude, position.longitude);

      final result = ForensicLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        locationName: placeDetails['name'] ?? 'Field Operations Sector',
        fullAddress: placeDetails['full'] ?? placeDetails['name'] ?? 'Field Operations Sector',
        isLiveGps: true,
        timestamp: DateTime.now(),
      );

      _currentCached = result;
      await _cacheLocation(result);
      return result;
    } catch (e) {
      debugPrint('[LocationService] Unexpected error querying location: $e');
      return _currentCached ?? ForensicLocation.fallback();
    }
  }

  /// Converts coordinates into a clean forensic location name
  static Future<Map<String, String>> _reverseGeocode(double lat, double lng) async {
    // Primary: Native Android Geocoder via geocoding package
    try {
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 5));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final nameParts = <String>[];

        // Format neighborhood / street
        final locality = p.locality?.trim();
        final subLocality = p.subLocality?.trim();
        final thoroughfare = p.thoroughfare?.trim();
        final subAdmin = p.subAdministrativeArea?.trim();
        final admin = p.administrativeArea?.trim();
        final country = p.country?.trim();

        if (subLocality != null && subLocality.isNotEmpty) {
          nameParts.add(subLocality);
        } else if (thoroughfare != null && thoroughfare.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(thoroughfare)) {
          nameParts.add(thoroughfare);
        }

        if (locality != null && locality.isNotEmpty && !nameParts.contains(locality)) {
          nameParts.add(locality);
        } else if (subAdmin != null && subAdmin.isNotEmpty && !nameParts.contains(subAdmin)) {
          nameParts.add(subAdmin);
        }

        if (admin != null && admin.isNotEmpty && !nameParts.contains(admin)) {
          nameParts.add(admin);
        } else if (country != null && country.isNotEmpty && !nameParts.contains(country)) {
          nameParts.add(country);
        }

        final locationName = nameParts.isNotEmpty ? nameParts.join(', ') : 'Metropolitan Field Precinct';

        // Full detailed string
        final fullParts = [
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (subLocality != null && subLocality.isNotEmpty) subLocality,
          if (locality != null && locality.isNotEmpty) locality,
          if (admin != null && admin.isNotEmpty) admin,
          if (country != null && country.isNotEmpty) country,
        ];

        return {
          'name': locationName,
          'full': fullParts.isNotEmpty ? fullParts.join(', ') : locationName,
        };
      }
    } catch (e) {
      debugPrint('[LocationService] Native reverse geocoding error: $e. Falling back to HTTP...');
    }

    // Secondary Fallback: Lightweight OpenStreetMap reverse geocode
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);
      final request = await client.getUrl(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'),
      );
      request.headers.set('User-Agent', 'SpectraForensicApp/1.0');
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final address = json['address'] as Map<String, dynamic>?;

        if (address != null) {
          final sub = address['suburb'] ?? address['neighbourhood'] ?? address['road'];
          final city = address['city'] ?? address['town'] ?? address['municipality'] ?? address['county'];
          final state = address['state'] ?? address['country'];

          final parts = <String>[];
          if (sub != null && sub.toString().isNotEmpty) parts.add(sub.toString());
          if (city != null && city.toString().isNotEmpty) parts.add(city.toString());
          if (state != null && state.toString().isNotEmpty) parts.add(state.toString());

          final displayName = parts.isNotEmpty ? parts.join(', ') : (json['display_name'] ?? 'Field Location');
          return {
            'name': displayName,
            'full': json['display_name']?.toString() ?? displayName,
          };
        }
      }
    } catch (e) {
      debugPrint('[LocationService] HTTP reverse geocoding error: $e');
    }

    // Coarse coordinate fallback formatted nicely
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final coordStr = '${lat.abs().toStringAsFixed(3)}° $latDir, ${lng.abs().toStringAsFixed(3)}° $lngDir';
    return {
      'name': 'Field Precinct ($coordStr)',
      'full': 'Field Operations Sector • $coordStr',
    };
  }

  /// Retrieve cached location from SharedPreferences
  static Future<ForensicLocation?> getLastCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null && str.isNotEmpty) {
        final json = jsonDecode(str) as Map<String, dynamic>;
        return ForensicLocation.fromJson(json);
      }
    } catch (e) {
      debugPrint('[LocationService] Error reading cached location: $e');
    }
    return null;
  }

  /// Save location to SharedPreferences
  static Future<void> _cacheLocation(ForensicLocation loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, jsonEncode(loc.toJson()));
    } catch (e) {
      debugPrint('[LocationService] Error caching location: $e');
    }
  }
}

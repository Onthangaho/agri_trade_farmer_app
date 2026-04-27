// lib/core/services/location_service.dart
/// Location service for permission handling, GPS capture, and reverse geocoding.

import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  LocationService();

  Future<bool> showExplanationDialog(BuildContext context) async {
    final bool? allowed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location access needed'),
          content: const Text(
            'AgriTrade uses your GPS to tag your farm location. This helps buyers find farms near them.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    );

    return allowed ?? false;
  }

  Future<bool> checkLocationServicesEnabled(BuildContext context) async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (enabled) {
      return true;
    }

    final bool? openSettings = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable location services'),
          content: const Text(
            'Location services are off. Please enable GPS to tag your farm.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );

    if (openSettings == true) {
      await Geolocator.openLocationSettings();
    }

    return false;
  }

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<void> handlePermanentlyDenied(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Location permission is permanently denied. Open app settings to allow access.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  Future<Position?> getCurrentPosition(BuildContext context) async {
    final bool accepted = await showExplanationDialog(context);
    if (!accepted) {
      return null;
    }

    final bool enabled = await checkLocationServicesEnabled(context);
    if (!enabled) {
      return null;
    }

    final PermissionStatus permissionStatus = await Permission.locationWhenInUse.status;
    if (permissionStatus.isPermanentlyDenied) {
      await handlePermanentlyDenied(context);
      return null;
    }

    if (!permissionStatus.isGranted) {
      final bool granted = await requestPermission();
      if (!granted) {
        final PermissionStatus latest = await Permission.locationWhenInUse.status;
        if (latest.isPermanentlyDenied) {
          await handlePermanentlyDenied(context);
        }
        return null;
      }
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final List<Placemark> places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) {
        return 'Unknown location';
      }

      final Placemark place = places.first;
      final List<String> parts = <String>[
        if ((place.street ?? '').isNotEmpty) place.street!,
        if ((place.locality ?? '').isNotEmpty) place.locality!,
        if ((place.administrativeArea ?? '').isNotEmpty) place.administrativeArea!,
        if ((place.country ?? '').isNotEmpty) place.country!,
      ];

      if (parts.isEmpty) {
        return 'Unknown location';
      }

      return parts.join(', ');
    } catch (_) {
      return 'Unknown location';
    }
  }
}

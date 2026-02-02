import 'dart:math';
import 'package:geolocator/geolocator.dart' as geo;

class PositionInterpolator {
  geo.Position? _startPosition;
  geo.Position? _endPosition;
  DateTime? _startTime;
  final Duration _duration;

  PositionInterpolator({Duration? duration})
      : _duration = duration ?? const Duration(seconds: 2);

  void setTarget(geo.Position newPosition) {
    if (_endPosition != null) {
      _startPosition = _endPosition;
    }
    _endPosition = newPosition;
    _startTime = DateTime.now();
  }

  geo.Position? getCurrentPosition() {
    if (_startPosition == null || _endPosition == null || _startTime == null) {
      return _endPosition;
    }

    final elapsed = DateTime.now().difference(_startTime!);
    if (elapsed >= _duration) {
      return _endPosition;
    }

    // Calculer le progrès (0.0 à 1.0)
    final progress = elapsed.inMilliseconds / _duration.inMilliseconds;
    
    // Interpolation linéaire pour latitude et longitude
    final lat = _lerp(_startPosition!.latitude, _endPosition!.latitude, progress);
    final lng = _lerp(_startPosition!.longitude, _endPosition!.longitude, progress);
    
    // Interpolation pour le heading (direction)
    final heading = _lerpAngle(_startPosition!.heading, _endPosition!.heading, progress);

    return geo.Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: _endPosition!.accuracy,
      altitude: _endPosition!.altitude,
      altitudeAccuracy: _endPosition!.altitudeAccuracy,
      heading: heading,
      headingAccuracy: _endPosition!.headingAccuracy,
      speed: _endPosition!.speed,
      speedAccuracy: _endPosition!.speedAccuracy,
    );
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress;
  }

  double _lerpAngle(double start, double end, double progress) {
    // Gérer le cas où les angles traversent 0/360
    double diff = end - start;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }
    
    double result = start + diff * progress;
    if (result < 0) result += 360;
    if (result >= 360) result -= 360;
    
    return result;
  }

  bool get isInterpolating {
    if (_startTime == null) return false;
    return DateTime.now().difference(_startTime!) < _duration;
  }
}

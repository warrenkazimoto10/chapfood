import 'dart:async';
import 'dart:math';
import 'smooth_movement_service.dart';

/// Service pour gérer le positionnement en temps réel avec une précision millimétrique
class RealtimePositioningService {
  static final Map<String, _PositionTracker> _trackers = {};
  static Timer? _globalUpdateTimer;
  
  /// Démarre le suivi en temps réel d'un marqueur
  static void startRealtimeTracking({
    required String markerId,
    required double initialLat,
    required double initialLng,
    required Function(double lat, double lng) onPositionUpdate,
    required Stream<Map<String, double>> positionStream,
    double smoothingFactor = 0.1, // Facteur de lissage (0.0 = pas de lissage, 1.0 = lissage maximum)
  }) {
    // Arrêter le suivi précédent s'il existe
    stopRealtimeTracking(markerId);
    
    final tracker = _PositionTracker(
      markerId: markerId,
      currentLat: initialLat,
      currentLng: initialLng,
      onPositionUpdate: onPositionUpdate,
      smoothingFactor: smoothingFactor,
    );
    
    _trackers[markerId] = tracker;
    
    // Écouter le stream de positions
    tracker._subscription = positionStream.listen((newPosition) {
      final newLat = newPosition['lat'] ?? initialLat;
      final newLng = newPosition['lng'] ?? initialLng;
      
      tracker.updatePosition(newLat, newLng);
    });
    
    // Démarrer le timer global si ce n'est pas déjà fait
    _startGlobalUpdateTimer();
  }
  
  /// Arrête le suivi en temps réel d'un marqueur
  static void stopRealtimeTracking(String markerId) {
    final tracker = _trackers.remove(markerId);
    tracker?.dispose();
    
    // Arrêter le timer global s'il n'y a plus de trackers
    if (_trackers.isEmpty) {
      _stopGlobalUpdateTimer();
    }
  }
  
  /// Arrête tous les suivis en temps réel
  static void stopAllRealtimeTracking() {
    for (final tracker in _trackers.values) {
      tracker.dispose();
    }
    _trackers.clear();
    _stopGlobalUpdateTimer();
  }
  
  /// Obtient la position actuelle d'un marqueur
  static Map<String, double>? getCurrentPosition(String markerId) {
    final tracker = _trackers[markerId];
    if (tracker != null) {
      return {
        'lat': tracker.currentLat,
        'lng': tracker.currentLng,
      };
    }
    return null;
  }
  
  /// Démarre le timer global pour les mises à jour fluides
  static void _startGlobalUpdateTimer() {
    if (_globalUpdateTimer != null) return;
    
    _globalUpdateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      for (final tracker in _trackers.values) {
        tracker.updateSmoothPosition();
      }
    });
  }
  
  /// Arrête le timer global
  static void _stopGlobalUpdateTimer() {
    _globalUpdateTimer?.cancel();
    _globalUpdateTimer = null;
  }
  
  /// Calcule la précision de positionnement basée sur la vitesse
  static double calculatePositioningAccuracy(double speedKmh) {
    // Plus la vitesse est élevée, moins la précision est importante
    // Précision de base : 1 mètre
    const double baseAccuracy = 1.0;
    
    // Facteur de vitesse (plus la vitesse est élevée, plus l'erreur augmente)
    final double speedFactor = max(1.0, speedKmh / 10.0);
    
    return baseAccuracy * speedFactor;
  }
  
  /// Filtre les positions aberrantes (outliers)
  static bool isPositionValid({
    required double newLat,
    required double newLng,
    required double previousLat,
    required double previousLng,
    required double maxSpeedKmh,
  }) {
    final distance = SmoothMovementService.calculateDistance(
      previousLat, previousLng, newLat, newLng,
    );
    
    // Calculer la vitesse en km/h
    final speedKmh = (distance / 1000) * 3600; // Conversion m/s -> km/h
    
    // Vérifier si la vitesse est réaliste
    return speedKmh <= maxSpeedKmh;
  }
}

/// Tracker individuel pour un marqueur
class _PositionTracker {
  final String markerId;
  double currentLat;
  double currentLng;
  final Function(double lat, double lng) onPositionUpdate;
  final double smoothingFactor;
  
  double _targetLat = 0;
  double _targetLng = 0;
  bool _hasTarget = false;
  StreamSubscription<Map<String, double>>? _subscription;
  
  _PositionTracker({
    required this.markerId,
    required this.currentLat,
    required this.currentLng,
    required this.onPositionUpdate,
    required this.smoothingFactor,
  }) {
    _targetLat = currentLat;
    _targetLng = currentLng;
    _hasTarget = true;
  }
  
  void updatePosition(double newLat, double newLng) {
    // Vérifier si la nouvelle position est valide
    if (RealtimePositioningService.isPositionValid(
      newLat: newLat,
      newLng: newLng,
      previousLat: currentLat,
      previousLng: currentLng,
      maxSpeedKmh: 120.0, // Vitesse maximale réaliste
    )) {
      _targetLat = newLat;
      _targetLng = newLng;
      _hasTarget = true;
    }
  }
  
  void updateSmoothPosition() {
    if (!_hasTarget) return;
    
    // Calculer la distance vers la cible
    final distance = SmoothMovementService.calculateDistance(
      currentLat, currentLng, _targetLat, _targetLng,
    );
    
    // Si on est très proche de la cible, on s'y rend directement
    if (distance < 0.1) { // 10 cm
      currentLat = _targetLat;
      currentLng = _targetLng;
      _hasTarget = false;
    } else {
      // Interpolation fluide vers la cible
      final factor = min(smoothingFactor, 1.0);
      currentLat += (_targetLat - currentLat) * factor;
      currentLng += (_targetLng - currentLng) * factor;
    }
    
    // Mettre à jour la position
    onPositionUpdate(currentLat, currentLng);
  }
  
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Service pour gérer les animations de marqueurs
class MarkerAnimationService {
  static final Map<String, _MarkerAnimator> _animators = {};
  
  /// Anime l'apparition d'un marqueur
  static void animateMarkerAppearance({
    required String markerId,
    required Function(double scale, double opacity) onAnimationUpdate,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    _animators[markerId]?.dispose();
    
    final animator = _MarkerAnimator(
      markerId: markerId,
      onAnimationUpdate: onAnimationUpdate,
      duration: duration,
    );
    
    _animators[markerId] = animator;
    animator.startAppearanceAnimation();
  }
  
  /// Anime la disparition d'un marqueur
  static void animateMarkerDisappearance({
    required String markerId,
    required Function(double scale, double opacity) onAnimationUpdate,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final animator = _animators[markerId];
    if (animator != null) {
      animator.startDisappearanceAnimation();
    }
  }
  
  /// Anime le "pulse" d'un marqueur
  static void animateMarkerPulse({
    required String markerId,
    required Function(double scale) onAnimationUpdate,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    _animators[markerId]?.dispose();
    
    final animator = _MarkerAnimator(
      markerId: markerId,
      onAnimationUpdate: (scale, opacity) => onAnimationUpdate(scale),
      duration: duration,
    );
    
    _animators[markerId] = animator;
    animator.startPulseAnimation();
  }
  
  /// Arrête toutes les animations
  static void stopAllAnimations() {
    for (final animator in _animators.values) {
      animator.dispose();
    }
    _animators.clear();
  }
}

/// Animateur pour les marqueurs
class _MarkerAnimator {
  final String markerId;
  final Function(double scale, double opacity) onAnimationUpdate;
  final Duration duration;
  
  Timer? _timer;
  DateTime? _startTime;
  double _currentScale = 0.0;
  double _currentOpacity = 0.0;
  
  _MarkerAnimator({
    required this.markerId,
    required this.onAnimationUpdate,
    required this.duration,
  });
  
  void startAppearanceAnimation() {
    _startTime = DateTime.now();
    _currentScale = 0.0;
    _currentOpacity = 0.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(_startTime!);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      // Animation d'apparition avec effet de rebond
      _currentScale = _bounceOut(progress);
      _currentOpacity = progress;
      
      onAnimationUpdate(_currentScale, _currentOpacity);
      
      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }
  
  void startDisappearanceAnimation() {
    _startTime = DateTime.now();
    final startScale = _currentScale;
    final startOpacity = _currentOpacity;
    
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(_startTime!);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      
      _currentScale = startScale * (1.0 - progress);
      _currentOpacity = startOpacity * (1.0 - progress);
      
      onAnimationUpdate(_currentScale, _currentOpacity);
      
      if (progress >= 1.0) {
        timer.cancel();
      }
    });
  }
  
  void startPulseAnimation() {
    _startTime = DateTime.now();
    _currentScale = 1.0;
    _currentOpacity = 1.0;
    
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final elapsed = DateTime.now().difference(_startTime!);
      final progress = (elapsed.inMilliseconds / duration.inMilliseconds) % 1.0;
      
      // Animation de pulse
      _currentScale = 1.0 + 0.2 * sin(progress * 2 * pi);
      
      onAnimationUpdate(_currentScale, _currentOpacity);
    });
  }
  
  double _bounceOut(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      return 7.5625 * (t -= 1.5 / 2.75) * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      return 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375;
    } else {
      return 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375;
    }
  }
  
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

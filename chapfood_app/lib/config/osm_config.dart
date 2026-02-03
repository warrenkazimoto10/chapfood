/// Configuration centralisée pour la stack OpenStreetMap (tuiles Carto, OSRM, Photon).
/// Les URLs peuvent être surchargées via .env pour une phase self-hosted ultérieure.
class OsmConfig {
  OsmConfig._();

  /// User-Agent pour les requêtes HTTP (politique d'usage OSRM / Photon).
  static const String userAgent = 'ChapFood/1.0';

  // --- Tuiles (affichage carte) ---
  /// URL des tuiles Carto / OSM. Utiliser {z}, {x}, {y} pour les placeholders.
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Attribution obligatoire pour les tuiles.
  static const String attribution =
      '© <a href="https://openstreetmap.org/copyright">OpenStreetMap</a> contributors';

  // --- OSRM (routing) ---
  /// Base URL de l'API OSRM (démo publique en phase 1).
  static const String osrmBaseUrl = 'https://router.project-osrm.org';

  /// Profil de routage par défaut: driving, walking, cycling.
  static const String defaultRoutingProfile = 'driving';

  // --- Photon (géocodage) ---
  /// Base URL de l'API Photon (Komoot).
  static const String photonBaseUrl = 'https://photon.komoot.io/api';

  // --- Carte par défaut (Grand Bassam) ---
  static const double defaultLat = 5.226313;
  static const double defaultLng = -3.768063;
  static const double defaultZoom = 15.0;
}

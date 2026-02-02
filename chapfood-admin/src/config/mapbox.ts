// Configuration Mapbox
export const MAPBOX_CONFIG = {
  // Clé API Mapbox
  ACCESS_TOKEN: 'pk.eyJ1IjoiYW5nZXdhcnJlbjEyMiIsImEiOiJjbWN0MGY2eTEwMDNhMmpzamF0OHc5YWt2In0.IY84028ftDyxRM8j_1AaHA',
  
  // Styles de carte disponibles
  MAP_STYLES: {
    STREETS: 'mapbox://styles/mapbox/streets-v12',
    OUTDOORS: 'mapbox://styles/mapbox/outdoors-v12',
    LIGHT: 'mapbox://styles/mapbox/light-v11',
    DARK: 'mapbox://styles/mapbox/dark-v11',
    SATELLITE: 'mapbox://styles/mapbox/satellite-v9',
    SATELLITE_STREETS: 'mapbox://styles/mapbox/satellite-streets-v12'
  },
  
  // Configuration par défaut
  DEFAULT_VIEWPORT: {
    longitude: 2.3522, // Paris par défaut
    latitude: 48.8566,
    zoom: 13
  },
  
  // Configuration des marqueurs
  MARKERS: {
    DRIVER: {
      color: '#2563eb', // Bleu
      size: 48
    },
    DELIVERY: {
      color: '#16a34a', // Vert
      size: 48
    }
  },
  
  // Configuration des popups
  POPUP: {
    OFFSET: 25,
    CLOSE_BUTTON: true,
    CLOSE_ON_CLICK: false
  }
};

// Styles CSS pour les marqueurs personnalisés
export const MARKER_STYLES = {
  driver: {
    width: '48px',
    height: '48px',
    backgroundColor: MAPBOX_CONFIG.MARKERS.DRIVER.color,
    borderRadius: '50%',
    border: '4px solid white',
    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer'
  },
  delivery: {
    width: '48px',
    height: '48px',
    backgroundColor: MAPBOX_CONFIG.MARKERS.DELIVERY.color,
    borderRadius: '50%',
    border: '4px solid white',
    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    cursor: 'pointer'
  }
};







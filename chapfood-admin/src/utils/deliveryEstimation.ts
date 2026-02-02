// Fonction pour calculer la distance entre deux points en utilisant la formule de Haversine
export function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Rayon de la Terre en kilomètres
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const distance = R * c; // Distance en kilomètres
  return distance;
}

// Fonction pour estimer le temps de livraison basé sur la distance
export function estimateDeliveryTime(distance: number): number {
  // Estimation basée sur:
  // - Vitesse moyenne en ville: 25 km/h
  // - Temps de préparation: 10 minutes
  // - Temps de livraison sur place: 5 minutes
  
  const averageSpeed = 25; // km/h
  const preparationTime = 10; // minutes
  const deliveryTime = 5; // minutes
  
  const travelTime = (distance / averageSpeed) * 60; // Convertir en minutes
  const totalTime = travelTime + preparationTime + deliveryTime;
  
  return Math.round(totalTime);
}

// Fonction pour formater le temps estimé
export function formatEstimatedTime(minutes: number): string {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  
  if (hours > 0) {
    return `${hours}h${mins > 0 ? mins.toString().padStart(2, '0') : ''}`;
  } else {
    return `${mins} min`;
  }
}

// Fonction pour obtenir l'heure d'arrivée estimée
export function getEstimatedArrivalTime(minutes: number): Date {
  const now = new Date();
  const estimatedTime = new Date(now.getTime() + minutes * 60000);
  return estimatedTime;
}






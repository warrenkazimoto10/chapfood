// Service Nominatim pour la recherche d'adresses (gratuit, basé sur OpenStreetMap)
export interface NominatimResult {
  place_id: number;
  licence: string;
  osm_type: string;
  osm_id: number;
  boundingbox: [string, string, string, string];
  lat: string;
  lon: string;
  display_name: string;
  class: string;
  type: string;
  importance: number;
  icon?: string;
}

export interface NominatimSearchOptions {
  limit?: number;
  countrycodes?: string; // 'ci' pour Côte d'Ivoire
  viewbox?: string; // Format: "min_lon,min_lat,max_lon,max_lat"
  bounded?: number; // 1 pour limiter aux résultats dans la viewbox
  addressdetails?: number; // 1 pour plus de détails
}

class NominatimService {
  private readonly baseUrl = 'https://nominatim.openstreetmap.org';
  private readonly userAgent = 'ChapFood/1.0'; // Important pour respecter la politique d'utilisation
  private lastRequestTime = 0;
  private readonly minRequestInterval = 1000; // 1 seconde minimum entre les requêtes

  /**
   * Recherche d'adresses avec Nominatim
   * @param query - Terme de recherche
   * @param options - Options de recherche
   */
  async search(
    query: string, 
    options: NominatimSearchOptions = {}
  ): Promise<NominatimResult[]> {
    const {
      limit = 10,
      countrycodes = 'ci', // Côte d'Ivoire
      viewbox,
      bounded = 1,
      addressdetails = 1
    } = options;

    // Viewbox pour Grand-Bassam et environs
    const defaultViewbox = viewbox || '-3.9,5.0,-3.5,5.4'; // lon_min,lat_min,lon_max,lat_max

    // Rate limiting : respecter 1 requête par seconde
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    if (timeSinceLastRequest < this.minRequestInterval) {
      await new Promise(resolve => setTimeout(resolve, this.minRequestInterval - timeSinceLastRequest));
    }

    const params = new URLSearchParams({
      q: query,
      format: 'json',
      limit: limit.toString(),
      countrycodes,
      viewbox: defaultViewbox,
      bounded: bounded.toString(),
      addressdetails: addressdetails.toString(),
      'accept-language': 'fr' // Résultats en français
    });

    try {
      this.lastRequestTime = Date.now();
      
      const response = await fetch(`${this.baseUrl}/search?${params.toString()}`, {
        headers: {
          'User-Agent': this.userAgent, // Obligatoire pour Nominatim
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Erreur Nominatim: ${response.status}`);
      }

      const data: NominatimResult[] = await response.json();
      
      // Filtrer et enrichir les résultats
      return this.enrichResults(data);
    } catch (error) {
      console.error('Erreur lors de la recherche Nominatim:', error);
      return [];
    }
  }

  /**
   * Enrichit les résultats Nominatim avec des informations utiles
   */
  private enrichResults(results: NominatimResult[]): NominatimResult[] {
    return results.map(result => {
      // Améliorer le display_name pour Grand-Bassam
      const displayName = this.formatDisplayName(result);
      return {
        ...result,
        display_name: displayName
      };
    });
  }

  /**
   * Formate le nom d'affichage pour une meilleure lisibilité
   */
  private formatDisplayName(result: NominatimResult): string {
    const parts = result.display_name.split(',');
    
    // Pour Grand-Bassam, on veut afficher: "Nom du lieu, Quartier, Grand-Bassam"
    if (parts.length > 2) {
      // Prendre les 2-3 premières parties (nom, quartier/rue, ville)
      return parts.slice(0, Math.min(3, parts.length)).join(', ').trim();
    }
    
    return result.display_name;
  }

  /**
   * Recherche inversée (coordonnées -> adresse)
   */
  async reverse(latitude: number, longitude: number): Promise<NominatimResult | null> {
    // Rate limiting
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequestTime;
    if (timeSinceLastRequest < this.minRequestInterval) {
      await new Promise(resolve => setTimeout(resolve, this.minRequestInterval - timeSinceLastRequest));
    }

    const params = new URLSearchParams({
      lat: latitude.toString(),
      lon: longitude.toString(),
      format: 'json',
      'accept-language': 'fr',
      addressdetails: '1'
    });

    try {
      this.lastRequestTime = Date.now();
      
      const response = await fetch(`${this.baseUrl}/reverse?${params.toString()}`, {
        headers: {
          'User-Agent': this.userAgent,
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Erreur Nominatim reverse: ${response.status}`);
      }

      const data: any = await response.json();
      return data;
    } catch (error) {
      console.error('Erreur lors du reverse geocoding:', error);
      return null;
    }
  }

  /**
   * Convertit un résultat Nominatim en format compatible avec LocationSearch
   */
  convertToLocationResult(result: NominatimResult): {
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    type: string;
    source: 'nominatim';
  } {
    return {
      name: this.extractName(result),
      address: result.display_name,
      latitude: parseFloat(result.lat),
      longitude: parseFloat(result.lon),
      type: result.type || result.class || 'lieu',
      source: 'nominatim'
    };
  }

  /**
   * Extrait un nom court depuis le display_name
   */
  private extractName(result: NominatimResult): string {
    const parts = result.display_name.split(',');
    
    // Si c'est un point d'intérêt (pharmacie, restaurant, etc.)
    if (result.type && ['pharmacy', 'restaurant', 'hotel', 'bank', 'school'].includes(result.type)) {
      return parts[0].trim();
    }
    
    // Sinon, prendre les 2 premières parties
    return parts.slice(0, 2).join(', ').trim();
  }
}

export const nominatimService = new NominatimService();




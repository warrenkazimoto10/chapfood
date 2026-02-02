import { supabase } from '@/integrations/supabase/client';
import { nominatimService } from './nominatimService';

export interface DeliveryLocation {
  id: string;
  name: string;
  district: string;
  zone_type: 'quartier' | 'zone_commerciale' | 'zone_residentielle' | 'zone_industrielle' | 'village' | 'lieu_public';
  latitude: number;
  longitude: number;
  postal_code?: string;
  delivery_fee: number;
  estimated_delivery_time: number;
  is_active: boolean;
  description?: string;
}

export interface Landmark {
  id: string;
  name: string;
  landmark_type: 'restaurant' | 'hotel' | 'banque' | 'pharmacie' | 'hopital' | 'ecole' | 'eglise' | 'mosquee' | 'marche' | 'station_service' | 'bureau' | 'autre';
  address?: string;
  latitude: number;
  longitude: number;
  delivery_location_id: string;
  description?: string;
}

export interface DeliveryZone {
  id: string;
  name: string;
  base_fee: number;
  max_distance_km: number;
  estimated_time_minutes: number;
  color_code: string;
  is_active: boolean;
}

export interface NearestLocation {
  location_id: string;
  location_name: string;
  district: string;
  distance_km: number;
  delivery_fee: number;
  estimated_time: number;
}

export interface DeliveryFeeResult {
  zone_name: string;
  delivery_fee: number;
  estimated_time: number;
  distance_km: number;
}

class LocationService {
  /**
   * Recherche de locations par nom (avec autocomplétion)
   */
  async searchLocations(query: string, limit: number = 10): Promise<DeliveryLocation[]> {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('*')
      .ilike('name', `%${query}%`)
      .eq('is_active', true)
      .order('name')
      .limit(limit);

    if (error) {
      console.error('Erreur lors de la recherche de locations:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Recherche par district
   */
  async getLocationsByDistrict(district: string): Promise<DeliveryLocation[]> {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('*')
      .eq('district', district)
      .eq('is_active', true)
      .order('name');

    if (error) {
      console.error('Erreur lors de la recherche par district:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Recherche par type de zone
   */
  async getLocationsByType(zone_type: string): Promise<DeliveryLocation[]> {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('*')
      .eq('zone_type', zone_type)
      .eq('is_active', true)
      .order('name');

    if (error) {
      console.error('Erreur lors de la recherche par type:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Trouve les locations les plus proches d'un point GPS
   */
  async findNearestLocations(
    latitude: number,
    longitude: number,
    maxDistanceKm: number = 10,
    limit: number = 10
  ): Promise<NearestLocation[]> {
    try {
      // Essayer d'abord la fonction RPC
      const { data, error } = await supabase.rpc('find_nearest_locations', {
        target_lat: latitude,
        target_lon: longitude,
        max_distance_km: maxDistanceKm,
        limit_count: limit
      });

      if (error) {
        console.warn('Fonction RPC non disponible, utilisation du calcul client:', error);
        // Fallback : récupérer toutes les locations et calculer côté client
        return await this.findNearestLocationsFallback(latitude, longitude, maxDistanceKm, limit);
      }

      return data || [];
    } catch (error) {
      console.warn('Erreur RPC, utilisation du fallback:', error);
      return await this.findNearestLocationsFallback(latitude, longitude, maxDistanceKm, limit);
    }
  }

  /**
   * Fallback pour trouver les locations les plus proches (calcul côté client)
   */
  private async findNearestLocationsFallback(
    latitude: number,
    longitude: number,
    maxDistanceKm: number = 10,
    limit: number = 10
  ): Promise<NearestLocation[]> {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('*')
      .eq('is_active', true)
      .limit(100); // Récupérer plus de données pour filtrer

    if (error) {
      console.error('Erreur lors de la récupération des locations:', error);
      return [];
    }

    if (!data) return [];

    // Calculer les distances et filtrer
    const locationsWithDistance = data
      .map(location => ({
        location_id: location.id,
        location_name: location.name,
        district: location.district,
        distance_km: this.calculateDistance(latitude, longitude, location.latitude, location.longitude),
        delivery_fee: location.delivery_fee,
        estimated_time: location.estimated_delivery_time
      }))
      .filter(location => location.distance_km <= maxDistanceKm)
      .sort((a, b) => a.distance_km - b.distance_km)
      .slice(0, limit);

    return locationsWithDistance;
  }

  /**
   * Calcule les frais de livraison pour une position GPS
   */
  async getDeliveryFee(latitude: number, longitude: number): Promise<DeliveryFeeResult | null> {
    try {
      // Essayer d'abord la fonction RPC
      const { data, error } = await supabase.rpc('get_delivery_fee', {
        target_lat: latitude,
        target_lon: longitude
      });

      if (error) {
        console.warn('Fonction RPC non disponible, utilisation du calcul client:', error);
        // Fallback : calculer côté client
        return await this.getDeliveryFeeFallback(latitude, longitude);
      }

      return data?.[0] || null;
    } catch (error) {
      console.warn('Erreur RPC, utilisation du fallback:', error);
      return await this.getDeliveryFeeFallback(latitude, longitude);
    }
  }

  /**
   * Fallback pour calculer les frais de livraison (calcul côté client)
   */
  private async getDeliveryFeeFallback(latitude: number, longitude: number): Promise<DeliveryFeeResult | null> {
    // Récupérer les zones de livraison actives
    const { data: zones, error: zonesError } = await supabase
      .from('delivery_zones')
      .select('*')
      .eq('is_active', true)
      .order('base_fee');

    if (zonesError || !zones || zones.length === 0) {
      console.warn('Aucune zone de livraison trouvée, utilisation des frais par défaut');
      // Frais par défaut pour Grand-Bassam
      return {
        zone_name: 'Grand-Bassam',
        delivery_fee: 1000, // 1000 FCFA par défaut
        estimated_time: 25, // 25 minutes par défaut
        distance_km: 0
      };
    }

    // Trouver la location la plus proche
    const nearestLocations = await this.findNearestLocations(latitude, longitude, 5, 1);
    
    if (nearestLocations.length === 0) {
      // Aucune location proche trouvée, utiliser la première zone
      const defaultZone = zones[0];
      return {
        zone_name: defaultZone.name,
        delivery_fee: defaultZone.base_fee,
        estimated_time: defaultZone.estimated_time_minutes,
        distance_km: 0
      };
    }

    const nearestLocation = nearestLocations[0];
    const distance = nearestLocation.distance_km;

    // Trouver la zone appropriée selon la distance
    let selectedZone = zones[0]; // Zone par défaut
    for (const zone of zones) {
      if (distance <= zone.max_distance_km) {
        selectedZone = zone;
        break;
      }
    }

    return {
      zone_name: selectedZone.name,
      delivery_fee: selectedZone.base_fee,
      estimated_time: selectedZone.estimated_time_minutes,
      distance_km: distance
    };
  }

  /**
   * Recherche de landmarks (points de repère)
   */
  async searchLandmarks(query: string, limit: number = 10): Promise<Landmark[]> {
    const { data, error } = await supabase
      .from('landmarks')
      .select(`
        *,
        delivery_location:delivery_location_id (
          name,
          district
        )
      `)
      .ilike('name', `%${query}%`)
      .eq('is_active', true)
      .order('name')
      .limit(limit);

    if (error) {
      console.error('Erreur lors de la recherche de landmarks:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Recherche de landmarks par type
   */
  async getLandmarksByType(type: string): Promise<Landmark[]> {
    const { data, error } = await supabase
      .from('landmarks')
      .select(`
        *,
        delivery_location:delivery_location_id (
          name,
          district
        )
      `)
      .eq('landmark_type', type)
      .eq('is_active', true)
      .order('name');

    if (error) {
      console.error('Erreur lors de la recherche de landmarks par type:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Obtient toutes les zones de livraison
   */
  async getDeliveryZones(): Promise<DeliveryZone[]> {
    const { data, error } = await supabase
      .from('delivery_zones')
      .select('*')
      .eq('is_active', true)
      .order('base_fee');

    if (error) {
      console.error('Erreur lors de la récupération des zones de livraison:', error);
      return [];
    }

    return data || [];
  }

  /**
   * Obtient tous les districts disponibles
   */
  async getDistricts(): Promise<string[]> {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('district')
      .eq('is_active', true)
      .order('district');

    if (error) {
      console.error('Erreur lors de la récupération des districts:', error);
      return [];
    }

    // Supprimer les doublons
    const districts = [...new Set(data?.map(item => item.district) || [])];
    return districts;
  }

  /**
   * Recherche intelligente combinée (locations + landmarks + Nominatim)
   */
  async smartSearch(query: string, limit: number = 15): Promise<{
    locations: DeliveryLocation[];
    landmarks: Landmark[];
    nominatimResults: Array<{
      name: string;
      address: string;
      latitude: number;
      longitude: number;
      type: string;
      source: 'nominatim';
    }>;
  }> {
    // Recherche en parallèle : base de données locale + Nominatim
    const [dbResults, nominatimResults] = await Promise.all([
      // Recherche dans la base de données locale
      Promise.all([
        this.searchLocations(query, Math.floor(limit / 2)),
        this.searchLandmarks(query, Math.floor(limit / 2))
      ]),
      // Recherche Nominatim (OpenStreetMap)
      nominatimService.search(query, {
        limit: limit,
        countrycodes: 'ci',
        viewbox: '-3.9,5.0,-3.5,5.4', // Grand-Bassam et environs
        bounded: 1
      })
    ]);

    const [locations, landmarks] = dbResults;
    
    // Convertir les résultats Nominatim au format attendu
    const convertedNominatim = nominatimResults
      .map(result => nominatimService.convertToLocationResult(result))
      .filter(result => {
        // Filtrer pour ne garder que les résultats dans Grand-Bassam
        return this.isValidGPSCoordinates(result.latitude, result.longitude);
      });

    return { 
      locations, 
      landmarks,
      nominatimResults: convertedNominatim
    };
  }

  /**
   * Validation d'une adresse GPS
   */
  isValidGPSCoordinates(latitude: number, longitude: number): boolean {
    // Grand-Bassam et environs: Lat ~5.1-5.3, Lon ~-3.6 à -3.8
    return (
      latitude >= 5.0 && latitude <= 5.4 &&
      longitude >= -3.9 && longitude <= -3.5
    );
  }

  /**
   * Calcul de distance simple entre deux points GPS
   */
  calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Rayon de la Terre en km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  /**
   * Formate une adresse pour l'affichage
   */
  formatAddress(location: DeliveryLocation, landmark?: Landmark): string {
    if (landmark) {
      return `${landmark.name}, ${landmark.address || location.name}, ${location.district}`;
    }
    return `${location.name}, ${location.district}`;
  }

  /**
   * Obtient les statistiques des locations
   */
  async getLocationStats(): Promise<{
    total_locations: number;
    total_landmarks: number;
    total_zones: number;
    districts_count: number;
  }> {
    const [locationsResult, landmarksResult, zonesResult, districtsResult] = await Promise.all([
      supabase.from('delivery_locations').select('id', { count: 'exact' }).eq('is_active', true),
      supabase.from('landmarks').select('id', { count: 'exact' }).eq('is_active', true),
      supabase.from('delivery_zones').select('id', { count: 'exact' }).eq('is_active', true),
      this.getDistricts()
    ]);

    return {
      total_locations: locationsResult.count || 0,
      total_landmarks: landmarksResult.count || 0,
      total_zones: zonesResult.count || 0,
      districts_count: districtsResult.length
    };
  }
}

export const locationService = new LocationService();


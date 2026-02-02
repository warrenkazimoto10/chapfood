import { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  MapPin, 
  Navigation, 
  Clock, 
  DollarSign, 
  Map,
  CheckCircle,
  AlertCircle,
  Loader2
} from 'lucide-react';
import LocationSearch from './LocationSearch';
import { locationService, DeliveryFeeResult } from '@/services/locationService';
import { MAPBOX_CONFIG } from '@/config/mapbox';
import { cn } from '@/lib/utils';

interface DeliveryLocationPickerProps {
  onLocationConfirmed: (location: {
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    delivery_fee: number;
    estimated_time: number;
  }) => void;
  onCancel: () => void;
  className?: string;
}

const DeliveryLocationPicker = ({ 
  onLocationConfirmed, 
  onCancel,
  className 
}: DeliveryLocationPickerProps) => {
  const [selectedLocation, setSelectedLocation] = useState<{
    name: string;
    address: string;
    latitude: number;
    longitude: number;
  } | null>(null);
  
  const [deliveryInfo, setDeliveryInfo] = useState<DeliveryFeeResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [mapLoaded, setMapLoaded] = useState(false);
  const [userLocation, setUserLocation] = useState<{lat: number, lng: number} | null>(null);
  const [locationError, setLocationError] = useState<string | null>(null);
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const markerRef = useRef<any>(null);

  // Fonction pour obtenir la position de l'utilisateur
  const getUserLocation = () => {
    return new Promise<{lat: number, lng: number}>((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Géolocalisation non supportée'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          const { latitude, longitude } = position.coords;
          resolve({ lat: latitude, lng: longitude });
        },
        (error) => {
          reject(error);
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000 // 5 minutes
        }
      );
    });
  };

  // Obtenir la position de l'utilisateur au chargement
  useEffect(() => {
    getUserLocation()
      .then(location => {
        setUserLocation(location);
        console.log('Position utilisateur obtenue:', location);
      })
      .catch(error => {
        console.warn('Impossible d\'obtenir la position:', error);
        setLocationError('Impossible d\'obtenir votre position');
        // Fallback sur Grand-Bassam
        setUserLocation({ lat: 5.2091, lng: -3.7386 });
      });
  }, []);

  // Chargement de la carte Mapbox
  useEffect(() => {
    const loadMapbox = async () => {
      try {
        // Charger dynamiquement Mapbox GL JS
        const mapboxgl = await import('mapbox-gl');
        
        if (mapContainerRef.current && !mapInstanceRef.current && userLocation) {
          mapboxgl.default.accessToken = MAPBOX_CONFIG.ACCESS_TOKEN;
          
          const map = new mapboxgl.default.Map({
            container: mapContainerRef.current,
            style: MAPBOX_CONFIG.MAP_STYLES.STREETS,
            center: [userLocation.lng, userLocation.lat], // Position de l'utilisateur
            zoom: 15, // Zoom plus proche pour la position de l'utilisateur
            attributionControl: false
          });

          mapInstanceRef.current = map;

          map.on('load', () => {
            setMapLoaded(true);
          });

          // Ajouter un marqueur à la position de l'utilisateur
          markerRef.current = new mapboxgl.default.Marker({
            color: '#EF4444',
            draggable: true
          })
          .setLngLat([userLocation.lng, userLocation.lat])
          .addTo(map);

          // Événement de déplacement du marqueur
          markerRef.current.on('dragend', () => {
            const lngLat = markerRef.current.getLngLat();
            handleMapClick(lngLat.lat, lngLat.lng);
          });

          // Événement de clic sur la carte
          map.on('click', (e) => {
            const { lng, lat } = e.lngLat;
            handleMapClick(lat, lng);
          });
        }
      } catch (error) {
        console.error('Erreur lors du chargement de Mapbox:', error);
      }
    };

    if (userLocation) {
      loadMapbox();
    }
  }, [userLocation]);

  // Mettre à jour la carte quand une location est sélectionnée
  useEffect(() => {
    if (selectedLocation && mapInstanceRef.current && markerRef.current) {
      markerRef.current.setLngLat([selectedLocation.longitude, selectedLocation.latitude]);
      mapInstanceRef.current.flyTo({
        center: [selectedLocation.longitude, selectedLocation.latitude],
        zoom: 16,
        duration: 1000
      });
    }
  }, [selectedLocation]);

  const handleLocationSelected = async (location: {
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    delivery_fee: number;
    estimated_time: number;
  }) => {
    setSelectedLocation({
      name: location.name,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude
    });

    // Calculer les frais de livraison
    await calculateDeliveryFee(location.latitude, location.longitude);
  };

  const handleMapClick = async (latitude: number, longitude: number) => {
    setLoading(true);
    
    try {
      // Trouver la location la plus proche
      const nearestLocations = await locationService.findNearestLocations(
        latitude, 
        longitude, 
        1, // 1km max
        1  // 1 résultat
      );

      if (nearestLocations.length > 0) {
        const nearest = nearestLocations[0];
        const location = {
          name: nearest.location_name,
          address: `${nearest.location_name}, ${nearest.district}`,
          latitude: latitude,
          longitude: longitude,
          delivery_fee: nearest.delivery_fee,
          estimated_time: nearest.estimated_time
        };

        setSelectedLocation({
          name: location.name,
          address: location.address,
          latitude: latitude,
          longitude: longitude
        });

        await calculateDeliveryFee(latitude, longitude);
      } else {
        // Location générique si pas de quartier proche
        const location = {
          name: 'Position GPS',
          address: `Position: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}`,
          latitude: latitude,
          longitude: longitude,
          delivery_fee: 0,
          estimated_time: 20
        };

        setSelectedLocation(location);
        await calculateDeliveryFee(latitude, longitude);
      }
    } catch (error) {
      console.error('Erreur lors de la recherche de location:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateDeliveryFee = async (latitude: number, longitude: number) => {
    try {
      const feeInfo = await locationService.getDeliveryFee(latitude, longitude);
      setDeliveryInfo(feeInfo);
    } catch (error) {
      console.error('Erreur lors du calcul des frais:', error);
      // Valeurs par défaut
      setDeliveryInfo({
        zone_name: 'Zone Standard',
        delivery_fee: 1000,
        estimated_time: 25,
        distance_km: 5
      });
    }
  };

  const handleConfirm = () => {
    if (selectedLocation && deliveryInfo) {
      onLocationConfirmed({
        name: selectedLocation.name,
        address: selectedLocation.address,
        latitude: selectedLocation.latitude,
        longitude: selectedLocation.longitude,
        delivery_fee: deliveryInfo.delivery_fee,
        estimated_time: deliveryInfo.estimated_time
      });
    }
  };

  const isValidLocation = selectedLocation && 
    locationService.isValidGPSCoordinates(selectedLocation.latitude, selectedLocation.longitude);

  return (
    <div className={cn("space-y-6", className)}>
      {/* En-tête */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MapPin className="h-5 w-5 text-primary" />
            Sélection de l'adresse de livraison
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground mb-4">
            Recherchez une adresse ou cliquez sur la carte pour sélectionner la position de livraison.
          </p>
          
          {/* Recherche d'adresse */}
          <LocationSearch
            onLocationSelected={handleLocationSelected}
            selectedLocation={selectedLocation}
            className="mb-4"
          />
        </CardContent>
      </Card>

      {/* Carte */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Map className="h-5 w-5" />
            Carte Interactive
            {!mapLoaded && <Loader2 className="h-4 w-4 animate-spin" />}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="relative">
            {!userLocation && !locationError && (
              <div className="absolute inset-0 flex items-center justify-center bg-gray-100 rounded-lg z-10">
                <div className="text-center">
                  <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
                  <p className="text-sm text-gray-600">Obtention de votre position...</p>
                </div>
              </div>
            )}
            
            {locationError && (
              <div className="absolute inset-0 flex items-center justify-center bg-orange-50 rounded-lg z-10">
                <div className="text-center p-4">
                  <AlertCircle className="h-8 w-8 text-orange-500 mx-auto mb-2" />
                  <p className="text-sm text-orange-700 mb-2">{locationError}</p>
                  <p className="text-xs text-gray-600">Utilisation de Grand-Bassam par défaut</p>
                </div>
              </div>
            )}
            
            <div 
              ref={mapContainerRef}
              className="w-full h-96 rounded-lg border-2 border-dashed border-muted-foreground/25"
            />
            {!mapLoaded && userLocation && (
              <div className="absolute inset-0 flex items-center justify-center bg-muted/50 rounded-lg">
                <div className="text-center">
                  <Loader2 className="h-8 w-8 animate-spin mx-auto mb-2" />
                  <p className="text-sm text-muted-foreground">Chargement de la carte...</p>
                </div>
              </div>
            )}
            
            {/* Légende et bouton de géolocalisation */}
            <div className="absolute top-4 right-4 bg-white/90 backdrop-blur-sm rounded-lg p-3 shadow-lg border">
              <div className="flex items-center gap-2 text-xs mb-2">
                <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                <span>Position de livraison</span>
              </div>
              <div className="flex items-center gap-2 text-xs mb-2">
                <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                <span>Cliquez pour déplacer</span>
              </div>
              {locationError && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => {
                    setLocationError(null);
                    getUserLocation()
                      .then(location => {
                        setUserLocation(location);
                        if (mapInstanceRef.current) {
                          mapInstanceRef.current.setCenter([location.lng, location.lat]);
                          mapInstanceRef.current.setZoom(15);
                          if (markerRef.current) {
                            markerRef.current.setLngLat([location.lng, location.lat]);
                          }
                        }
                      })
                      .catch(error => {
                        console.warn('Impossible d\'obtenir la position:', error);
                        setLocationError('Impossible d\'obtenir votre position');
                      });
                  }}
                  className="w-full text-xs"
                >
                  <Navigation className="h-3 w-3 mr-1" />
                  Ma position
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Informations de livraison */}
      {selectedLocation && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              Informations de livraison
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Adresse sélectionnée */}
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-start gap-3">
                <MapPin className="h-5 w-5 text-green-600 mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-medium text-green-900">{selectedLocation.name}</h4>
                  <p className="text-sm text-green-700 mt-1">{selectedLocation.address}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge variant="outline" className="text-xs">
                      <Navigation className="h-3 w-3 mr-1" />
                      {selectedLocation.latitude.toFixed(4)}, {selectedLocation.longitude.toFixed(4)}
                    </Badge>
                    {isValidLocation && (
                      <Badge variant="default" className="text-xs bg-green-600">
                        <CheckCircle className="h-3 w-3 mr-1" />
                        Position valide
                      </Badge>
                    )}
                  </div>
                </div>
              </div>
            </div>

            <Separator />

            {/* Informations de livraison */}
            {deliveryInfo && (
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg text-center">
                  <DollarSign className="h-6 w-6 text-blue-600 mx-auto mb-2" />
                  <div className="text-lg font-bold text-blue-900">
                    {deliveryInfo.delivery_fee === 0 ? 'Gratuit' : `${deliveryInfo.delivery_fee} FCFA`}
                  </div>
                  <div className="text-xs text-blue-700">Frais de livraison</div>
                </div>

                <div className="p-4 bg-orange-50 border border-orange-200 rounded-lg text-center">
                  <Clock className="h-6 w-6 text-orange-600 mx-auto mb-2" />
                  <div className="text-lg font-bold text-orange-900">
                    {deliveryInfo.estimated_time} min
                  </div>
                  <div className="text-xs text-orange-700">Temps estimé</div>
                </div>

                <div className="p-4 bg-purple-50 border border-purple-200 rounded-lg text-center">
                  <Navigation className="h-6 w-6 text-purple-600 mx-auto mb-2" />
                  <div className="text-lg font-bold text-purple-900">
                    {deliveryInfo.distance_km.toFixed(1)} km
                  </div>
                  <div className="text-xs text-purple-700">Distance</div>
                </div>
              </div>
            )}

            {/* Zone de livraison */}
            {deliveryInfo && (
              <div className="p-3 bg-muted/50 rounded-lg">
                <div className="flex items-center gap-2">
                  <Badge variant="outline">{deliveryInfo.zone_name}</Badge>
                  <span className="text-sm text-muted-foreground">
                    Zone de livraison
                  </span>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Validation */}
      {!isValidLocation && selectedLocation && (
        <Card className="border-red-200 bg-red-50">
          <CardContent className="p-4">
            <div className="flex items-center gap-2 text-red-700">
              <AlertCircle className="h-5 w-5" />
              <span className="font-medium">Position hors zone de livraison</span>
            </div>
            <p className="text-sm text-red-600 mt-1">
              Cette position semble être en dehors de la zone de livraison de Grand-Bassam. 
              Veuillez sélectionner une position dans la zone couverte.
            </p>
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex justify-end gap-3">
        <Button variant="outline" onClick={onCancel}>
          Annuler
        </Button>
        <Button 
          onClick={handleConfirm}
          disabled={!selectedLocation || !isValidLocation || loading}
          className="min-w-32"
        >
          {loading ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin mr-2" />
              Calcul...
            </>
          ) : (
            <>
              <CheckCircle className="h-4 w-4 mr-2" />
              Confirmer
            </>
          )}
        </Button>
      </div>
    </div>
  );
};

export default DeliveryLocationPicker;


import { useState, useEffect, useRef } from "react";
import { Map, Marker, Popup } from 'react-map-gl';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { 
  X, 
  RefreshCw, 
  Truck, 
  MapPin, 
  Clock, 
  Phone, 
  User,
  Navigation,
  AlertCircle,
  Info,
  Package,
  Utensils
} from "lucide-react";
import 'mapbox-gl/dist/mapbox-gl.css';
import { useRealtimeLocation } from '@/services/realtimeLocationService';
import '@/styles/scrollbar.css';
import { MAPBOX_CONFIG, MARKER_STYLES } from '@/config/mapbox';

interface DriverLocation {
  driver_id: number;
  name: string;
  phone: string;
  current_lat: number;
  current_lng: number;
  last_update: string;
}

interface DeliveryLocation {
  order_id: number;
  customer_name: string;
  customer_phone: string;
  delivery_address: string;
  delivery_lat: number;
  delivery_lng: number;
  estimated_delivery_time: string;
  total_amount: number;
  status: string;
}

interface LiveDeliveryMapProps {
  orderId: number;
  isOpen: boolean;
  onClose: () => void;
  driverLocation?: DriverLocation | null;
  deliveryLocation?: DeliveryLocation | null;
}


const LiveDeliveryMap = ({ 
  orderId, 
  isOpen, 
  onClose, 
  driverLocation, 
  deliveryLocation 
}: LiveDeliveryMapProps) => {
  const [viewport, setViewport] = useState({
    longitude: 0,
    latitude: 0,
    zoom: 13
  });
  const [selectedMarker, setSelectedMarker] = useState<string | null>(null);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [routeData, setRouteData] = useState<any>(null);
  const [isLoadingRoute, setIsLoadingRoute] = useState(false);
  const [routeInfo, setRouteInfo] = useState<any>(null);
  const [estimatedTime, setEstimatedTime] = useState<number | null>(null);
  const [timeElapsed, setTimeElapsed] = useState<number>(0);
  const [startTime, setStartTime] = useState<Date | null>(null);
  const [showScrollTop, setShowScrollTop] = useState<boolean>(false);
  const mapRef = useRef<any>(null);
  const mapInstanceRef = useRef<any>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  
  // Coordonnées restaurant (même que l'app livreur pour l'instant)
  const RESTAURANT_COORDS = {
    lat: 5.226313,
    lng: -3.768063,
  };
  
  // Hook pour la géolocalisation temps réel
  const { 
    driverLocation: realtimeDriverLocation, 
    lastUpdate: realtimeLastUpdate, 
    isConnected: isGpsConnected 
  } = useRealtimeLocation(driverLocation?.driver_id);

  // Utiliser la position temps réel si disponible, sinon la position statique
  const currentDriverLocation = realtimeDriverLocation || driverLocation;
  
  // État pour éviter les rechargements inutiles
  const [initialViewportSet, setInitialViewportSet] = useState(false);

  useEffect(() => {
    // Ne définir le viewport initial qu'une seule fois quand le modal s'ouvre
    if (isOpen && !initialViewportSet && (currentDriverLocation || deliveryLocation)) {
      // Centrer la carte différemment selon la phase
      // Phase 1: vers restaurant (status = ready_for_delivery)
      // Phase 2: vers client (status = picked_up ou in_transit)
      let centerLat = RESTAURANT_COORDS.lat; // Coordonnées par défaut (restaurant)
      let centerLng = RESTAURANT_COORDS.lng;
      let zoom = 12;

      const isPhase2 = deliveryLocation?.status === 'picked_up' || deliveryLocation?.status === 'in_transit';

      if (isPhase2 && deliveryLocation?.delivery_lat && deliveryLocation?.delivery_lng) {
        // Phase 2 : centrer plutôt vers le client
        centerLat = deliveryLocation.delivery_lat;
        centerLng = deliveryLocation.delivery_lng;
        zoom = 15;
      } else if (currentDriverLocation?.current_lat && currentDriverLocation?.current_lng) {
        // Phase 1 : centrer entre le livreur et le restaurant
        centerLat = (currentDriverLocation.current_lat + RESTAURANT_COORDS.lat) / 2;
        centerLng = (currentDriverLocation.current_lng + RESTAURANT_COORDS.lng) / 2;
        zoom = 13;
      }
      
      setViewport({
        longitude: centerLng,
        latitude: centerLat,
        zoom: zoom
      });
      setInitialViewportSet(true);
    }
    
    // Réinitialiser quand le modal se ferme
    if (!isOpen) {
      setInitialViewportSet(false);
    }
  }, [isOpen, initialViewportSet, currentDriverLocation, deliveryLocation]);

  // Effet pour mettre à jour la route quand la position du livreur change (avec debounce)
  useEffect(() => {
    if (realtimeDriverLocation && deliveryLocation && isOpen) {
      // Debounce pour éviter trop de recalculs
      const timeoutId = setTimeout(() => {
        console.log('🔄 Position livreur mise à jour, recalcul de la route...');
        fetchRoute();
        setLastUpdate(new Date());
      }, 2000); // Attendre 2 secondes avant de recalculer

      return () => clearTimeout(timeoutId);
    }
  }, [realtimeDriverLocation, deliveryLocation, isOpen]);

  useEffect(() => {
    if (isFullscreen && isOpen) {
      document.documentElement.requestFullscreen();
    } else if (!isFullscreen && document.fullscreenElement) {
      document.exitFullscreen();
    }
  }, [isFullscreen, isOpen]);

  // Charger la route quand les positions sont disponibles
  useEffect(() => {
    if (driverLocation?.current_lat && driverLocation?.current_lng && deliveryLocation) {
      // Attendre que la carte soit chargée avant de calculer la route
      const timer = setTimeout(() => {
        fetchRoute();
        // Démarrer le compteur de temps
        if (!startTime) {
          setStartTime(new Date());
        }
      }, 1000); // Délai de 1 seconde pour s'assurer que la carte est prête

      return () => clearTimeout(timer);
    }
  }, [driverLocation?.current_lat, driverLocation?.current_lng, deliveryLocation?.delivery_lat, deliveryLocation?.delivery_lng]);

  // Compteur de temps en temps réel
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (startTime && isOpen) {
      interval = setInterval(() => {
        const now = new Date();
        const elapsed = Math.floor((now.getTime() - startTime.getTime()) / 1000);
        setTimeElapsed(elapsed);
      }, 1000);
    }
    return () => {
      if (interval) clearInterval(interval);
    };
  }, [startTime, isOpen]);

  // Gestion du scroll pour afficher le bouton "Retour en haut"
  useEffect(() => {
    const handleScroll = () => {
      if (panelRef.current) {
        const scrollTop = panelRef.current.scrollTop;
        setShowScrollTop(scrollTop > 100);
      }
    };

    const panel = panelRef.current;
    if (panel) {
      panel.addEventListener('scroll', handleScroll);
      return () => panel.removeEventListener('scroll', handleScroll);
    }
  }, [isOpen]);

  // Ajouter le tracé de route animé à la carte
  useEffect(() => {
    if (routeData && (mapRef.current || mapInstanceRef.current)) {
      const map = mapRef.current || mapInstanceRef.current;
      console.log('Adding route to map:', map);
      
      // Supprimer les sources et couches existantes
      const layersToRemove = [
        'route-background', 'route-main', 'route-highlight', 
        'route-dashed', 'route-pulse', 'route-glow'
      ];
      const sourcesToRemove = ['route', 'route-animated'];
      
      layersToRemove.forEach(layerId => {
        try {
          if (map.getLayer(layerId)) {
            map.removeLayer(layerId);
          }
        } catch (e) {
          // Layer doesn't exist, ignore
        }
      });
      
      sourcesToRemove.forEach(sourceId => {
        try {
          if (map.getSource(sourceId)) {
            map.removeSource(sourceId);
          }
        } catch (e) {
          // Source doesn't exist, ignore
        }
      });

      // Vérifier que la carte est bien chargée et que les méthodes existent
      if (!map || typeof map.addSource !== 'function') {
        console.warn('Map instance not ready or addSource method not available');
        return;
      }

      // Ajouter la source de données principale
      map.addSource('route', {
        type: 'geojson',
        data: routeData
      });

      // Source pour l'animation (avec des points plus denses)
      const animatedData = {
        ...routeData,
        properties: {
          ...routeData.properties,
          animate: true
        }
      };
      
      map.addSource('route-animated', {
        type: 'geojson',
        data: animatedData
      });

      // 1. Couche de fond avec effet de glow
      map.addLayer({
        id: 'route-glow',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#1e40af',
          'line-width': {
            'base': 1,
            'stops': [[0, 12], [20, 16]]
          },
          'line-opacity': 0.4,
          'line-blur': 2
        }
      });

      // 2. Couche principale avec gradient
      map.addLayer({
        id: 'route-background',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#1e40af',
          'line-width': {
            'base': 1,
            'stops': [[0, 10], [20, 14]]
          },
          'line-opacity': 0.6
        }
      });

      // 3. Couche principale
      map.addLayer({
        id: 'route-main',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#3b82f6',
          'line-width': {
            'base': 1,
            'stops': [[0, 6], [20, 10]]
          },
          'line-opacity': 0.95
        }
      });

      // 4. Couche de surbrillance
      map.addLayer({
        id: 'route-highlight',
        type: 'line',
        source: 'route',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#60a5fa',
          'line-width': {
            'base': 1,
            'stops': [[0, 3], [20, 5]]
          },
          'line-opacity': 1
        }
      });

      // 5. Animation avec pointillés animés
      map.addLayer({
        id: 'route-pulse',
        type: 'line',
        source: 'route-animated',
        layout: {
          'line-join': 'round',
          'line-cap': 'round'
        },
        paint: {
          'line-color': '#ffffff',
          'line-width': {
            'base': 1,
            'stops': [[0, 2], [20, 4]]
          },
          'line-opacity': 0.9,
          'line-dasharray': [2, 2],
          'line-offset': {
            'base': 1,
            'stops': [[0, 0], [20, 0]]
          }
        }
      });

      // Animation CSS pour les pointillés
      const style = document.createElement('style');
      style.textContent = `
        @keyframes dash {
          to {
            stroke-dashoffset: -4;
          }
        }
        .mapboxgl-canvas {
          animation: dash 1s linear infinite;
        }
      `;
      document.head.appendChild(style);

      // Ajouter des points de direction
      const coordinates = routeData.coordinates;
      if (coordinates && coordinates.length > 0) {
        // Point de départ
        map.addSource('start-point', {
          type: 'geojson',
          data: {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: coordinates[0]
            },
            properties: {
              type: 'start'
            }
          }
        });

        map.addLayer({
          id: 'start-point',
          type: 'circle',
          source: 'start-point',
          paint: {
            'circle-radius': 8,
            'circle-color': '#10b981',
            'circle-stroke-width': 3,
            'circle-stroke-color': '#ffffff',
            'circle-opacity': 0.9
          }
        });

        // Point d'arrivée
        map.addSource('end-point', {
          type: 'geojson',
          data: {
            type: 'Feature',
            geometry: {
              type: 'Point',
              coordinates: coordinates[coordinates.length - 1]
            },
            properties: {
              type: 'end'
            }
          }
        });

        map.addLayer({
          id: 'end-point',
          type: 'circle',
          source: 'end-point',
          paint: {
            'circle-radius': 8,
            'circle-color': '#ef4444',
            'circle-stroke-width': 3,
            'circle-stroke-color': '#ffffff',
            'circle-opacity': 0.9
          }
        });
      }
    }

    // Cleanup function
    return () => {
      if (mapRef.current) {
        const map = mapRef.current;
        const layersToRemove = [
          'route-glow', 'route-background', 'route-main', 'route-highlight', 
          'route-pulse', 'start-point', 'end-point'
        ];
        const sourcesToRemove = ['route', 'route-animated', 'start-point', 'end-point'];
        
        layersToRemove.forEach(layerId => {
          if (map.getLayer && map.getLayer(layerId)) {
            map.removeLayer(layerId);
          }
        });
        
        sourcesToRemove.forEach(sourceId => {
          if (map.getSource && map.getSource(sourceId)) {
            map.removeSource(sourceId);
          }
        });
      }
    };
  }, [routeData]);

  const toggleFullscreen = () => {
    setIsFullscreen(!isFullscreen);
  };

  const refreshLocation = () => {
    setLastUpdate(new Date());
    // Actualiser la route si les deux positions sont disponibles
    if (driverLocation?.current_lat && driverLocation?.current_lng && deliveryLocation) {
      fetchRoute();
    }
  };

  const fetchRoute = async () => {
    const activeDriverLocation = realtimeDriverLocation || driverLocation;
    
    if (!activeDriverLocation?.current_lat || !activeDriverLocation?.current_lng || !deliveryLocation) {
      console.log('Missing data for route calculation:', {
        driverLat: activeDriverLocation?.current_lat,
        driverLng: activeDriverLocation?.current_lng,
        deliveryLat: deliveryLocation?.delivery_lat,
        deliveryLng: deliveryLocation?.delivery_lng
      });
      return;
    }

    setIsLoadingRoute(true);
    
    // Phase 1 : vers restaurant (ready_for_delivery)
    // Phase 2 : vers client (picked_up ou in_transit)
    const isPhase2 = deliveryLocation.status === 'picked_up' || deliveryLocation.status === 'in_transit';

    const targetLat = isPhase2 ? deliveryLocation.delivery_lat : RESTAURANT_COORDS.lat;
    const targetLng = isPhase2 ? deliveryLocation.delivery_lng : RESTAURANT_COORDS.lng;

    console.log(
      'Fetching route from',
      activeDriverLocation.current_lat,
      activeDriverLocation.current_lng,
      'to',
      targetLat,
      targetLng,
      'phase =',
      isPhase2 ? 'client' : 'restaurant',
    );
    
    try {
      const start = `${activeDriverLocation.current_lng},${activeDriverLocation.current_lat}`;
      const end = `${targetLng},${targetLat}`;
      
      const url = `https://api.mapbox.com/directions/v5/mapbox/driving/${start};${end}?geometries=geojson&overview=full&steps=true&access_token=${MAPBOX_CONFIG.ACCESS_TOKEN}`;
      console.log('Route API URL:', url);
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      console.log('Route API response:', data);
      
      if (data.routes && data.routes.length > 0) {
        const route = data.routes[0];
        console.log('Setting route data:', route.geometry);
        setRouteData(route.geometry);
        setRouteInfo(route);
        // Durée en secondes, convertie en minutes
        setEstimatedTime(Math.round(route.duration / 60));
        console.log('Route data set successfully');
      } else {
        console.error('No routes found in response:', data);
      }
    } catch (error) {
      console.error('Erreur lors du calcul de la route:', error);
    } finally {
      setIsLoadingRoute(false);
    }
  };

  const getDriverInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
  };

  const formatPrice = (price: number) => {
    return `${price.toLocaleString('fr-FR')} FCFA`;
  };

  const formatTime = (seconds: number) => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  const scrollToTop = () => {
    if (panelRef.current) {
      panelRef.current.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    }
  };

  const calculateDistance = (lat1: number, lng1: number, lat2: number, lng2: number) => {
    const R = 6371; // Rayon de la Terre en km
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = 
      Math.sin(dLat/2) * Math.sin(dLat/2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLng/2) * Math.sin(dLng/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  };

  if (!isOpen) return null;

  const distance = driverLocation && deliveryLocation 
    ? calculateDistance(
        driverLocation.current_lat, 
        driverLocation.current_lng,
        deliveryLocation.delivery_lat,
        deliveryLocation.delivery_lng
      )
    : null;

  return (
    <div className={`fixed inset-0 z-50 bg-gradient-to-br from-orange-50 via-red-50 to-yellow-50 ${isFullscreen ? 'p-0' : 'p-4'}`}>
      <div className="h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-orange-200 bg-white/95 backdrop-blur-sm shadow-lg">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-gradient-to-r from-orange-500 to-red-500 rounded-xl shadow-lg">
              <Truck className="h-8 w-8 text-white" />
            </div>
            <div>
              <h2 className="text-3xl font-bold bg-gradient-to-r from-orange-600 to-red-600 bg-clip-text text-transparent">
                Suivi en Temps Réel - Commande #{orderId.toString().slice(-6)}
              </h2>
              <p className="text-gray-600 text-lg flex items-center gap-2 mt-1">
                <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                Dernière mise à jour: {lastUpdate.toLocaleTimeString('fr-FR')}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-3">
             <Button
               variant="outline"
               size="sm"
               onClick={refreshLocation}
               disabled={isLoadingRoute}
               className="border-orange-300 text-orange-600 hover:bg-orange-50 shadow-md"
             >
               <RefreshCw className={`h-4 w-4 mr-2 ${isLoadingRoute ? 'animate-spin' : ''}`} />
               {isLoadingRoute ? 'Calcul route...' : 'Actualiser'}
             </Button>
            
            <Button
              variant="outline"
              size="sm"
              onClick={toggleFullscreen}
              className="border-blue-300 text-blue-600 hover:bg-blue-50 shadow-md"
            >
              {isFullscreen ? <X className="h-4 w-4" /> : <Navigation className="h-4 w-4" />}
            </Button>
            
            <Button
              variant="outline"
              size="sm"
              onClick={onClose}
              className="border-red-300 text-red-600 hover:bg-red-50 shadow-md"
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        </div>

        <div className="flex-1 flex">
           {/* Carte */}
           <div className="flex-1 relative">
             {/* Légende améliorée */}
             <div className="absolute top-6 left-6 z-10 bg-white/95 backdrop-blur-sm p-4 rounded-xl shadow-xl border border-orange-200">
               <h3 className="font-bold text-orange-700 mb-3 text-lg flex items-center gap-2">
                 <Map className="h-5 w-5" />
                 Légende
               </h3>
               <div className="space-y-3">
                 <div className="flex items-center gap-3">
                   <div className="w-4 h-4 bg-yellow-500 rounded-full shadow-md animate-pulse"></div>
                   <span className="text-sm font-medium text-gray-700">🚚 Livreur</span>
                 </div>
                 <div className="flex items-center gap-3">
                   <div className="w-4 h-4 bg-red-500 rounded-full shadow-md"></div>
                   <span className="text-sm font-medium text-gray-700">📍 Point de livraison</span>
                 </div>
               </div>
             </div>

             <Map
               {...viewport}
               onMove={evt => setViewport(evt.viewState)}
               onLoad={(evt) => {
                 mapRef.current = evt.target;
                 mapInstanceRef.current = evt.target;
                 console.log('Map loaded successfully, instance captured:', evt.target);
               }}
               onError={(error) => {
                 console.error('Mapbox error:', error);
               }}
               mapboxAccessToken={MAPBOX_CONFIG.ACCESS_TOKEN}
               style={{ width: '100%', height: '100%' }}
               mapStyle={MAPBOX_CONFIG.MAP_STYLES.STREETS}
               attributionControl={false}
               logoPosition="bottom-right"
             >
               {/* Marqueur du livreur avec animation */}
               {currentDriverLocation && currentDriverLocation.current_lat && currentDriverLocation.current_lng && (
                 <Marker
                   key={`driver-${currentDriverLocation.driver_id}`}
                   longitude={currentDriverLocation.current_lng}
                   latitude={currentDriverLocation.current_lat}
                   anchor="center"
                   onClick={() => setSelectedMarker('driver')}
                 >
                   <div className="relative">
                     {/* Animation de pulsation */}
                     <div className="absolute inset-0 w-12 h-12 bg-yellow-400 rounded-full animate-ping opacity-75"></div>
                     <div className="absolute inset-0 w-12 h-12 bg-yellow-300 rounded-full animate-pulse"></div>
                     
                     {/* Marqueur principal */}
                     <div className="relative w-12 h-12 bg-yellow-500 rounded-full border-4 border-white shadow-xl flex items-center justify-center">
                       <Truck className="h-6 w-6 text-white" />
                     </div>
                     
                     {/* Flèche avec animation */}
                     <div className="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-yellow-500 animate-pulse"></div>
                     
                     {/* Indicateur de mouvement */}
                     <div className="absolute -top-2 -right-2 w-4 h-4 bg-green-500 rounded-full border-2 border-white animate-pulse">
                       <div className="w-full h-full bg-green-400 rounded-full animate-ping"></div>
                     </div>
                   </div>
                 </Marker>
               )}

              {/* Marqueur du restaurant */}
              <Marker
                longitude={RESTAURANT_COORDS.lng}
                latitude={RESTAURANT_COORDS.lat}
                anchor="center"
                onClick={() => setSelectedMarker('restaurant')}
              >
                <div className="relative">
                  <div className="absolute inset-0 w-10 h-10 bg-orange-300 rounded-full opacity-60 animate-ping"></div>
                  <div className="relative w-10 h-10 bg-white rounded-full border-4 border-orange-500 shadow-md flex items-center justify-center">
                    <Utensils className="h-5 w-5 text-orange-600" />
                  </div>
                  <div className="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-3 border-r-3 border-t-4 border-transparent border-t-orange-500"></div>
                </div>
              </Marker>

              {/* Marqueur de livraison (client) */}
              {deliveryLocation && (
                <Marker
                  longitude={deliveryLocation.delivery_lng}
                  latitude={deliveryLocation.delivery_lat}
                  anchor="center"
                  onClick={() => setSelectedMarker('delivery')}
                >
                  <div className="relative">
                    {/* Animation de pulsation pour la destination */}
                    <div className="absolute inset-0 w-12 h-12 bg-red-400 rounded-full animate-ping opacity-60"></div>
                    <div className="absolute inset-0 w-12 h-12 bg-red-300 rounded-full animate-pulse"></div>
                    
                    {/* Marqueur principal avec effet de respiration */}
                    <div className="relative w-12 h-12 bg-red-600 rounded-full border-4 border-white shadow-xl flex items-center justify-center animate-pulse">
                      <MapPin className="h-6 w-6 text-white animate-bounce" />
                    </div>
                    
                    {/* Flèche avec animation */}
                    <div className="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-0 h-0 border-l-4 border-r-4 border-t-4 border-transparent border-t-red-600 animate-pulse"></div>
                    
                    {/* Indicateur d'urgence */}
                    <div className="absolute -top-2 -left-2 w-4 h-4 bg-orange-500 rounded-full border-2 border-white animate-ping">
                      <div className="w-full h-full bg-orange-400 rounded-full animate-pulse"></div>
                    </div>
                  </div>
                </Marker>
              )}

              {/* Popups */}
               {selectedMarker === 'driver' && driverLocation && (
                 <Popup
                   longitude={driverLocation.current_lng}
                   latitude={driverLocation.current_lat}
                   onClose={() => setSelectedMarker(null)}
                   closeButton={true}
                   closeOnClick={false}
                 >
                   <div className="p-2">
                     <h3 className="font-bold text-yellow-600">Livreur</h3>
                     <p className="font-medium">{driverLocation.name}</p>
                     <p className="text-sm text-muted-foreground">{driverLocation.phone}</p>
                     <p className="text-xs text-muted-foreground">
                       Dernière position: {new Date(driverLocation.last_update).toLocaleTimeString('fr-FR')}
                     </p>
                   </div>
                 </Popup>
               )}

               {selectedMarker === 'delivery' && deliveryLocation && (
                 <Popup
                   longitude={deliveryLocation.delivery_lng}
                   latitude={deliveryLocation.delivery_lat}
                   onClose={() => setSelectedMarker(null)}
                   closeButton={true}
                   closeOnClick={false}
                 >
                   <div className="p-2">
                     <h3 className="font-bold text-red-600">Point de Livraison</h3>
                     <p className="font-medium">{deliveryLocation.customer_name || 'Client anonyme'}</p>
                     <p className="text-sm">{deliveryLocation.delivery_address}</p>
                     <p className="text-sm text-muted-foreground">{deliveryLocation.customer_phone}</p>
                   </div>
                 </Popup>
               )}

               {selectedMarker === 'restaurant' && (
                 <Popup
                   longitude={RESTAURANT_COORDS.lng}
                   latitude={RESTAURANT_COORDS.lat}
                   onClose={() => setSelectedMarker(null)}
                   closeButton={true}
                   closeOnClick={false}
                 >
                   <div className="p-2">
                     <h3 className="font-bold text-orange-600">Restaurant</h3>
                     <p className="text-sm text-muted-foreground">
                       Point de départ de la commande
                     </p>
                     <p className="text-xs text-muted-foreground">
                       Phase: {deliveryLocation?.status === 'picked_up' || deliveryLocation?.status === 'in_transit'
                         ? 'Vers client'
                         : 'Vers restaurant'}
                     </p>
                   </div>
                 </Popup>
               )}

               {/* Tracé de route - sera ajouté via useEffect */}
            </Map>
          </div>

          {/* Panneau d'informations amélioré */}
          {!isFullscreen && (
            <div className="w-96 border-l border-orange-200 bg-white/95 backdrop-blur-sm flex flex-col h-full shadow-xl">
              {/* Header fixe du panneau */}
              <div className="flex-shrink-0 p-6 border-b border-orange-200 bg-gradient-to-r from-orange-50 to-red-50">
                <h3 className="text-2xl font-bold text-orange-700 flex items-center gap-3">
                  <div className="p-2 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
                    <Info className="h-6 w-6 text-white" />
                  </div>
                  Détails de la livraison
                </h3>
                <p className="text-gray-600 text-lg mt-2">Informations en temps réel</p>
              </div>
              
              {/* Contenu scrollable */}
              <div ref={panelRef} className="delivery-panel flex-1 p-4 space-y-4">
                {/* Informations de la commande */}
                {deliveryLocation && (
                  <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
                    <CardHeader className="bg-gradient-to-r from-orange-50 to-red-50 border-b border-orange-200">
                      <CardTitle className="text-lg text-orange-700 flex items-center gap-2">
                        <Package className="h-5 w-5" />
                        📦 Informations de la commande
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4 p-6">
                      <div className="flex items-center gap-3 p-3 bg-orange-50 rounded-lg border border-orange-200">
                        <div className="p-2 bg-orange-100 rounded-full">
                          <User className="h-4 w-4 text-orange-600" />
                        </div>
                        <span className="font-semibold text-orange-800">
                          {deliveryLocation.customer_name || "Client anonyme"}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-blue-50 rounded-lg border border-blue-200">
                        <div className="p-2 bg-blue-100 rounded-full">
                          <Phone className="h-4 w-4 text-blue-600" />
                        </div>
                        <span className="font-medium text-blue-800">{deliveryLocation.customer_phone}</span>
                      </div>
                      <div className="flex items-start gap-3 p-3 bg-green-50 rounded-lg border border-green-200">
                        <div className="p-2 bg-green-100 rounded-full mt-0.5">
                          <MapPin className="h-4 w-4 text-green-600" />
                        </div>
                        <div>
                          <p className="font-medium text-green-800">Adresse de livraison</p>
                          <p className="text-sm text-green-700">{deliveryLocation.delivery_address}</p>
                          <p className="text-xs text-green-600 mt-1">
                            Position sélectionnée ({deliveryLocation.delivery_lat.toFixed(6)}, {deliveryLocation.delivery_lng.toFixed(6)})
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-3 p-3 bg-yellow-50 rounded-lg border border-yellow-200">
                        <div className="p-2 bg-yellow-100 rounded-full">
                          <Clock className="h-4 w-4 text-yellow-600" />
                        </div>
                        <span className="font-medium text-yellow-800">
                          Livraison prévue: {new Date(deliveryLocation.estimated_delivery_time).toLocaleTimeString('fr-FR')}
                        </span>
                      </div>
                      <div className="pt-3 border-t border-orange-200">
                        <div className="flex justify-between items-center p-3 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg border border-green-200">
                          <span className="font-medium text-green-700">💰 Montant total</span>
                          <span className="font-bold text-green-800 text-lg">{formatPrice(deliveryLocation.total_amount)}</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                )}

                {/* Informations du livreur */}
                {driverLocation && (
                  <Card className="bg-white/90 backdrop-blur-sm border-orange-200 shadow-lg">
                    <CardHeader className="bg-gradient-to-r from-blue-50 to-cyan-50 border-b border-orange-200">
                      <CardTitle className="text-lg text-orange-700 flex items-center gap-2">
                        <Truck className="h-5 w-5" />
                        🚚 Informations du livreur
                      </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4 p-6">
                      <div className="flex items-center gap-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
                        <Avatar className="h-12 w-12">
                          <AvatarFallback className="bg-gradient-to-r from-blue-500 to-cyan-500 text-white font-bold text-lg">
                            {getDriverInitials(driverLocation.name)}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <h4 className="font-bold text-blue-800 text-lg">{driverLocation.name}</h4>
                          <p className="text-sm text-blue-600 font-medium">{driverLocation.phone}</p>
                        </div>
                      </div>
                      
                      {!driverLocation.current_lat || !driverLocation.current_lng ? (
                        <div className="p-4 border border-orange-200 bg-gradient-to-r from-orange-50 to-red-50 rounded-lg">
                          <div className="flex items-center gap-3">
                            <div className="p-2 bg-orange-100 rounded-full">
                              <AlertCircle className="h-5 w-5 text-orange-600" />
                            </div>
                            <p className="text-sm text-orange-800 font-medium">
                              Position du livreur non disponible. Le livreur doit activer la géolocalisation sur son appareil.
                            </p>
                          </div>
                        </div>
                      ) : (
                        <div className="space-y-3">
                          <div className="p-3 bg-green-50 rounded-lg border border-green-200">
                            <div className="flex items-center gap-2">
                              <Clock className="h-4 w-4 text-green-600" />
                              <span className="text-sm font-medium text-green-800">
                                Dernière position: {new Date(driverLocation.last_update).toLocaleTimeString('fr-FR')}
                              </span>
                            </div>
                          </div>
                          {distance && (
                            <div className="p-3 bg-purple-50 rounded-lg border border-purple-200">
                              <div className="flex items-center gap-2">
                                <MapPin className="h-4 w-4 text-purple-600" />
                                <span className="text-sm font-medium text-purple-800">
                                  Distance: {distance.toFixed(2)} km
                                </span>
                              </div>
                            </div>
                          )}
                        </div>
                      )}
                    </CardContent>
                  </Card>
                )}

                 {/* Informations de la route */}
                 {isLoadingRoute && (
                   <Card className="border-orange-200 bg-gradient-to-br from-orange-50 to-yellow-50">
                     <CardContent className="p-6">
                       <div className="flex items-center justify-center gap-3">
                         <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-orange-500"></div>
                         <p className="text-orange-700 font-medium">Calcul de la route en cours...</p>
                       </div>
                     </CardContent>
                   </Card>
                 )}

                 {routeData && routeInfo && (
                   <Card className="border-blue-200 bg-gradient-to-br from-blue-50 to-indigo-50">
                     <CardHeader className="pb-3">
                       <CardTitle className="text-lg flex items-center gap-2">
                         <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                         Informations de la route
                       </CardTitle>
                     </CardHeader>
                     <CardContent>
                       <div className="space-y-4">
                         {/* Compteur de temps estimé */}
                         <div className="bg-white rounded-lg p-4 border border-blue-100">
                           <div className="flex items-center justify-between">
                             <div className="flex items-center gap-3">
                               <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
                                 <Clock className="h-5 w-5 text-blue-600" />
                               </div>
                               <div>
                                 <p className="text-sm font-medium text-gray-900">Temps estimé</p>
                                 <p className="text-xs text-gray-500">Temps de trajet</p>
                               </div>
                             </div>
                             <div className="text-right">
                               <p className="text-2xl font-bold text-blue-600">
                                 {estimatedTime ? `${estimatedTime} min` : '--'}
                               </p>
                               <p className="text-xs text-gray-500">
                                 {routeInfo.distance ? `${(routeInfo.distance / 1000).toFixed(1)} km` : ''}
                               </p>
                             </div>
                           </div>
                         </div>

                         {/* Compteur de temps écoulé */}
                         <div className="bg-gradient-to-r from-orange-50 to-red-50 rounded-lg p-4 border border-orange-200">
                           <div className="flex items-center justify-between">
                             <div className="flex items-center gap-3">
                               <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center">
                                 <RefreshCw className="h-5 w-5 text-orange-600 animate-spin" />
                               </div>
                               <div>
                                 <p className="text-sm font-medium text-gray-900">Temps écoulé</p>
                                 <p className="text-xs text-gray-500">Depuis le début du suivi</p>
                               </div>
                             </div>
                             <div className="text-right">
                               <p className="text-2xl font-bold text-orange-600">
                                 {formatTime(timeElapsed)}
                               </p>
                               <p className="text-xs text-gray-500">
                                 {timeElapsed > 0 ? 'En cours...' : 'Démarré'}
                               </p>
                             </div>
                           </div>
                         </div>

                         {/* Détails de la route */}
                         <div className="grid grid-cols-2 gap-3">
                           <div className="bg-white rounded-lg p-3 border border-blue-100">
                             <div className="flex items-center gap-2">
                               <Navigation className="h-4 w-4 text-blue-500" />
                               <span className="text-sm font-medium">Distance route</span>
                             </div>
                             <p className="text-lg font-bold text-blue-600 mt-1">
                               {routeInfo.distance ? `${(routeInfo.distance / 1000).toFixed(1)} km` : '--'}
                             </p>
                           </div>
                           <div className="bg-white rounded-lg p-3 border border-blue-100">
                             <div className="flex items-center gap-2">
                               <Truck className="h-4 w-4 text-blue-500" />
                               <span className="text-sm font-medium">Distance directe</span>
                             </div>
                             <p className="text-lg font-bold text-blue-600 mt-1">
                               {distance ? `${distance.toFixed(1)} km` : '--'}
                             </p>
                           </div>
                         </div>

                         {/* Indicateur de statut */}
                         <div className="flex items-center gap-2 p-2 bg-green-50 rounded-lg border border-green-200">
                           <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                           <span className="text-sm text-green-700 font-medium">
                             Route optimisée pour véhicules
                           </span>
                         </div>
                       </div>
                     </CardContent>
                   </Card>
                 )}

                 {/* Statut de la livraison */}
                 <Card>
                   <CardHeader>
                     <CardTitle className="text-lg">Statut de la livraison</CardTitle>
                   </CardHeader>
                   <CardContent>
                     <div className="flex items-center gap-2">
                       <Badge variant="default" className="bg-green-100 text-green-800">
                         En cours de livraison
                       </Badge>
                     </div>
                     {distance && (
                       <p className="text-sm text-muted-foreground mt-2">
                         Le livreur se trouve à {distance.toFixed(2)} km du point de livraison
                       </p>
                     )}
                   </CardContent>
                 </Card>
               </div>
               
               {/* Bouton retour en haut avec animation */}
               {showScrollTop && (
                 <div className="fixed bottom-6 right-6 z-50 scroll-top-button">
                   <Button
                     onClick={scrollToTop}
                     size="sm"
                     className="rounded-full shadow-lg bg-blue-600 hover:bg-blue-700 hover:scale-110 transition-transform duration-200 animate-pulse"
                   >
                     <Navigation className="h-4 w-4 rotate-180" />
                   </Button>
                 </div>
               )}
             </div>
           )}
        </div>
      </div>
    </div>
  );
};

export default LiveDeliveryMap;

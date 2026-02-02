import { useState, useEffect, useRef } from 'react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { 
  MapPin, 
  Search, 
  Clock, 
  DollarSign, 
  Navigation,
  Building2,
  Home,
  ShoppingBag,
  Factory,
  Church,
  School,
  Hotel,
  Utensils
} from 'lucide-react';
import { locationService, DeliveryLocation, Landmark } from '@/services/locationService';
import { cn } from '@/lib/utils';

interface LocationSearchProps {
  onLocationSelected: (location: {
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    delivery_fee: number;
    estimated_time: number;
  }) => void;
  selectedLocation?: {
    latitude: number;
    longitude: number;
  } | null;
  className?: string;
}

const LocationSearch = ({ 
  onLocationSelected, 
  selectedLocation, 
  className 
}: LocationSearchProps) => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<{
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
  }>({ locations: [], landmarks: [], nominatimResults: [] });
  const [loading, setLoading] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);
  const resultsRef = useRef<HTMLDivElement>(null);

  // Recherche avec debounce
  useEffect(() => {
    const timeoutId = setTimeout(async () => {
      if (query.length >= 2) {
        setLoading(true);
        try {
          const searchResults = await locationService.smartSearch(query, 8);
          setResults(searchResults);
          setShowResults(true);
          setSelectedIndex(-1);
        } catch (error) {
          console.error('Erreur de recherche:', error);
        } finally {
          setLoading(false);
        }
      } else {
        setResults({ locations: [], landmarks: [], nominatimResults: [] });
        setShowResults(false);
      }
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [query]);

  // Gestion du clavier
  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (!showResults) return;

    const totalDbResults = results.locations.length + results.landmarks.length;
    const totalResults = totalDbResults + results.nominatimResults.length;

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setSelectedIndex(prev => 
          prev < totalResults - 1 ? prev + 1 : 0
        );
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelectedIndex(prev => 
          prev > 0 ? prev - 1 : totalResults - 1
        );
        break;
      case 'Enter':
        e.preventDefault();
        if (selectedIndex >= 0) {
          handleResultClick(selectedIndex);
        }
        break;
      case 'Escape':
        setShowResults(false);
        setSelectedIndex(-1);
        break;
    }
  };

  const handleResultClick = (index: number) => {
    const totalDbResults = results.locations.length + results.landmarks.length;
    let selectedItem: any = null;
    let isLandmark = false;
    let isNominatim = false;

    if (index < results.locations.length) {
      selectedItem = results.locations[index];
    } else if (index < totalDbResults) {
      selectedItem = results.landmarks[index - results.locations.length];
      isLandmark = true;
    } else {
      // Résultat Nominatim
      selectedItem = results.nominatimResults[index - totalDbResults];
      isNominatim = true;
    }

    if (selectedItem) {
      if (isNominatim) {
        // Pour les résultats Nominatim, calculer les frais de livraison
        locationService.getDeliveryFee(selectedItem.latitude, selectedItem.longitude)
          .then(feeResult => {
            const locationData = {
              name: selectedItem.name,
              address: selectedItem.address,
              latitude: selectedItem.latitude,
              longitude: selectedItem.longitude,
              delivery_fee: feeResult?.delivery_fee || 1000,
              estimated_time: feeResult?.estimated_time || 25
            };
            onLocationSelected(locationData);
            setQuery(locationData.address);
            setShowResults(false);
            setSelectedIndex(-1);
          })
          .catch(error => {
            console.error('Erreur lors du calcul des frais:', error);
            // Utiliser des valeurs par défaut en cas d'erreur
            const locationData = {
              name: selectedItem.name,
              address: selectedItem.address,
              latitude: selectedItem.latitude,
              longitude: selectedItem.longitude,
              delivery_fee: 1000,
              estimated_time: 25
            };
            onLocationSelected(locationData);
            setQuery(locationData.address);
            setShowResults(false);
            setSelectedIndex(-1);
          });
        return;
      } else {
        // Logique existante pour locations et landmarks
        const locationData = {
          name: selectedItem.name,
          address: locationService.formatAddress(
            isLandmark ? 
              results.locations.find(l => l.id === (selectedItem as Landmark).delivery_location_id) || 
              results.locations[0] : 
              selectedItem as DeliveryLocation,
            isLandmark ? selectedItem as Landmark : undefined
          ),
          latitude: selectedItem.latitude,
          longitude: selectedItem.longitude,
          delivery_fee: (selectedItem as DeliveryLocation).delivery_fee || 0,
          estimated_time: (selectedItem as DeliveryLocation).estimated_delivery_time || 20
        };

        onLocationSelected(locationData);
        setQuery(locationData.address);
        setShowResults(false);
        setSelectedIndex(-1);
      }
    }
  };

  const getIconForLocation = (location: DeliveryLocation | Landmark) => {
    if ('zone_type' in location) {
      // C'est une DeliveryLocation
      switch (location.zone_type) {
        case 'quartier': return <Home className="h-4 w-4" />;
        case 'zone_commerciale': return <ShoppingBag className="h-4 w-4" />;
        case 'zone_industrielle': return <Factory className="h-4 w-4" />;
        case 'zone_residentielle': return <Building2 className="h-4 w-4" />;
        case 'village': return <Home className="h-4 w-4" />;
        case 'lieu_public': return <MapPin className="h-4 w-4" />;
        default: return <MapPin className="h-4 w-4" />;
      }
    } else {
      // C'est un Landmark
      switch (location.landmark_type) {
        case 'hotel': return <Hotel className="h-4 w-4" />;
        case 'restaurant': return <Utensils className="h-4 w-4" />;
        case 'ecole': return <School className="h-4 w-4" />;
        case 'eglise':
        case 'mosquee': return <Church className="h-4 w-4" />;
        default: return <MapPin className="h-4 w-4" />;
      }
    }
  };

  const getZoneTypeLabel = (zoneType: string) => {
    const labels: Record<string, string> = {
      'quartier': 'Quartier',
      'zone_commerciale': 'Zone Commerciale',
      'zone_residentielle': 'Zone Résidentielle',
      'zone_industrielle': 'Zone Industrielle',
      'village': 'Village',
      'lieu_public': 'Lieu Public'
    };
    return labels[zoneType] || zoneType;
  };

  const getLandmarkTypeLabel = (landmarkType: string) => {
    const labels: Record<string, string> = {
      'hotel': 'Hôtel',
      'restaurant': 'Restaurant',
      'banque': 'Banque',
      'pharmacie': 'Pharmacie',
      'hopital': 'Hôpital',
      'ecole': 'École',
      'eglise': 'Église',
      'mosquee': 'Mosquée',
      'marche': 'Marché',
      'station_service': 'Station Service',
      'bureau': 'Bureau',
      'autre': 'Autre'
    };
    return labels[landmarkType] || landmarkType;
  };

  return (
    <div className={cn("relative w-full", className)}>
      {/* Barre de recherche */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
        <Input
          ref={inputRef}
          type="text"
          placeholder="Rechercher un quartier, une adresse ou un point de repère..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => {
            if (results.locations.length > 0 || results.landmarks.length > 0 || results.nominatimResults.length > 0) {
              setShowResults(true);
            }
          }}
          className="pl-10 pr-4 py-3 text-base"
        />
        {loading && (
          <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
            <div className="animate-spin rounded-full h-4 w-4 border-2 border-primary border-t-transparent" />
          </div>
        )}
      </div>

      {/* Résultats de recherche */}
      {showResults && (results.locations.length > 0 || results.landmarks.length > 0 || results.nominatimResults.length > 0) && (
        <Card className="absolute top-full left-0 right-0 z-50 mt-2 max-h-80 overflow-y-auto shadow-lg border-2">
          <CardContent className="p-0">
            {/* Locations */}
            {results.locations.length > 0 && (
              <>
                <div className="px-4 py-2 bg-muted/50 text-sm font-medium text-muted-foreground border-b">
                  📍 Quartiers et Zones ({results.locations.length})
                </div>
                {results.locations.map((location, index) => (
                  <div
                    key={location.id}
                    className={cn(
                      "px-4 py-3 cursor-pointer hover:bg-muted/50 transition-colors border-b last:border-b-0",
                      selectedIndex === index && "bg-primary/10"
                    )}
                    onClick={() => handleResultClick(index)}
                  >
                    <div className="flex items-start gap-3">
                      <div className="text-primary mt-0.5">
                        {getIconForLocation(location)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <span className="font-medium text-sm">{location.name}</span>
                          <Badge variant="outline" className="text-xs">
                            {getZoneTypeLabel(location.zone_type)}
                          </Badge>
                        </div>
                        <div className="text-xs text-muted-foreground mb-2">
                          {location.district}
                        </div>
                        <div className="flex items-center gap-4 text-xs">
                          <div className="flex items-center gap-1 text-green-600">
                            <DollarSign className="h-3 w-3" />
                            {location.delivery_fee === 0 ? 'Gratuit' : `${location.delivery_fee} FCFA`}
                          </div>
                          <div className="flex items-center gap-1 text-blue-600">
                            <Clock className="h-3 w-3" />
                            {location.estimated_delivery_time} min
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </>
            )}

            {/* Séparateur entre locations et landmarks */}
            {results.locations.length > 0 && results.landmarks.length > 0 && (
              <Separator />
            )}

            {/* Landmarks */}
            {results.landmarks.length > 0 && (
              <>
                <div className="px-4 py-2 bg-muted/50 text-sm font-medium text-muted-foreground border-b">
                  🏢 Points de Repère ({results.landmarks.length})
                </div>
                {results.landmarks.map((landmark, index) => {
                  const adjustedIndex = index + results.locations.length;
                  return (
                    <div
                      key={landmark.id}
                      className={cn(
                        "px-4 py-3 cursor-pointer hover:bg-muted/50 transition-colors border-b last:border-b-0",
                        selectedIndex === adjustedIndex && "bg-primary/10"
                      )}
                      onClick={() => handleResultClick(adjustedIndex)}
                    >
                      <div className="flex items-start gap-3">
                        <div className="text-primary mt-0.5">
                          {getIconForLocation(landmark)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium text-sm">{landmark.name}</span>
                            <Badge variant="secondary" className="text-xs">
                              {getLandmarkTypeLabel(landmark.landmark_type)}
                            </Badge>
                          </div>
                          {landmark.address && (
                            <div className="text-xs text-muted-foreground mb-2">
                              {landmark.address}
                            </div>
                          )}
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <Navigation className="h-3 w-3" />
                            {landmark.latitude.toFixed(4)}, {landmark.longitude.toFixed(4)}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </>
            )}

            {/* Séparateur avant les résultats Nominatim */}
            {(results.locations.length > 0 || results.landmarks.length > 0) && results.nominatimResults.length > 0 && (
              <Separator />
            )}

            {/* Résultats Nominatim (OpenStreetMap) */}
            {results.nominatimResults.length > 0 && (
              <>
                <div className="px-4 py-2 bg-muted/50 text-sm font-medium text-muted-foreground border-b">
                  🗺️ Adresses OpenStreetMap ({results.nominatimResults.length})
                </div>
                {results.nominatimResults.map((result, index) => {
                  const adjustedIndex = index + results.locations.length + results.landmarks.length;
                  return (
                    <div
                      key={`nominatim-${index}`}
                      className={cn(
                        "px-4 py-3 cursor-pointer hover:bg-muted/50 transition-colors border-b last:border-b-0",
                        selectedIndex === adjustedIndex && "bg-primary/10"
                      )}
                      onClick={() => handleResultClick(adjustedIndex)}
                    >
                      <div className="flex items-start gap-3">
                        <div className="text-primary mt-0.5">
                          <MapPin className="h-4 w-4" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium text-sm">{result.name}</span>
                            <Badge variant="outline" className="text-xs">
                              {result.type}
                            </Badge>
                          </div>
                          <div className="text-xs text-muted-foreground mb-2">
                            {result.address}
                          </div>
                          <div className="flex items-center gap-1 text-xs text-muted-foreground">
                            <Navigation className="h-3 w-3" />
                            {result.latitude.toFixed(4)}, {result.longitude.toFixed(4)}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </>
            )}
          </CardContent>
        </Card>
      )}

      {/* Message si aucun résultat */}
      {showResults && query.length >= 2 && results.locations.length === 0 && results.landmarks.length === 0 && results.nominatimResults.length === 0 && !loading && (
        <Card className="absolute top-full left-0 right-0 z-50 mt-2 shadow-lg border-2">
          <CardContent className="p-4 text-center text-muted-foreground">
            <MapPin className="h-8 w-8 mx-auto mb-2 opacity-50" />
            <p>Aucun résultat trouvé pour "{query}"</p>
            <p className="text-xs mt-1">Essayez avec d'autres mots-clés</p>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default LocationSearch;





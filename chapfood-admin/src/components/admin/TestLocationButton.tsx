import { useState } from "react";
import { Button } from "@/components/ui/button";
import { MapPin, Loader2 } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";

interface TestLocationButtonProps {
  driverId: number;
  onLocationUpdated?: () => void;
}

const TestLocationButton = ({ driverId, onLocationUpdated }: TestLocationButtonProps) => {
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const addTestLocation = async () => {
    try {
      setLoading(true);
      
      // Coordonnées de test à Bassam (Côte d'Ivoire)
      const testCoordinates = {
        current_lat: 5.2111 + (Math.random() - 0.5) * 0.005, // Bassam avec variation
        current_lng: -3.7369 + (Math.random() - 0.5) * 0.005
      };

      const { error } = await supabase
        .from('drivers')
        .update({
          current_lat: testCoordinates.current_lat,
          current_lng: testCoordinates.current_lng,
          updated_at: new Date().toISOString()
        })
        .eq('id', driverId);

      if (error) throw error;

      toast({
        title: "Position de test ajoutée",
        description: `Coordonnées GPS ajoutées pour le livreur #${driverId}`,
      });

      if (onLocationUpdated) {
        onLocationUpdated();
      }
    } catch (error) {
      console.error('Erreur lors de l\'ajout de la position:', error);
      toast({
        title: "Erreur",
        description: "Impossible d'ajouter la position de test",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Button
      onClick={addTestLocation}
      disabled={loading}
      size="sm"
      variant="outline"
      className="text-xs"
    >
      {loading ? (
        <Loader2 className="h-3 w-3 mr-1 animate-spin" />
      ) : (
        <MapPin className="h-3 w-3 mr-1" />
      )}
      {loading ? "Ajout..." : "Ajouter position test"}
    </Button>
  );
};

export default TestLocationButton;

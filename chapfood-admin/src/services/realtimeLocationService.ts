import React from 'react';
import { supabase } from '@/integrations/supabase/client';

interface DriverLocation {
  id: number;
  name: string;
  current_lat: number | null;
  current_lng: number | null;
  updated_at: string;
  is_available: boolean;
  is_active: boolean;
}

interface LocationUpdateCallback {
  (driverLocation: DriverLocation): void;
}

class RealtimeLocationService {
  private intervalId: NodeJS.Timeout | null = null;
  private callbacks: LocationUpdateCallback[] = [];
  private lastUpdateTime: Date = new Date();
  private isRunning = false;
  private lastDriverData: Map<number, DriverLocation> = new Map();

  // Démarrer la surveillance en temps réel
  startRealtimeUpdates(intervalMs: number = 15000) { // 15 secondes par défaut (réduit la fréquence)
    if (this.isRunning) return;

    this.isRunning = true;
    console.log('🔄 Démarrage de la surveillance GPS temps réel...');

    // Récupération immédiate
    this.fetchDriverLocations();

    // Puis toutes les X secondes
    this.intervalId = setInterval(() => {
      this.fetchDriverLocations();
    }, intervalMs);
  }

  // Arrêter la surveillance
  stopRealtimeUpdates() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.isRunning = false;
    console.log('⏹️ Arrêt de la surveillance GPS temps réel');
  }

  // S'abonner aux mises à jour de position
  subscribe(callback: LocationUpdateCallback) {
    this.callbacks.push(callback);
    return () => {
      this.callbacks = this.callbacks.filter(cb => cb !== callback);
    };
  }

  // Récupérer toutes les positions des livreurs
  private async fetchDriverLocations() {
    try {
      const { data, error } = await supabase
        .from('drivers')
        .select('id, name, current_lat, current_lng, updated_at, is_available, is_active')
        .eq('is_active', true)
        .not('current_lat', 'is', null)
        .not('current_lng', 'is', null);

      if (error) {
        console.error('❌ Erreur lors de la récupération des positions:', error);
        return;
      }

      if (data && data.length > 0) {
        const now = new Date();
        const timeSinceLastUpdate = now.getTime() - this.lastUpdateTime.getTime();
        
        // Vérifier si les données ont vraiment changé pour éviter les notifications inutiles
        let hasChanges = false;
        const changedDrivers: DriverLocation[] = [];

        data.forEach(driver => {
          const driverData = driver as DriverLocation;
          const lastData = this.lastDriverData.get(driver.id);
          
          // Comparer les positions (avec une tolérance de 0.0001 degré ≈ 11 mètres)
          const positionChanged = !lastData || 
            Math.abs(lastData.current_lat - driverData.current_lat) > 0.0001 ||
            Math.abs(lastData.current_lng - driverData.current_lng) > 0.0001;
          
          if (positionChanged) {
            hasChanges = true;
            changedDrivers.push(driverData);
            this.lastDriverData.set(driver.id, driverData);
          }
        });

        if (hasChanges) {
          console.log(`📍 ${changedDrivers.length} positions mises à jour (${data.length} total)`);
          
          // Notifier seulement pour les positions qui ont changé
          changedDrivers.forEach(driver => {
            this.callbacks.forEach(callback => {
              callback(driver);
            });
          });

          this.lastUpdateTime = now;
        }
      }
    } catch (error) {
      console.error('❌ Erreur dans fetchDriverLocations:', error);
    }
  }

  // Récupérer la position d'un livreur spécifique
  async getDriverLocation(driverId: number): Promise<DriverLocation | null> {
    try {
      const { data, error } = await supabase
        .from('drivers')
        .select('id, name, current_lat, current_lng, updated_at, is_available, is_active')
        .eq('id', driverId)
        .single();

      if (error) {
        console.error(`❌ Erreur position livreur ${driverId}:`, error);
        return null;
      }

      return data as DriverLocation;
    } catch (error) {
      console.error(`❌ Erreur getDriverLocation pour ${driverId}:`, error);
      return null;
    }
  }

  // Vérifier si le service est actif
  isActive(): boolean {
    return this.isRunning;
  }

  // Obtenir le temps de la dernière mise à jour
  getLastUpdateTime(): Date {
    return this.lastUpdateTime;
  }
}

// Instance singleton
export const realtimeLocationService = new RealtimeLocationService();

// Hook React pour utiliser le service
export const useRealtimeLocation = (driverId?: number) => {
  const [driverLocation, setDriverLocation] = React.useState<DriverLocation | null>(null);
  const [lastUpdate, setLastUpdate] = React.useState<Date | null>(null);
  const [isConnected, setIsConnected] = React.useState(false);
  const lastLocationRef = React.useRef<DriverLocation | null>(null);

  React.useEffect(() => {
    // S'abonner aux mises à jour
    const unsubscribe = realtimeLocationService.subscribe((location) => {
      if (!driverId || location.id === driverId) {
        // Éviter les mises à jour si la position n'a pas vraiment changé
        const lastLocation = lastLocationRef.current;
        const positionChanged = !lastLocation || 
          Math.abs(lastLocation.current_lat - location.current_lat) > 0.0001 ||
          Math.abs(lastLocation.current_lng - location.current_lng) > 0.0001;
        
        if (positionChanged) {
          setDriverLocation(location);
          setLastUpdate(new Date());
          setIsConnected(true);
          lastLocationRef.current = location;
        }
      }
    });

    // Récupérer la position initiale si un driverId est spécifié
    if (driverId) {
      realtimeLocationService.getDriverLocation(driverId).then(location => {
        if (location) {
          setDriverLocation(location);
          setLastUpdate(new Date());
          lastLocationRef.current = location;
        }
      });
    }

    // Démarrer les mises à jour si pas déjà actif
    if (!realtimeLocationService.isActive()) {
      realtimeLocationService.startRealtimeUpdates();
    }

    return () => {
      unsubscribe();
    };
  }, [driverId]);

  React.useEffect(() => {
    // Vérifier la connexion toutes les 60 secondes (réduit la fréquence)
    const checkConnection = setInterval(() => {
      const lastUpdate = realtimeLocationService.getLastUpdateTime();
      const timeSinceUpdate = new Date().getTime() - lastUpdate.getTime();
      setIsConnected(timeSinceUpdate < 120000); // Connecté si mise à jour < 2 minutes
    }, 60000);

    return () => clearInterval(checkConnection);
  }, []);

  return {
    driverLocation,
    lastUpdate,
    isConnected,
    startUpdates: () => realtimeLocationService.startRealtimeUpdates(),
    stopUpdates: () => realtimeLocationService.stopRealtimeUpdates(),
    isActive: realtimeLocationService.isActive()
  };
};


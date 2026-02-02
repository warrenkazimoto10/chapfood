import { AlertTriangle, Shield, UserCheck } from "lucide-react";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { useAdminAuth } from "@/hooks/useAdminAuth";

interface PermissionErrorProps {
  requiredRole?: 'admin_general' | 'cuisine';
  message?: string;
  onRetry?: () => void;
}

export const PermissionError = ({ 
  requiredRole, 
  message = "Vous n'avez pas les permissions nécessaires pour effectuer cette action.",
  onRetry 
}: PermissionErrorProps) => {
  const { admin } = useAdminAuth();

  const getRoleDisplayName = (role: string) => {
    switch (role) {
      case 'admin_general':
        return 'Administrateur Général';
      case 'cuisine':
        return 'Personnel de Cuisine';
      default:
        return role;
    }
  };

  const getCurrentRoleDisplay = () => {
    if (!admin) return 'Non connecté';
    return getRoleDisplayName(admin.role);
  };

  return (
    <Alert variant="destructive" className="max-w-md mx-auto">
      <AlertTriangle className="h-4 w-4" />
      <AlertTitle>Accès Refusé</AlertTitle>
      <AlertDescription className="space-y-3">
        <p>{message}</p>
        
        <div className="space-y-2 text-sm">
          <div className="flex items-center gap-2">
            <Shield className="h-4 w-4" />
            <span>Rôle requis: {requiredRole ? getRoleDisplayName(requiredRole) : 'Admin ou Cuisine'}</span>
          </div>
          
          <div className="flex items-center gap-2">
            <UserCheck className="h-4 w-4" />
            <span>Votre rôle: {getCurrentRoleDisplay()}</span>
          </div>
        </div>

        {onRetry && (
          <Button 
            variant="outline" 
            size="sm" 
            onClick={onRetry}
            className="mt-2"
          >
            Réessayer
          </Button>
        )}
      </AlertDescription>
    </Alert>
  );
};

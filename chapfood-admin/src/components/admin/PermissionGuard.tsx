import { ReactNode } from 'react';
import { useStockPermissions } from '@/hooks/useStockPermissions';

interface PermissionGuardProps {
  children: ReactNode;
  requiredPermission: 'create' | 'edit' | 'delete' | 'view';
  fallback?: ReactNode;
}

export const PermissionGuard = ({ 
  children, 
  requiredPermission, 
  fallback = null 
}: PermissionGuardProps) => {
  const permissions = useStockPermissions();

  const hasPermission = permissions[`can${requiredPermission.charAt(0).toUpperCase() + requiredPermission.slice(1)}`];

  if (!hasPermission) {
    return <>{fallback}</>;
  }

  return <>{children}</>;
};

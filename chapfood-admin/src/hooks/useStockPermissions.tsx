import { useAdminAuth } from './useAdminAuth';

export interface StockPermissions {
  canCreate: boolean;
  canEdit: boolean;
  canDelete: boolean;
  canView: boolean;
  isAdmin: boolean;
  isKitchen: boolean;
}

export const useStockPermissions = (): StockPermissions => {
  const { admin } = useAdminAuth();

  const isAdmin = !!admin && admin.role === 'admin_general';
  const isKitchen = !!admin && admin.role === 'cuisine';
  const hasPermission = isAdmin || isKitchen;

  return {
    canCreate: hasPermission,
    canEdit: hasPermission,
    canDelete: hasPermission,
    canView: hasPermission,
    isAdmin,
    isKitchen,
  };
};

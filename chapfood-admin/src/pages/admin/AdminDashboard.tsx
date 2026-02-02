import React, { useEffect, useState } from 'react';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { Navigate } from 'react-router-dom';
import { KitchenDashboard } from '@/components/admin/KitchenDashboard';
import { GeneralAdminDashboard } from '@/components/admin/GeneralAdminDashboard';
import ModernAdminDashboard from './ModernAdminDashboard';

const AdminDashboard = () => {
  const { admin, loading } = useAdminAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (!admin) {
    return <Navigate to="/admin/login" replace />;
  }

  return (
    <div className="min-h-screen bg-background">
      {admin.role === 'cuisine' ? (
        <KitchenDashboard />
      ) : (
        <ModernAdminDashboard />
      )}
    </div>
  );
};

export default AdminDashboard;
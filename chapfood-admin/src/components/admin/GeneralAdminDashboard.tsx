import React from 'react';
import { useAdminAuth } from '@/hooks/useAdminAuth';
import { AdminDashboard } from '@/components/admin/AdminDashboard';

export const GeneralAdminDashboard = () => {
  const { admin, logout } = useAdminAuth();

  return <AdminDashboard />; 
};
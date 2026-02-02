import React, { useState, useEffect, createContext, useContext } from 'react';
import { supabase } from '@/integrations/supabase/client';

export interface AdminUser {
  id: string;
  email: string;
  role: 'admin_general' | 'cuisine';
  full_name?: string;
}

interface AdminAuthContextType {
  admin: AdminUser | null;
  login: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => void;
  loading: boolean;
}

const AdminAuthContext = createContext<AdminAuthContextType | undefined>(undefined);

export const useAdminAuth = () => {
  const context = useContext(AdminAuthContext);
  if (context === undefined) {
    throw new Error('useAdminAuth must be used within an AdminAuthProvider');
  }
  return context;
};

export const useAdminAuthProvider = () => {
  const [admin, setAdmin] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const adminData = localStorage.getItem('admin_user');
    if (adminData) {
      try {
        setAdmin(JSON.parse(adminData));
      } catch (error) {
        localStorage.removeItem('admin_user');
      }
    }
    setLoading(false);
  }, []);

  const login = async (email: string, password: string) => {
    try {
      const { data, error } = await supabase.rpc('authenticate_admin', {
        email_input: email,
        password_input: password
      });

      if (error) {
        return { success: false, error: 'Erreur de connexion' };
      }

      if (!data || data.length === 0) {
        return { success: false, error: 'Email ou mot de passe incorrect' };
      }

      const adminUser: AdminUser = {
        id: data[0].admin_id,
        email: data[0].admin_email,
        role: data[0].admin_role as 'admin_general' | 'cuisine',
        full_name: data[0].admin_name
      };

      setAdmin(adminUser);
      localStorage.setItem('admin_user', JSON.stringify(adminUser));
      
      return { success: true };
    } catch (error) {
      return { success: false, error: 'Erreur de connexion au serveur' };
    }
  };

  const logout = () => {
    setAdmin(null);
    localStorage.removeItem('admin_user');
  };

  return {
    admin,
    login,
    logout,
    loading
  };
};

interface AdminAuthProviderProps {
  children: React.ReactNode;
}

export const AdminAuthProvider: React.FC<AdminAuthProviderProps> = ({ children }) => {
  const authValue = useAdminAuthProvider();
  return (
    <AdminAuthContext.Provider value={authValue}>
      {children}
    </AdminAuthContext.Provider>
  );
};
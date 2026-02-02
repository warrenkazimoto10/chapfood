import { supabase } from '@/integrations/supabase/client';
import { useStockPermissions } from '@/hooks/useStockPermissions';

export interface MenuItem {
  id: number;
  name: string;
  description: string | null;
  price: number;
  category_id: number | null;
  is_available: boolean;
  is_popular: boolean;
  has_extra: boolean;
  has_garniture: boolean;
  image_url: string | null;
  created_at: string;
}

export interface Category {
  id: number;
  name: string;
  description: string | null;
  is_active: boolean;
  image_url: string | null;
  created_at: string;
}

export interface Supplement {
  id: number;
  name: string;
  description: string | null;
  price: number;
  is_available: boolean;
  created_at: string;
}

export class StockService {
  private static checkPermissions(permissions: ReturnType<typeof useStockPermissions>) {
    if (!permissions.canView) {
      throw new Error('Accès refusé: permissions insuffisantes');
    }
  }

  // Opérations sur les articles du menu
  static async getMenuItems() {
    const { data, error } = await supabase
      .from('menu_items')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  static async createMenuItem(item: Omit<MenuItem, 'id' | 'created_at'>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canCreate) {
      throw new Error('Accès refusé: permission de création requise');
    }

    const { data, error } = await supabase
      .from('menu_items')
      .insert([item])
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async updateMenuItem(id: number, updates: Partial<MenuItem>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canEdit) {
      throw new Error('Accès refusé: permission de modification requise');
    }

    const { data, error } = await supabase
      .from('menu_items')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async deleteMenuItem(id: number, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canDelete) {
      throw new Error('Accès refusé: permission de suppression requise');
    }

    const { error } = await supabase
      .from('menu_items')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  }

  // Opérations sur les catégories
  static async getCategories() {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  static async createCategory(category: Omit<Category, 'id' | 'created_at'>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canCreate) {
      throw new Error('Accès refusé: permission de création requise');
    }

    const { data, error } = await supabase
      .from('categories')
      .insert([category])
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async updateCategory(id: number, updates: Partial<Category>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canEdit) {
      throw new Error('Accès refusé: permission de modification requise');
    }

    const { data, error } = await supabase
      .from('categories')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async deleteCategory(id: number, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canDelete) {
      throw new Error('Accès refusé: permission de suppression requise');
    }

    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  }

  // Opérations sur les suppléments/garnitures
  static async getSupplements() {
    const { data, error } = await supabase
      .from('supplements')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  static async createSupplement(supplement: Omit<Supplement, 'id' | 'created_at'>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canCreate) {
      throw new Error('Accès refusé: permission de création requise');
    }

    const { data, error } = await supabase
      .from('supplements')
      .insert([supplement])
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async updateSupplement(id: number, updates: Partial<Supplement>, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canEdit) {
      throw new Error('Accès refusé: permission de modification requise');
    }

    const { data, error } = await supabase
      .from('supplements')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  static async deleteSupplement(id: number, permissions: ReturnType<typeof useStockPermissions>) {
    this.checkPermissions(permissions);
    
    if (!permissions.canDelete) {
      throw new Error('Accès refusé: permission de suppression requise');
    }

    const { error } = await supabase
      .from('supplements')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  }
}

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "13.0.4"
  }
  public: {
    Tables: {
      admin_users: {
        Row: {
          created_at: string
          email: string
          full_name: string | null
          id: string
          is_active: boolean
          password_hash: string
          role: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          email: string
          full_name?: string | null
          id?: string
          is_active?: boolean
          password_hash: string
          role: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          email?: string
          full_name?: string | null
          id?: string
          is_active?: boolean
          password_hash?: string
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      cart_item_supplements: {
        Row: {
          cart_item_id: string | null
          created_at: string | null
          id: string
          price: number | null
          quantity: number
          supplement_id: number
          supplement_name: string
          supplement_type: string
        }
        Insert: {
          cart_item_id?: string | null
          created_at?: string | null
          id?: string
          price?: number | null
          quantity?: number
          supplement_id: number
          supplement_name: string
          supplement_type: string
        }
        Update: {
          cart_item_id?: string | null
          created_at?: string | null
          id?: string
          price?: number | null
          quantity?: number
          supplement_id?: number
          supplement_name?: string
          supplement_type?: string
        }
        Relationships: [
          {
            foreignKeyName: "cart_item_supplements_cart_item_id_fkey"
            columns: ["cart_item_id"]
            isOneToOne: false
            referencedRelation: "cart_items"
            referencedColumns: ["id"]
          },
        ]
      }
      cart_items: {
        Row: {
          cart_id: string | null
          created_at: string | null
          description: string | null
          id: string
          image_url: string | null
          instructions: string | null
          item_id: number
          name: string
          quantity: number
          unit_price: number
        }
        Insert: {
          cart_id?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          instructions?: string | null
          item_id: number
          name: string
          quantity?: number
          unit_price: number
        }
        Update: {
          cart_id?: string | null
          created_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          instructions?: string | null
          item_id?: number
          name?: string
          quantity?: number
          unit_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "cart_summary"
            referencedColumns: ["cart_id"]
          },
          {
            foreignKeyName: "cart_items_cart_id_fkey"
            columns: ["cart_id"]
            isOneToOne: false
            referencedRelation: "carts"
            referencedColumns: ["id"]
          },
        ]
      }
      carts: {
        Row: {
          created_at: string | null
          id: string
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      carts_old: {
        Row: {
          created_at: string | null
          id: string | null
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          created_at?: string | null
          id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          created_at?: string | null
          id?: string | null
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      categories: {
        Row: {
          created_at: string | null
          description: string | null
          id: number
          image_url: string | null
          is_active: boolean | null
          name: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          is_active?: boolean | null
          name: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          description?: string | null
          id?: number
          image_url?: string | null
          is_active?: boolean | null
          name?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      driver_notifications: {
        Row: {
          created_at: string
          driver_id: number
          id: string
          message: string
          order_id: number | null
          read_at: string | null
          type: string
        }
        Insert: {
          created_at?: string
          driver_id: number
          id?: string
          message: string
          order_id?: number | null
          read_at?: string | null
          type: string
        }
        Update: {
          created_at?: string
          driver_id?: number
          id?: string
          message?: string
          order_id?: number | null
          read_at?: string | null
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "driver_notifications_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "driver_notifications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      drivers: {
        Row: {
          created_at: string | null
          current_lat: number | null
          current_lng: number | null
          email: string | null
          id: number
          is_active: boolean | null
          is_available: boolean | null
          name: string
          phone: string
          updated_at: string | null
        }
        Insert: {
          created_at?: string | null
          current_lat?: number | null
          current_lng?: number | null
          email?: string | null
          id?: number
          is_active?: boolean | null
          is_available?: boolean | null
          name: string
          phone: string
          updated_at?: string | null
        }
        Update: {
          created_at?: string | null
          current_lat?: number | null
          current_lng?: number | null
          email?: string | null
          id?: number
          is_active?: boolean | null
          is_available?: boolean | null
          name?: string
          phone?: string
          updated_at?: string | null
        }
        Relationships: []
      }
      menu_items: {
        Row: {
          category_id: number | null
          created_at: string | null
          description: string | null
          has_extra: boolean | null
          has_garniture: boolean | null
          id: number
          image_url: string | null
          is_available: boolean | null
          is_popular: boolean | null
          name: string
          price: number
          updated_at: string | null
        }
        Insert: {
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          has_extra?: boolean | null
          has_garniture?: boolean | null
          id?: number
          image_url?: string | null
          is_available?: boolean | null
          is_popular?: boolean | null
          name: string
          price: number
          updated_at?: string | null
        }
        Update: {
          category_id?: number | null
          created_at?: string | null
          description?: string | null
          has_extra?: boolean | null
          has_garniture?: boolean | null
          id?: number
          image_url?: string | null
          is_available?: boolean | null
          is_popular?: boolean | null
          name?: string
          price?: number
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "menu_items_category_id_fkey"
            columns: ["category_id"]
            isOneToOne: false
            referencedRelation: "categories"
            referencedColumns: ["id"]
          },
        ]
      }
      order_driver_assignments: {
        Row: {
          assigned_at: string | null
          delivered_at: string | null
          driver_id: number | null
          id: number
          order_id: number | null
          picked_up_at: string | null
        }
        Insert: {
          assigned_at?: string | null
          delivered_at?: string | null
          driver_id?: number | null
          id?: number
          order_id?: number | null
          picked_up_at?: string | null
        }
        Update: {
          assigned_at?: string | null
          delivered_at?: string | null
          driver_id?: number | null
          id?: number
          order_id?: number | null
          picked_up_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "order_driver_assignments_driver_id_fkey"
            columns: ["driver_id"]
            isOneToOne: false
            referencedRelation: "drivers"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_driver_assignments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_items: {
        Row: {
          created_at: string | null
          id: number
          instructions: string | null
          item_name: string
          item_price: number
          menu_item_id: number | null
          order_id: number | null
          quantity: number
          selected_extras: Json | null
          selected_garnitures: Json | null
          total_price: number
        }
        Insert: {
          created_at?: string | null
          id?: number
          instructions?: string | null
          item_name: string
          item_price: number
          menu_item_id?: number | null
          order_id?: number | null
          quantity?: number
          selected_extras?: Json | null
          selected_garnitures?: Json | null
          total_price: number
        }
        Update: {
          created_at?: string | null
          id?: number
          instructions?: string | null
          item_name?: string
          item_price?: number
          menu_item_id?: number | null
          order_id?: number | null
          quantity?: number
          selected_extras?: Json | null
          selected_garnitures?: Json | null
          total_price?: number
        }
        Relationships: [
          {
            foreignKeyName: "order_items_menu_item_id_fkey"
            columns: ["menu_item_id"]
            isOneToOne: false
            referencedRelation: "menu_items"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      order_notifications: {
        Row: {
          id: string
          message: string
          order_id: number
          read_at: string | null
          sent_at: string
          type: string
          user_id: string | null
        }
        Insert: {
          id?: string
          message: string
          order_id: number
          read_at?: string | null
          sent_at?: string
          type: string
          user_id?: string | null
        }
        Update: {
          id?: string
          message?: string
          order_id?: number
          read_at?: string | null
          sent_at?: string
          type?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "order_notifications_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "order_notifications_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      order_tracking: {
        Row: {
          created_at: string | null
          id: number
          location_lat: number | null
          location_lng: number | null
          notes: string | null
          order_id: number | null
          status: Database["public"]["Enums"]["order_status"]
        }
        Insert: {
          created_at?: string | null
          id?: number
          location_lat?: number | null
          location_lng?: number | null
          notes?: string | null
          order_id?: number | null
          status: Database["public"]["Enums"]["order_status"]
        }
        Update: {
          created_at?: string | null
          id?: number
          location_lat?: number | null
          location_lng?: number | null
          notes?: string | null
          order_id?: number | null
          status?: Database["public"]["Enums"]["order_status"]
        }
        Relationships: [
          {
            foreignKeyName: "order_tracking_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "orders"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          accepted_at: string | null
          actual_delivery_time: string | null
          created_at: string | null
          customer_name: string | null
          customer_phone: string
          delivery_address: string | null
          delivery_fee: number | null
          delivery_lat: number | null
          delivery_lng: number | null
          delivery_type: Database["public"]["Enums"]["delivery_type"]
          estimated_delivery_time: string | null
          id: number
          instructions: string | null
          kitchen_notes: string | null
          payment_method: Database["public"]["Enums"]["payment_method"]
          payment_number: string | null
          preparation_time: number | null
          ready_at: string | null
          rejected_at: string | null
          status: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total_amount: number
          updated_at: string | null
          user_id: string | null
        }
        Insert: {
          accepted_at?: string | null
          actual_delivery_time?: string | null
          created_at?: string | null
          customer_name?: string | null
          customer_phone: string
          delivery_address?: string | null
          delivery_fee?: number | null
          delivery_lat?: number | null
          delivery_lng?: number | null
          delivery_type?: Database["public"]["Enums"]["delivery_type"]
          estimated_delivery_time?: string | null
          id?: number
          instructions?: string | null
          kitchen_notes?: string | null
          payment_method?: Database["public"]["Enums"]["payment_method"]
          payment_number?: string | null
          preparation_time?: number | null
          ready_at?: string | null
          rejected_at?: string | null
          status?: Database["public"]["Enums"]["order_status"]
          subtotal: number
          total_amount: number
          updated_at?: string | null
          user_id?: string | null
        }
        Update: {
          accepted_at?: string | null
          actual_delivery_time?: string | null
          created_at?: string | null
          customer_name?: string | null
          customer_phone?: string
          delivery_address?: string | null
          delivery_fee?: number | null
          delivery_lat?: number | null
          delivery_lng?: number | null
          delivery_type?: Database["public"]["Enums"]["delivery_type"]
          estimated_delivery_time?: string | null
          id?: number
          instructions?: string | null
          kitchen_notes?: string | null
          payment_method?: Database["public"]["Enums"]["payment_method"]
          payment_number?: string | null
          preparation_time?: number | null
          ready_at?: string | null
          rejected_at?: string | null
          status?: Database["public"]["Enums"]["order_status"]
          subtotal?: number
          total_amount?: number
          updated_at?: string | null
          user_id?: string | null
        }
        Relationships: []
      }
      supplements: {
        Row: {
          created_at: string | null
          id: number
          is_available: boolean | null
          is_obligatory: boolean | null
          name: string
          price: number | null
          type: string
        }
        Insert: {
          created_at?: string | null
          id?: number
          is_available?: boolean | null
          is_obligatory?: boolean | null
          name: string
          price?: number | null
          type: string
        }
        Update: {
          created_at?: string | null
          id?: number
          is_available?: boolean | null
          is_obligatory?: boolean | null
          name?: string
          price?: number | null
          type?: string
        }
        Relationships: []
      }
      users: {
        Row: {
          address: string | null
          avatar_url: string | null
          created_at: string | null
          email: string | null
          full_name: string | null
          id: string
          is_active: boolean | null
          phone: string | null
          updated_at: string | null
        }
        Insert: {
          address?: string | null
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id: string
          is_active?: boolean | null
          phone?: string | null
          updated_at?: string | null
        }
        Update: {
          address?: string | null
          avatar_url?: string | null
          created_at?: string | null
          email?: string | null
          full_name?: string | null
          id?: string
          is_active?: boolean | null
          phone?: string | null
          updated_at?: string | null
        }
        Relationships: []
      }
    }
    Views: {
      cart_summary: {
        Row: {
          cart_id: string | null
          created_at: string | null
          subtotal: number | null
          total_items: number | null
          total_quantity: number | null
          updated_at: string | null
          user_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      authenticate_admin: {
        Args: { email_input: string; password_input: string }
        Returns: {
          admin_email: string
          admin_id: string
          admin_name: string
          admin_role: string
        }[]
      }
      create_admin_user: {
        Args: {
          email_input: string
          name_input?: string
          password_input: string
          role_input: string
        }
        Returns: string
      }
      get_cart_item_total: {
        Args: { cart_item_uuid: string }
        Returns: number
      }
    }
    Enums: {
      delivery_type: "delivery" | "pickup"
      order_status:
        | "pending"
        | "accepted"
        | "ready_for_delivery"
        | "picked_up"
        | "in_transit"
        | "delivered"
        | "cancelled"
      payment_method: "cash" | "wave" | "orange_money"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      delivery_type: ["delivery", "pickup"],
      order_status: [
        "pending",
        "accepted",
        "ready_for_delivery",
        "in_transit",
        "delivered",
        "cancelled",
      ],
      payment_method: ["cash", "wave", "orange_money"],
    },
  },
} as const

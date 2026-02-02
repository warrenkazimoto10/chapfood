-- Create admin users table for admin authentication
CREATE TABLE public.admin_users (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin_general', 'cuisine')),
  full_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Admin users can view and manage their own data
CREATE POLICY "Admin users can view own profile" 
ON public.admin_users 
FOR SELECT 
USING (true);

CREATE POLICY "Admin users can update own profile" 
ON public.admin_users 
FOR UPDATE 
USING (true);

-- Extend orders table with kitchen management fields
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS preparation_time INTEGER; -- minutes
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS kitchen_notes TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS rejected_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS ready_at TIMESTAMP WITH TIME ZONE;

-- Create driver notifications table
CREATE TABLE public.driver_notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id INTEGER NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  order_id INTEGER REFERENCES public.orders(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('order_available', 'order_ready', 'order_assigned')),
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.driver_notifications ENABLE ROW LEVEL SECURITY;

-- Drivers can view their own notifications
CREATE POLICY "Drivers can view own notifications" 
ON public.driver_notifications 
FOR SELECT 
USING (true);

-- Create order notifications table for clients
CREATE TABLE public.order_notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('order_confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered')),
  sent_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" 
ON public.order_notifications 
FOR SELECT 
USING (user_id = auth.uid());

-- Add trigger for updated_at on admin_users
CREATE TRIGGER update_admin_users_updated_at
BEFORE UPDATE ON public.admin_users
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- Enable realtime for notifications
ALTER PUBLICATION supabase_realtime ADD TABLE public.driver_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
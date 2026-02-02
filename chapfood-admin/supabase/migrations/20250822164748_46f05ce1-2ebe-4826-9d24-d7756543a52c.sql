-- Fix security issues: Enable RLS on remaining tables (excluding cart_summary which is a view)

-- Enable RLS on tables that don't have it (excluding cart_summary)
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_item_supplements ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies for cart tables
CREATE POLICY "Users can manage own cart" 
ON public.carts 
FOR ALL 
USING (user_id = auth.uid());

CREATE POLICY "Users can manage own cart items" 
ON public.cart_items 
FOR ALL 
USING (cart_id IN (SELECT id FROM public.carts WHERE user_id = auth.uid()));

CREATE POLICY "Users can manage own cart supplements" 
ON public.cart_item_supplements 
FOR ALL 
USING (cart_item_id IN (
  SELECT ci.id FROM public.cart_items ci 
  JOIN public.carts c ON ci.cart_id = c.id 
  WHERE c.user_id = auth.uid()
));

-- Create security definer function for admin authentication
CREATE OR REPLACE FUNCTION public.authenticate_admin(email_input TEXT, password_input TEXT)
RETURNS TABLE(admin_id UUID, admin_email TEXT, admin_role TEXT, admin_name TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.email, a.role, a.full_name
  FROM public.admin_users a
  WHERE a.email = email_input 
    AND a.password_hash = crypt(password_input, a.password_hash)
    AND a.is_active = true;
END;
$$;

-- Create function to hash admin passwords
CREATE OR REPLACE FUNCTION public.create_admin_user(
  email_input TEXT,
  password_input TEXT,
  role_input TEXT,
  name_input TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_admin_id UUID;
BEGIN
  INSERT INTO public.admin_users (email, password_hash, role, full_name)
  VALUES (
    email_input,
    crypt(password_input, gen_salt('bf')),
    role_input,
    name_input
  )
  RETURNING id INTO new_admin_id;
  
  RETURN new_admin_id;
END;
$$;
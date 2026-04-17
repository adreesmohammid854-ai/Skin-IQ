-- Create ENUMs
CREATE TYPE user_role AS ENUM ('CUSTOMER', 'WHOLESALE', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE order_status AS ENUM ('PENDING', 'PAID', 'DEBT', 'CANCELLED');
CREATE TYPE payment_status AS ENUM ('SUCCESS', 'FAILED', 'PENDING');

-- Create users table (Extending auth.users is best practice in Supabase)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    business_name TEXT,
    role user_role DEFAULT 'CUSTOMER'::user_role NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create products table
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    retail_price NUMERIC(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create product_wholesale_prices table for strict RLS compliance
CREATE TABLE public.product_wholesale_prices (
    product_id UUID PRIMARY KEY REFERENCES public.products(id) ON DELETE CASCADE,
    wholesale_price NUMERIC(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create orders table
CREATE TABLE public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    total_amount NUMERIC(10, 2) NOT NULL,
    status order_status DEFAULT 'PENDING'::order_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create order_items table
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL
);

-- Create payments table
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    provider TEXT NOT NULL,
    status payment_status DEFAULT 'PENDING'::payment_status NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_wholesale_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Helper Function to prevent infinite recursion in RLS
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS public.user_role
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

-- RLS Policies

-- Users: Can read their own data. Admins/Super Admins can read all.
CREATE POLICY "Users can view their own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can view all profiles" ON public.users FOR SELECT USING (
  public.get_user_role() IN ('ADMIN', 'SUPER_ADMIN')
);

-- Users: Can update their own profile.
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Products: Anyone can view active products.
CREATE POLICY "Anyone can view active products" ON public.products FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can view all products" ON public.products FOR SELECT USING (
  public.get_user_role() IN ('ADMIN', 'SUPER_ADMIN')
);

-- Product Wholesale Prices: Only WHOLESALE, ADMIN, SUPER_ADMIN can view
CREATE POLICY "Authorized roles can view wholesale prices" ON public.product_wholesale_prices FOR SELECT USING (
  public.get_user_role() IN ('WHOLESALE', 'ADMIN', 'SUPER_ADMIN')
);

-- Orders: Users can view their own. Admins can view all.
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Admins can view all orders" ON public.orders FOR SELECT USING (
  public.get_user_role() IN ('ADMIN', 'SUPER_ADMIN')
);

-- Order Items: Users can view items of their own orders.
CREATE POLICY "Users can view own order items" ON public.order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
);
CREATE POLICY "Admins can view all order items" ON public.order_items FOR SELECT USING (
  public.get_user_role() IN ('ADMIN', 'SUPER_ADMIN')
);

-- Payments: Users can view payments for their own orders.
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.orders WHERE orders.id = payments.order_id AND orders.user_id = auth.uid())
);
CREATE POLICY "Admins can view all payments" ON public.payments FOR SELECT USING (
  public.get_user_role() IN ('ADMIN', 'SUPER_ADMIN')
);

-- ==============================================================================
-- TINGO ECOSISTEMA CERO COSTOS ($0/MES) - ESQUEMA BASE DE DATOS POSTGIS
-- ==============================================================================

-- 1. Habilitar extensiones requeridas
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 2. Enumeraciones de estado
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('passenger', 'driver', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE trip_status AS ENUM (
        'REQUESTED', 
        'MATCHING', 
        'ACCEPTED', 
        'ARRIVED', 
        'IN_PROGRESS', 
        'COMPLETED', 
        'CANCELLED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM ('CASH', 'CARD');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM ('PENDING', 'AUTHORIZED', 'CAPTURED', 'RELEASED', 'FAILED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Tabla de Perfiles de Usuario
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    avatar_url TEXT,
    role user_role NOT NULL DEFAULT 'passenger',
    rating NUMERIC(3, 2) DEFAULT 5.00,
    total_trips INTEGER DEFAULT 0,
    fcm_token TEXT,
    stripe_customer_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabla de Vehículos del Conductor
CREATE TABLE IF NOT EXISTS public.driver_vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year INTEGER NOT NULL,
    color TEXT NOT NULL,
    license_plate TEXT UNIQUE NOT NULL,
    status verification_status DEFAULT 'PENDING',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Tabla de Documentos del Conductor
CREATE TABLE IF NOT EXISTS public.driver_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL, -- 'DRIVER_LICENSE', 'VEHICLE_REGISTRATION', 'INSURANCE'
    document_url TEXT NOT NULL,
    status verification_status DEFAULT 'PENDING',
    rejection_reason TEXT,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Tabla de Ubicaciones GPS en Tiempo Real de Conductores
CREATE TABLE IF NOT EXISTS public.driver_locations (
    driver_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    heading NUMERIC(5, 2) DEFAULT 0.0,
    is_online BOOLEAN DEFAULT FALSE,
    is_busy BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_driver_locations_gix 
ON public.driver_locations USING GIST (location);

-- 7. Tabla de Parámetros Globales de Tarifas (Admin)
CREATE TABLE IF NOT EXISTS public.system_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    base_fare NUMERIC(10, 2) DEFAULT 2.50,
    cost_per_km NUMERIC(10, 2) DEFAULT 0.85,
    cost_per_minute NUMERIC(10, 2) DEFAULT 0.20,
    minimum_fare NUMERIC(10, 2) DEFAULT 3.50,
    app_commission_percentage NUMERIC(5, 2) DEFAULT 15.00, -- 15% comisión para Tingo
    search_radius_km NUMERIC(5, 2) DEFAULT 5.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.system_settings (id, base_fare, cost_per_km, cost_per_minute, minimum_fare, app_commission_percentage)
VALUES (1, 2.50, 0.85, 0.20, 3.50, 15.00)
ON CONFLICT (id) DO NOTHING;

-- 8. Tabla de Viajes
CREATE TABLE IF NOT EXISTS public.trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    passenger_id UUID NOT NULL REFERENCES public.profiles(id),
    driver_id UUID REFERENCES public.profiles(id),
    origin_address TEXT NOT NULL,
    origin_location GEOGRAPHY(POINT, 4326) NOT NULL,
    destination_address TEXT NOT NULL,
    destination_location GEOGRAPHY(POINT, 4326) NOT NULL,
    estimated_distance_km NUMERIC(10, 2) NOT NULL,
    estimated_duration_min NUMERIC(10, 2) NOT NULL,
    estimated_fare NUMERIC(10, 2) NOT NULL,
    final_fare NUMERIC(10, 2),
    app_commission_amount NUMERIC(10, 2),
    driver_earnings_amount NUMERIC(10, 2),
    pay_method payment_method NOT NULL DEFAULT 'CASH',
    pay_status payment_status NOT NULL DEFAULT 'PENDING',
    status trip_status NOT NULL DEFAULT 'REQUESTED',
    stripe_payment_intent_id TEXT,
    cancellation_reason TEXT,
    passenger_rating INTEGER CHECK (passenger_rating BETWEEN 1 AND 5),
    driver_rating INTEGER CHECK (driver_rating BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_trips_passenger ON public.trips(passenger_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver ON public.trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON public.trips(status);

-- 9. FUNCIÓN GEOESPACIAL POSTGIS: Buscar conductores activos más cercanos
CREATE OR REPLACE FUNCTION public.fn_get_nearby_drivers(
    passenger_lat DOUBLE PRECISION,
    passenger_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 5.0
)
RETURNS TABLE (
    driver_id UUID,
    full_name TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    rating NUMERIC(3, 2),
    distance_meters DOUBLE PRECISION,
    current_lat DOUBLE PRECISION,
    current_lng DOUBLE PRECISION,
    heading NUMERIC(5, 2)
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS driver_id,
        p.full_name,
        p.phone_number,
        p.avatar_url,
        p.rating,
        ST_Distance(
            dl.location, 
            ST_SetSRID(ST_MakePoint(passenger_lng, passenger_lat), 4326)::geography
        ) AS distance_meters,
        ST_Y(dl.location::geometry) AS current_lat,
        ST_X(dl.location::geometry) AS current_lng,
        dl.heading
    FROM public.driver_locations dl
    JOIN public.profiles p ON p.id = dl.driver_id
    JOIN public.driver_vehicles dv ON dv.driver_id = p.id
    WHERE dl.is_online = TRUE 
      AND dl.is_busy = FALSE
      AND p.role = 'driver'
      AND dv.status = 'APPROVED'
      AND ST_DWithin(
            dl.location,
            ST_SetSRID(ST_MakePoint(passenger_lng, passenger_lat), 4326)::geography,
            radius_km * 1000.0
      )
    ORDER BY distance_meters ASC;
END;
$$;

-- 10. POLÍTICAS DE SEGURIDAD (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Permisos genéricos para prototipo/desarrollo
CREATE POLICY "Permitir lectura publica de perfiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Permitir lectura publica de ubicaciones conductor" ON public.driver_locations FOR SELECT USING (true);
CREATE POLICY "Permitir actualización de ubicaciones propias" ON public.driver_locations FOR ALL USING (true);
CREATE POLICY "Permitir lectura y creación de viajes" ON public.trips FOR ALL USING (true);
CREATE POLICY "Permitir lectura publica de tarifas" ON public.system_settings FOR SELECT USING (true);
CREATE POLICY "Permitir actualización de tarifas" ON public.system_settings FOR ALL USING (true);

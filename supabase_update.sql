-- =====================================================================================
-- SCRIPT DE ACTUALIZACIÓN DE BASE DE DATOS - KST BUSINESS
-- =====================================================================================

-- 1. Crear tabla de Perfiles de Usuario (user_profiles)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  first_name text,
  last_name text,
  full_name text GENERATED ALWAYS AS (COALESCE(first_name || ' ' || last_name, email)) STORED,
  role text NOT NULL CHECK (role IN ('administrador', 'gerente', 'vendedor', 'sistema')),
  area text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  phone text
);

-- Habilitar RLS en user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Crear políticas de RLS para user_profiles
DROP POLICY IF EXISTS "Permitir lectura de perfiles a usuarios autenticados" ON public.user_profiles;
CREATE POLICY "Permitir lectura de perfiles a usuarios autenticados"
  ON public.user_profiles FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Permitir control de perfiles solo a administradores" ON public.user_profiles;
CREATE POLICY "Permitir control de perfiles solo a administradores"
  ON public.user_profiles FOR ALL TO authenticated USING (
    COALESCE((SELECT role FROM public.user_profiles WHERE id = auth.uid()), 'vendedor') = 'administrador'
  );

DROP POLICY IF EXISTS "Permitir actualización de perfil propio" ON public.user_profiles;
CREATE POLICY "Permitir actualización de perfil propio"
  ON public.user_profiles FOR UPDATE TO authenticated 
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Trigger para sincronizar auth.users a public.user_profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, role)
  VALUES (
    new.id, 
    new.email,
    COALESCE(new.raw_user_meta_data ->> 'role', 'vendedor')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Sincronizar usuarios existentes de auth.users a public.user_profiles
INSERT INTO public.user_profiles (id, email, role)
SELECT id, email, COALESCE(raw_user_meta_data ->> 'role', 'vendedor')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 2. Alterar tabla catalogo para stock e inventario y rezago
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS stock numeric;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS es_rezago boolean DEFAULT false NOT NULL;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS es_por_puntos boolean DEFAULT false;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS puntos integer;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tarifa_punto numeric(12,2);

-- 3. Alterar tabla cotizacion_items para puntos y minutos
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS es_por_puntos boolean DEFAULT false NOT NULL;
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS tarifa_punto numeric;
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS es_por_minutos boolean DEFAULT false NOT NULL;
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS duracion_minutos numeric;
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS tarifa_minuto numeric;
ALTER TABLE public.cotizacion_items ADD COLUMN IF NOT EXISTS detalles_tecnicos jsonb;

-- 4. Actualizar función user_has_role para leer de la tabla user_profiles
CREATE OR REPLACE FUNCTION public.user_has_role(required_roles text[])
RETURNS boolean AS $$
DECLARE
    user_role text;
BEGIN
    SELECT role INTO user_role
    FROM public.user_profiles
    WHERE id = auth.uid();
    
    RETURN COALESCE(user_role, 'vendedor') = ANY(required_roles);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================================
-- 5. ACTUALIZACIONES DE LA REESTRUCTURACIÓN (STORAGE E IMÁGENES)
-- =====================================================================================

-- Añadir columna imagen_url a catalogo si no existe
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS imagen_url text;

-- Limpieza completa de datos (Trunca/Borra tablas a excepción de user_profiles)
-- Se borran los conceptos y cotizaciones primero por restricciones de llave foránea (FK)
DELETE FROM public.cotizacion_items;
DELETE FROM public.cotizaciones;
DELETE FROM public.clientes;
DELETE FROM public.catalogo;

-- Crear el bucket de storage 'catalog' si no existe
INSERT INTO storage.buckets (id, name, public)
VALUES ('catalog', 'catalog', true)
ON CONFLICT (id) DO NOTHING;

-- Crear políticas para almacenamiento de imágenes de catálogo
DROP POLICY IF EXISTS "Permitir lectura pública de imágenes de catálogo" ON storage.objects;
CREATE POLICY "Permitir lectura pública de imágenes de catálogo"
  ON storage.objects FOR SELECT USING (bucket_id = 'catalog');

DROP POLICY IF EXISTS "Permitir subida de imágenes a usuarios autenticados" ON storage.objects;
CREATE POLICY "Permitir subida de imágenes a usuarios autenticados"
  ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'catalog');

DROP POLICY IF EXISTS "Permitir eliminación de imágenes a administradores o propietarios" ON storage.objects;
CREATE POLICY "Permitir eliminación de imágenes a administradores o propietarios"
  ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'catalog');

-- ================================================================================
--                    DATOS SEMILLA (SEED DATA) PARA CLIENTES Y CATÁLOGO
-- ================================================================================

-- 1. Clientes Semilla (Reales)
insert into public.clientes (id, nombre, telefono, correo, empresa) values
('11111111-1111-1111-1111-111111111111', 'Juan García', '5512345678', 'juan@empresa.mx', 'Empresa ABC S.A.'),
('22222222-2222-2222-2222-222222222222', 'María López', '5598765432', 'maria@xyz.mx', 'Constructora XYZ'),
('33333333-3333-3333-3333-333333333333', 'Roberto Sánchez', '5511223344', 'rsanchez@gov.mx', 'Municipio de Apizaco'),
('44444444-4444-4444-4444-444444444444', 'Ana Torres', '5544556677', 'ana@redes.mx', 'Redes Modernas S.A.'),
('55555555-5555-5555-5555-555555555555', 'Luis Hernández', '5577889900', 'luis@tecno.mx', 'Tecno Soluciones S.A.'),
('66666666-6666-6666-6666-666666666666', 'Adolfo Robles', '2471072139', 'adolfo.robles@transportesrobles.mx', 'Transportes Robles')
on conflict (id) do update set
    nombre = excluded.nombre,
    telefono = excluded.telefono,
    correo = excluded.correo,
    empresa = excluded.empresa;

-- 2. Catálogo Semilla Enriquecido con campos por Pilar
insert into public.catalogo (
    id, nombre, descripcion, tipo_cobro, pilar, precio_base, costo_proveedor, margen_porcentaje, categoria, unidad,
    marca, modelo, garantia, dimensiones, peso_kg, stock, es_rezago,
    modalidad_servicio, incluye_visita, tarifa_hora_extra, duracion_estimada,
    tipo_proyecto, tecnologias, modulos, horas_estimadas, garantia_entrega,
    comision_fija, comision_porcentaje, monto_minimo, monto_maximo, tipo_pago,
    tipo_contenido, revisiones_incluidas, tiempo_entrega, entregables, formato_salida, tarifa_hora_creativa
) values
-- Pilar A: Productos
('a1', 'Laptop HP 15"', 'Laptop HP Core i5, 8GB RAM, 512GB SSD', 'COSTO_MARKUP', 'A', 12500.00, 10000.00, 25.00, 'Cómputo', 'pza',
 'HP', '15-dy2500', '1 año con fabricante', '35.85 x 24.2 x 1.79 cm', 1.690, 15.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

('a2', 'Switch 24 puertos', 'Switch administrable 24 puertos Gigabit', 'FIJO_PRECIO', 'A', 4800.00, null, null, 'Redes', 'pza',
 'TP-Link', 'TL-SG1024', '5 años', '44.0 x 18.0 x 4.4 cm', 2.000, 8.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

('a3', 'Licencia Office 365', 'Suscripción anual Microsoft 365 Business', 'FIJO_PRECIO', 'A', 3200.00, null, null, 'Licencias', 'usuario/año',
 'Microsoft', 'Business Standard', 'Suscripción activa', null, null, 100.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

-- Pilar B: Servicios Técnicos
('b1', 'Instalación de Red', 'Instalación y configuración de red estructurada', 'TARIFA_BASE_EXTRAS', 'B', 1500.00, null, null, 'Instalación', 'servicio',
 null, null, null, null, null, 0.00, false,
 'presencial', true, 350.00, '1-2 días',
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

('b2', 'Mantenimiento Preventivo', 'Mantenimiento preventivo de equipo de cómputo', 'TARIFA_BASE_EXTRAS', 'B', 350.00, null, null, 'Mantenimiento', 'equipo',
 null, null, null, null, null, 0.00, false,
 'presencial', true, 250.00, '2-4 hrs',
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

('b3', 'Soporte Técnico Remoto', 'Soporte técnico a distancia (1 hora)', 'TARIFA_BASE_EXTRAS', 'B', 500.00, null, null, 'Soporte', 'hora',
 null, null, null, null, null, 0.00, false,
 'remoto', false, 400.00, '1 hora',
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

-- Pilar C: Proyectos Complejos
('c1', 'Desarrollo App Móvil', 'Desarrollo de aplicación móvil iOS/Android', 'POR_HORA_MODULO', 'C', 800.00, null, null, 'Desarrollo', 'hora',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 'movil', '["Flutter", "Firebase", "Dart", "Node.js"]'::jsonb,
 '[{"nombre": "Autenticación", "descripcion": "Login y registro de usuarios", "horas": 20, "precio": 16000}, {"nombre": "Base de datos", "descripcion": "Diseño y sincronización de datos", "horas": 30, "precio": 24000}]'::jsonb,
 120.0, '90 días post-entrega',
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

('c2', 'Sitio Web Corporativo', 'Diseño y desarrollo web responsive', 'POR_HORA_MODULO', 'C', 650.00, null, null, 'Desarrollo', 'hora',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 'web', '["React", "Vite", "Tailwind CSS", "Supabase"]'::jsonb,
 '[{"nombre": "Home & Landing", "descripcion": "Diseño UI premium responsive", "horas": 25, "precio": 16250}]'::jsonb,
 60.0, '60 días post-entrega',
 0.00, 0.00, null, null, null,
 null, null, null, '[]'::jsonb, null, null),

-- Pilar D: Micro-Transacciones
('d1', 'Pago CFE', 'Pago de recibo CFE + comisión de servicio', 'MONTO_MAS_COMISION', 'D', 0.00, null, null, 'Pagos', 'recibo',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 15.00, 0.00, 10.00, 10000.00, 'cfe',
 null, null, null, '[]'::jsonb, null, null),

('d2', 'Recarga de Saldo', 'Recarga telefónica + comisión de servicio', 'MONTO_MAS_COMISION', 'D', 0.00, null, null, 'Recargas', 'recarga',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 3.00, 0.00, 10.00, 500.00, 'recarga',
 null, null, null, '[]'::jsonb, null, null),

-- Pilar E: Servicios Creativos
('e1', 'Video Promocional Rápido', 'Paquete video 30 seg edición básica', 'HIBRIDO_CREATIVO', 'E', 2500.00, null, null, 'Contenido', 'paquete',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 'video', 3, '3-5 días hábiles', '["Video MP4 1080p", "Miniatura", "Archivo de proyecto"]'::jsonb, 'MP4', 600.00),

('e2', 'Invitación Digital', 'Diseño de invitación digital animada', 'HIBRIDO_CREATIVO', 'E', 800.00, null, null, 'Diseño', 'pza',
 null, null, null, null, null, 0.00, false,
 null, false, null, null,
 null, '[]'::jsonb, '[]'::jsonb, null, null,
 0.00, 0.00, null, null, null,
 'diseno', 2, '1-2 días', '["Imagen JPG", "PDF Interactivo", "SVG editable"]'::jsonb, 'PDF/JPG', 400.00)
on conflict (id) do update set
    nombre = excluded.nombre,
    descripcion = excluded.descripcion,
    tipo_cobro = excluded.tipo_cobro,
    pilar = excluded.pilar,
    precio_base = excluded.precio_base,
    costo_proveedor = excluded.costo_proveedor,
    margen_porcentaje = excluded.margen_porcentaje,
    categoria = excluded.categoria,
    unidad = excluded.unidad,
    marca = excluded.marca,
    modelo = excluded.modelo,
    garantia = excluded.garantia,
    dimensiones = excluded.dimensiones,
    peso_kg = excluded.peso_kg,
    stock = excluded.stock,
    es_rezago = excluded.es_rezago,
    modalidad_servicio = excluded.modalidad_servicio,
    incluye_visita = excluded.incluye_visita,
    tarifa_hora_extra = excluded.tarifa_hora_extra,
    duracion_estimada = excluded.duracion_estimada,
    tipo_proyecto = excluded.tipo_proyecto,
    tecnologias = excluded.tecnologias,
    modulos = excluded.modulos,
    horas_estimadas = excluded.horas_estimadas,
    garantia_entrega = excluded.garantia_entrega,
    comision_fija = excluded.comision_fija,
    comision_porcentaje = excluded.comision_porcentaje,
    monto_minimo = excluded.monto_minimo,
    monto_maximo = excluded.monto_maximo,
    tipo_pago = excluded.tipo_pago,
    tipo_contenido = excluded.tipo_contenido,
    revisiones_incluidas = excluded.revisiones_incluidas,
    tiempo_entrega = excluded.tiempo_entrega,
    entregables = excluded.entregables,
    formato_salida = excluded.formato_salida,
    tarifa_hora_creativa = excluded.tarifa_hora_creativa;

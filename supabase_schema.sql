-- ================================================================================
--                    ESQUEMA DE BASE DE DATOS - KST BUSINESS
-- ================================================================================
-- PROYECTO: KST Business
-- MOTOR: PostgreSQL (Supabase)
-- DESCRIPCIÓN: Estructura relacional con RLS escalable y datos semilla.
-- ================================================================================

-- Habilitar extensión UUID si no está habilitada
create extension if not exists "uuid-ossp";

-- ─── 0. TABLA: PERFILES DE USUARIO (user_profiles) ─────────────────────────────
create table if not exists public.user_profiles (
    id uuid not null primary key references auth.users(id) on delete cascade,
    email text not null,
    first_name text,
    last_name text,
    full_name text generated always as (coalesce(first_name || ' ' || last_name, email)) stored,
    role text not null check (role in ('administrador', 'gerente', 'vendedor', 'sistema')),
    area text,
    is_active boolean default true,
    created_at timestamp with time zone default now(),
    updated_at timestamp with time zone default now(),
    phone text
);

-- ─── 1. TABLA: CLIENTES ────────────────────────────────────────────────────────
create table if not exists public.clientes (
    id uuid primary key default gen_random_uuid(),
    nombre text not null,
    telefono text,
    correo text,
    empresa text,
    rfc text,
    creado_en timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ─── 2. TABLA: CATÁLOGO (PRODUCTOS Y SERVICIOS) ──────────────────────────────────
create table if not exists public.catalogo (
    id text primary key default gen_random_uuid()::text,
    nombre text not null,
    descripcion text default ''::text not null,
    tipo_cobro text not null, -- FIJO_PRECIO, COSTO_MARKUP, etc.
    pilar text not null,      -- A, B, C, D, E
    precio_base numeric(12, 2) not null,
    costo_proveedor numeric(12, 2),
    margen_porcentaje numeric(5, 2),
    activo boolean default true not null,
    categoria text,
    unidad text,
    stock numeric default 0,
    es_rezago boolean default false not null,
    imagen_url text,
    es_por_puntos boolean default false,
    puntos integer,
    tarifa_punto numeric(12, 2),
    creado_en timestamp with time zone default timezone('utc'::text, now()) not null,
    
    constraint check_tipo_cobro check (tipo_cobro in ('FIJO_PRECIO', 'COSTO_MARKUP', 'TARIFA_BASE_EXTRAS', 'POR_HORA_MODULO', 'MONTO_MAS_COMISION', 'HIBRIDO_CREATIVO')),
    constraint check_pilar check (pilar in ('A', 'B', 'C', 'D', 'E'))
);

-- ─── 3. TABLA: COTIZACIONES ───────────────────────────────────────────────────
create table if not exists public.cotizaciones (
    id uuid primary key default gen_random_uuid(),
    numero text unique not null,
    cliente_id uuid not null references public.clientes(id) on delete restrict,
    status text default 'draft'::text not null, -- draft, sent, approved, rejected, expired
    vigencia_dias integer default 15 not null,
    notas text,
    vendedor_id uuid default auth.uid() references auth.users(id) on delete set null,
    creado_en timestamp with time zone default timezone('utc'::text, now()) not null,
    enviado_en timestamp with time zone,
    pdf_url text,
    
    constraint check_status check (status in ('draft', 'sent', 'approved', 'rejected', 'expired'))
);

-- ─── 4. TABLA: CONCEPTOS DE COTIZACIÓN (ITEMS) ─────────────────────────────────
create table if not exists public.cotizacion_items (
    id uuid primary key default gen_random_uuid(),
    cotizacion_id uuid not null references public.cotizaciones(id) on delete cascade,
    catalog_item_id text not null references public.catalogo(id) on delete restrict,
    cantidad numeric(10, 2) default 1.00 not null,
    precio_unitario numeric(12, 2) not null,
    descuento_porcentaje numeric(5, 2) default 0.00 not null,
    urgencia text default 'standard'::text not null, -- standard, express, immediate, emergency
    notas text,
    
    -- Campos especiales para pilares de negocio
    horas numeric(8, 2),
    tarifa_hora numeric(12, 2),
    monto_exacto numeric(12, 2),
    es_horas_edicion boolean default false not null,
    
    -- Campos para matriz de puntos y tarifas por minutos
    es_por_puntos boolean default false not null,
    tarifa_punto numeric,
    es_por_minutos boolean default false not null,
    duracion_minutos numeric,
    tarifa_minuto numeric,
    detalles_tecnicos jsonb,
    
    constraint check_urgencia check (urgencia in ('standard', 'express', 'immediate', 'emergency'))
);

-- ================================================================================
--                    ARQUITECTURA DE SEGURIDAD (RLS & ROLES)
-- ================================================================================

-- Función helper para verificar roles de manera dinámica y escalable
create or replace function public.user_has_role(required_roles text[])
returns boolean as $$
declare
    user_role text;
begin
    -- Se extrae el rol desde la tabla public.user_profiles
    select role into user_role
    from public.user_profiles
    where id = auth.uid();
    
    return coalesce(user_role, 'vendedor') = any(required_roles);
end;
$$ language plpgsql security definer;

-- Habilitar RLS en todas las tablas
alter table public.user_profiles enable row level security;
alter table public.clientes enable row level security;
alter table public.catalogo enable row level security;
alter table public.cotizaciones enable row level security;
alter table public.cotizacion_items enable row level security;

-- ─── POLÍTICAS DE RLS: PERFILES DE USUARIO ──────────────────────────────────────
create policy "Permitir lectura de perfiles a usuarios autenticados"
    on public.user_profiles for select to authenticated using (true);

create policy "Permitir control de perfiles solo a administradores"
    on public.user_profiles for all to authenticated using (
        coalesce((select role from public.user_profiles where id = auth.uid()), 'vendedor') = 'administrador'
    );

create policy "Permitir actualización de perfil propio"
    on public.user_profiles for update to authenticated 
    using (id = auth.uid())
    with check (id = auth.uid());

-- ─── POLÍTICAS DE RLS: CLIENTES ────────────────────────────────────────────────
create policy "Permitir lectura de clientes a usuarios autenticados"
    on public.clientes for select to authenticated using (true);

create policy "Permitir inserción de clientes a usuarios autenticados"
    on public.clientes for insert to authenticated with check (true);

create policy "Permitir edición de clientes a usuarios autenticados"
    on public.clientes for update to authenticated using (true);

create policy "Permitir borrado de clientes solo a administradores"
    on public.clientes for delete to authenticated 
    using (public.user_has_role(array['administrador']));

-- ─── POLÍTICAS DE RLS: CATÁLOGO ────────────────────────────────────────────────
create policy "Permitir lectura de catálogo a usuarios autenticados"
    on public.catalogo for select to authenticated using (true);

create policy "Permitir control de catálogo solo a administradores"
    on public.catalogo for all to authenticated 
    using (public.user_has_role(array['administrador']))
    with check (public.user_has_role(array['administrador']));

-- ─── POLÍTICAS DE RLS: COTIZACIONES ─────────────────────────────────────────────
create policy "Lectura de cotizaciones: Vendedores ven las suyas, Admins/Supervisores ven todas"
    on public.cotizaciones for select to authenticated 
    using (
        public.user_has_role(array['administrador', 'supervisor']) 
        or vendedor_id = auth.uid()
    );

create policy "Inserción de cotizaciones: Propietario o Administrador"
    on public.cotizaciones for insert to authenticated 
    with check (
        vendedor_id = auth.uid() 
        or public.user_has_role(array['administrador'])
    );

create policy "Edición de cotizaciones: Propietario o Administrador/Supervisor"
    on public.cotizaciones for update to authenticated 
    using (
        public.user_has_role(array['administrador', 'supervisor']) 
        or vendedor_id = auth.uid()
    );

create policy "Borrado de cotizaciones: Propietario o Administrador"
    on public.cotizaciones for delete to authenticated 
    using (
        public.user_has_role(array['administrador']) 
        or vendedor_id = auth.uid()
    );

-- ─── POLÍTICAS DE RLS: COTIZACION_ITEMS ──────────────────────────────────────────
create policy "Lectura de items: Si el usuario tiene acceso a la cotización padre"
    on public.cotizacion_items for select to authenticated 
    using (
        exists (
            select 1 from public.cotizaciones
            where public.cotizaciones.id = cotizacion_id
        )
    );

create policy "Inserción de items: Si el usuario tiene acceso a la cotización padre"
    on public.cotizacion_items for insert to authenticated 
    with check (
        exists (
            select 1 from public.cotizaciones
            where public.cotizaciones.id = cotizacion_id
        )
    );

create policy "Edición de items: Si el usuario tiene acceso a la cotización padre"
    on public.cotizacion_items for update to authenticated 
    using (
        exists (
            select 1 from public.cotizaciones
            where public.cotizaciones.id = cotizacion_id
        )
    );

create policy "Borrado de items: Si el usuario tiene acceso a la cotización padre"
    on public.cotizacion_items for delete to authenticated 
    using (
        exists (
            select 1 from public.cotizaciones
            where public.cotizaciones.id = cotizacion_id
        )
    );

-- ================================================================================
--                    CONFIGURACIÓN DE STORAGE (BUCKET PARA PDFs E IMÁGENES)
-- ================================================================================

-- Crear el bucket de storage para PDFs si no existe
insert into storage.buckets (id, name, public)
values ('quotes', 'quotes', true)
on conflict (id) do nothing;

-- Crear el bucket de storage para imágenes si no existe
insert into storage.buckets (id, name, public)
values ('catalog', 'catalog', true)
on conflict (id) do nothing;

-- Crear políticas para almacenamiento de PDFs
create policy "Permitir lectura pública de cotizaciones PDF"
    on storage.objects for select using (bucket_id = 'quotes');

create policy "Permitir subida de PDFs a usuarios autenticados"
    on storage.objects for insert to authenticated
    with check (bucket_id = 'quotes');

create policy "Permitir eliminación de PDFs a administradores o propietarios"
    on storage.objects for delete to authenticated
    using (bucket_id = 'quotes');

-- Crear políticas para almacenamiento de imágenes de catálogo
create policy "Permitir lectura pública de imágenes de catálogo"
    on storage.objects for select using (bucket_id = 'catalog');

create policy "Permitir subida de imágenes a usuarios autenticados"
    on storage.objects for insert to authenticated
    with check (bucket_id = 'catalog');

create policy "Permitir eliminación de imágenes a administradores o propietarios"
    on storage.objects for delete to authenticated
    using (bucket_id = 'catalog');

-- Trigger para sincronizar auth.users a public.user_profiles
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.user_profiles (id, email, role)
  values (
    new.id, 
    new.email,
    coalesce(new.raw_user_meta_data ->> 'role', 'vendedor')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Sincronizar usuarios existentes
insert into public.user_profiles (id, email, role)
select id, email, coalesce(raw_user_meta_data ->> 'role', 'vendedor')
from auth.users
on conflict (id) do nothing;

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

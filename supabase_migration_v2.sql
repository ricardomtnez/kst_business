-- ================================================================================
--   MIGRACIÓN V2 — KST Business Catálogo Dinámico por Pilar
--   Proyecto: ozcknultatuiybmcarog.supabase.co
--   Fecha: 2026-07-10
--   Instrucciones: Ejecutar en Supabase Dashboard → SQL Editor
-- ================================================================================

-- ─── PILAR A: KST Infraestructura & Redes ──────────────────────────────────────
-- Campos físicos de hardware/equipo

ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS marca TEXT;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS modelo TEXT;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS garantia TEXT;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS dimensiones TEXT;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS peso_kg NUMERIC(8,3);

-- ─── PILAR B: KST Soporte & Mantenimiento ──────────────────────────────────────
-- Campos de servicios técnicos

ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS modalidad_servicio TEXT
    CHECK (modalidad_servicio IS NULL OR modalidad_servicio IN ('remoto','presencial','hibrido'));
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS incluye_visita BOOLEAN DEFAULT FALSE;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tarifa_hora_extra NUMERIC(10,2);
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS duracion_estimada TEXT; -- "2-4 hrs", "medio día"

-- ─── PILAR C: KST Software & Plataformas ──────────────────────────────────────
-- Campos de desarrollo de software

ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tipo_proyecto TEXT
    CHECK (tipo_proyecto IS NULL OR tipo_proyecto IN ('web','movil','desktop','api','automatizacion','erp','otro'));
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tecnologias JSONB DEFAULT '[]'::JSONB;
    -- Formato: ["Flutter","React","Node.js","PostgreSQL"]
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS modulos JSONB DEFAULT '[]'::JSONB;
    -- Formato: [{"nombre":"Módulo Autenticación","descripcion":"Login/registro","horas":20,"precio":8000}]
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS horas_estimadas NUMERIC(8,1);
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS garantia_entrega TEXT; -- "90 días post-entrega"

-- ─── PILAR D: KST Finanzas & Pagos ─────────────────────────────────────────────
-- Campos de micro-transacciones

ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS comision_fija NUMERIC(10,2) DEFAULT 0;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS comision_porcentaje NUMERIC(5,2) DEFAULT 0;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS monto_minimo NUMERIC(12,2);
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS monto_maximo NUMERIC(12,2);
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tipo_pago TEXT
    CHECK (tipo_pago IS NULL OR tipo_pago IN ('cfe','agua','telefono','recarga','transferencia','predial','seguro','otro'));

-- ─── PILAR E: KST Media & Servicios Creativos ──────────────────────────────────
-- Campos de producción creativa

ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tipo_contenido TEXT
    CHECK (tipo_contenido IS NULL OR tipo_contenido IN ('video','diseno','fotografia','animacion','audio','branding','otro'));
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS revisiones_incluidas INTEGER DEFAULT 2;
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tiempo_entrega TEXT;  -- "3-5 días hábiles"
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS entregables JSONB DEFAULT '[]'::JSONB;
    -- Formato: ["Video 1080p MP4","Thumbnail 1920x1080","Storyboard PDF"]
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS formato_salida TEXT; -- "MP4 4K","PDF","PNG","SVG"
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS tarifa_hora_creativa NUMERIC(10,2);

-- ─── CAMPOS COMUNES (Todos los Pilares) ─────────────────────────────────────────

-- Galería de imágenes (hasta 5 URLs — Supabase Storage o Google Drive)
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS imagenes_urls JSONB DEFAULT '[]'::JSONB;
    -- Formato: ["https://storage.../img1.jpg","https://storage.../img2.jpg"]

-- Características genéricas clave-valor (campos extra flexibles)
ALTER TABLE public.catalogo ADD COLUMN IF NOT EXISTS caracteristicas JSONB DEFAULT '[]'::JSONB;
    -- Formato: [{"clave":"Voltaje","valor":"110V"},{"clave":"Conectividad","valor":"WiFi 6"}]

-- ─── ÍNDICES para búsqueda eficiente ───────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_catalogo_pilar ON public.catalogo(pilar);
CREATE INDEX IF NOT EXISTS idx_catalogo_activo ON public.catalogo(activo);
CREATE INDEX IF NOT EXISTS idx_catalogo_tipo_cobro ON public.catalogo(tipo_cobro);
CREATE INDEX IF NOT EXISTS idx_catalogo_es_rezago ON public.catalogo(es_rezago) WHERE es_rezago = TRUE;

-- Índice GIN para búsqueda en JSONB
CREATE INDEX IF NOT EXISTS idx_catalogo_tecnologias ON public.catalogo USING GIN(tecnologias);
CREATE INDEX IF NOT EXISTS idx_catalogo_modulos ON public.catalogo USING GIN(modulos);

-- ─── COMENTARIOS DE COLUMNAS ────────────────────────────────────────────────────
COMMENT ON COLUMN public.catalogo.tecnologias IS 'Array JSON de tecnologías. Ej: ["Flutter","React","Node.js"]';
COMMENT ON COLUMN public.catalogo.modulos IS 'Array JSON de módulos del proyecto: [{nombre, descripcion, horas, precio}]';
COMMENT ON COLUMN public.catalogo.imagenes_urls IS 'Array JSON de URLs de imágenes (hasta 5). Supabase Storage o Google Drive';
COMMENT ON COLUMN public.catalogo.caracteristicas IS 'Características clave-valor extra: [{clave, valor}]';
COMMENT ON COLUMN public.catalogo.entregables IS 'Lista de entregables al cliente: ["Video 1080p","Thumbnail"]';

-- ─── VERIFICACIÓN ──────────────────────────────────────────────────────────────
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'catalogo'
ORDER BY ordinal_position;

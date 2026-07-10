// lib/features/prices/models/catalog_item.dart

import 'package:equatable/equatable.dart';
import 'package:kst_business/core/constants/app_constants.dart';

enum TipoCobro {
  fijoPrecio(AppConstants.tipoCobroFijoPrecio, 'Precio Fijo'),
  costoMarkup(AppConstants.tipoCobroCostoMarkup, 'Costo + Margen'),
  tarifaBaseExtras(AppConstants.tipoCobroTarifaBaseExtras, 'Tarifa Base + Extras'),
  porHoraModulo(AppConstants.tipoCobroPorHoraModulo, 'Por Hora / Módulo'),
  montoMasComision(AppConstants.tipoCobroMontoMasComision, 'Monto + Comisión'),
  hibridoCreativo(AppConstants.tipoCobroHibridoCreativo, 'Híbrido Creativo');

  const TipoCobro(this.value, this.label);
  final String value;
  final String label;

  static TipoCobro fromValue(String val) =>
      TipoCobro.values.firstWhere((e) => e.value == val, orElse: () => TipoCobro.fijoPrecio);
}

enum PilarNegocio {
  productosInventario('A', 'KST Infraestructura & Redes'),
  serviciosTecnicos('B', 'KST Soporte & Mantenimiento'),
  proyectosComplexos('C', 'KST Software & Plataformas'),
  microTransacciones('D', 'KST Finanzas & Pagos'),
  serviciosCreativos('E', 'KST Media & Servicios Creativos');

  const PilarNegocio(this.key, this.label);
  final String key;
  final String label;
}

class CatalogItem extends Equatable {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoCobro tipoCobro;
  final PilarNegocio pilar;
  final double precioBase;
  final double? costoProveedor;
  final double? margenPorcentaje;
  final bool activo;
  final String? categoria;
  final String? unidad;
  final String? imagenUrl; // Legacy — use imagenesUrls
  final double? stock;
  final bool esRezago;

  // ── Pilar A: Infraestructura & Redes ─────────────
  final String? marca;
  final String? modelo;
  final String? garantia;
  final String? dimensiones;
  final double? pesoKg;

  // ── Pilar B: Soporte & Mantenimiento ─────────────
  final String? modalidadServicio; // 'remoto'|'presencial'|'hibrido'
  final bool incluyeVisita;
  final double? tarifaHoraExtra;
  final String? duracionEstimada;

  // ── Pilar C: Software & Plataformas ──────────────
  final String? tipoProyecto; // 'web'|'movil'|'desktop'|'api'|'automatizacion'|'erp'|'otro'
  final List<String> tecnologias;
  final List<Map<String, dynamic>> modulos; // [{nombre, descripcion, horas, precio}]
  final double? horasEstimadas;
  final String? garantiaEntrega;
  final bool isPorPuntos;
  final int? puntos;
  final double? tarifaPunto;

  // ── Pilar D: Finanzas & Pagos ─────────────────────
  final double? comisionFija;
  final double? comisionPorcentaje;
  final double? montoMinimo;
  final double? montoMaximo;
  final String? tipoPago; // 'cfe'|'agua'|'telefono'|'recarga'|'transferencia'|'predial'|'seguro'|'otro'

  // ── Pilar E: Media & Creativos ────────────────────
  final String? tipoContenido; // 'video'|'diseno'|'fotografia'|'animacion'|'audio'|'branding'
  final int? revisionesIncluidas;
  final String? tiempoEntrega;
  final List<String> entregables;
  final String? formatoSalida;
  final double? tarifaHoraCreativa;

  // ── Común (todos los pilares) ─────────────────────
  final List<String> imagenesUrls; // Hasta 5 imágenes
  final List<Map<String, dynamic>> caracteristicas; // [{clave, valor}]

  const CatalogItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipoCobro,
    required this.pilar,
    required this.precioBase,
    this.costoProveedor,
    this.margenPorcentaje,
    this.activo = true,
    this.categoria,
    this.unidad,
    this.imagenUrl,
    this.stock = 0.0,
    this.esRezago = false,
    // Pilar A
    this.marca,
    this.modelo,
    this.garantia,
    this.dimensiones,
    this.pesoKg,
    // Pilar B
    this.modalidadServicio,
    this.incluyeVisita = false,
    this.tarifaHoraExtra,
    this.duracionEstimada,
    // Pilar C
    this.tipoProyecto,
    this.tecnologias = const [],
    this.modulos = const [],
    this.horasEstimadas,
    this.garantiaEntrega,
    this.isPorPuntos = false,
    this.puntos,
    this.tarifaPunto,
    // Pilar D
    this.comisionFija,
    this.comisionPorcentaje,
    this.montoMinimo,
    this.montoMaximo,
    this.tipoPago,
    // Pilar E
    this.tipoContenido,
    this.revisionesIncluidas,
    this.tiempoEntrega,
    this.entregables = const [],
    this.formatoSalida,
    this.tarifaHoraCreativa,
    // Common
    this.imagenesUrls = const [],
    this.caracteristicas = const [],
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) => CatalogItem(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String? ?? '',
        tipoCobro: TipoCobro.fromValue(json['tipo_cobro'] as String),
        pilar: PilarNegocio.values.firstWhere(
          (p) => p.key == json['pilar'],
          orElse: () => PilarNegocio.productosInventario,
        ),
        precioBase: (json['precio_base'] as num).toDouble(),
        costoProveedor: _parseDouble(json['costo_proveedor']),
        margenPorcentaje: _parseDouble(json['margen_porcentaje']),
        activo: json['activo'] as bool? ?? true,
        categoria: json['categoria'] as String?,
        unidad: json['unidad'] as String?,
        imagenUrl: json['imagen_url'] as String?,
        stock: _parseDouble(json['stock']) ?? 0.0,
        esRezago: json['es_rezago'] as bool? ?? false,
        // Pilar A
        marca: json['marca'] as String?,
        modelo: json['modelo'] as String?,
        garantia: json['garantia'] as String?,
        dimensiones: json['dimensiones'] as String?,
        pesoKg: _parseDouble(json['peso_kg']),
        // Pilar B
        modalidadServicio: json['modalidad_servicio'] as String?,
        incluyeVisita: json['incluye_visita'] as bool? ?? false,
        tarifaHoraExtra: _parseDouble(json['tarifa_hora_extra']),
        duracionEstimada: json['duracion_estimada'] as String?,
        // Pilar C
        tipoProyecto: json['tipo_proyecto'] as String?,
        tecnologias: _parseStringList(json['tecnologias']),
        modulos: _parseMapList(json['modulos']),
        horasEstimadas: _parseDouble(json['horas_estimadas']),
        garantiaEntrega: json['garantia_entrega'] as String?,
        isPorPuntos: json['es_por_puntos'] as bool? ?? false,
        puntos: json['puntos'] as int?,
        tarifaPunto: _parseDouble(json['tarifa_punto']),
        // Pilar D
        comisionFija: _parseDouble(json['comision_fija']),
        comisionPorcentaje: _parseDouble(json['comision_porcentaje']),
        montoMinimo: _parseDouble(json['monto_minimo']),
        montoMaximo: _parseDouble(json['monto_maximo']),
        tipoPago: json['tipo_pago'] as String?,
        // Pilar E
        tipoContenido: json['tipo_contenido'] as String?,
        revisionesIncluidas: json['revisiones_incluidas'] as int?,
        tiempoEntrega: json['tiempo_entrega'] as String?,
        entregables: _parseStringList(json['entregables']),
        formatoSalida: json['formato_salida'] as String?,
        tarifaHoraCreativa: _parseDouble(json['tarifa_hora_creativa']),
        // Common
        imagenesUrls: _parseStringList(json['imagenes_urls']),
        caracteristicas: _parseMapList(json['caracteristicas']),
      );

  // ── JSON Helpers ─────────────────────────────────────────────────────────────
  static double? _parseDouble(dynamic v) =>
      v != null ? (v as num).toDouble() : null;

  static List<String> _parseStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return const [];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'tipo_cobro': tipoCobro.value,
        'pilar': pilar.key,
        'precio_base': precioBase,
        'costo_proveedor': costoProveedor,
        'margen_porcentaje': margenPorcentaje,
        'activo': activo,
        'categoria': categoria,
        'unidad': unidad,
        'imagen_url': imagenUrl,
        'stock': stock,
        'es_rezago': esRezago,
        // Pilar A
        'marca': marca,
        'modelo': modelo,
        'garantia': garantia,
        'dimensiones': dimensiones,
        'peso_kg': pesoKg,
        // Pilar B
        'modalidad_servicio': modalidadServicio,
        'incluye_visita': incluyeVisita,
        'tarifa_hora_extra': tarifaHoraExtra,
        'duracion_estimada': duracionEstimada,
        // Pilar C
        'tipo_proyecto': tipoProyecto,
        'tecnologias': tecnologias,
        'modulos': modulos,
        'horas_estimadas': horasEstimadas,
        'garantia_entrega': garantiaEntrega,
        'es_por_puntos': isPorPuntos,
        'puntos': puntos,
        'tarifa_punto': tarifaPunto,
        // Pilar D
        'comision_fija': comisionFija,
        'comision_porcentaje': comisionPorcentaje,
        'monto_minimo': montoMinimo,
        'monto_maximo': montoMaximo,
        'tipo_pago': tipoPago,
        // Pilar E
        'tipo_contenido': tipoContenido,
        'revisiones_incluidas': revisionesIncluidas,
        'tiempo_entrega': tiempoEntrega,
        'entregables': entregables,
        'formato_salida': formatoSalida,
        'tarifa_hora_creativa': tarifaHoraCreativa,
        // Common
        'imagenes_urls': imagenesUrls,
        'caracteristicas': caracteristicas,
      };

  CatalogItem copyWith({
    String? nombre,
    String? descripcion,
    TipoCobro? tipoCobro,
    PilarNegocio? pilar,
    double? precioBase,
    double? costoProveedor,
    double? margenPorcentaje,
    bool? activo,
    String? categoria,
    String? unidad,
    String? imagenUrl,
    double? stock,
    bool? esRezago,
    // Pilar A
    String? marca,
    String? modelo,
    String? garantia,
    String? dimensiones,
    double? pesoKg,
    // Pilar B
    String? modalidadServicio,
    bool? incluyeVisita,
    double? tarifaHoraExtra,
    String? duracionEstimada,
    // Pilar C
    String? tipoProyecto,
    List<String>? tecnologias,
    List<Map<String, dynamic>>? modulos,
    double? horasEstimadas,
    String? garantiaEntrega,
    bool? isPorPuntos,
    int? puntos,
    double? tarifaPunto,
    // Pilar D
    double? comisionFija,
    double? comisionPorcentaje,
    double? montoMinimo,
    double? montoMaximo,
    String? tipoPago,
    // Pilar E
    String? tipoContenido,
    int? revisionesIncluidas,
    String? tiempoEntrega,
    List<String>? entregables,
    String? formatoSalida,
    double? tarifaHoraCreativa,
    // Common
    List<String>? imagenesUrls,
    List<Map<String, dynamic>>? caracteristicas,
  }) =>
      CatalogItem(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        tipoCobro: tipoCobro ?? this.tipoCobro,
        pilar: pilar ?? this.pilar,
        precioBase: precioBase ?? this.precioBase,
        costoProveedor: costoProveedor ?? this.costoProveedor,
        margenPorcentaje: margenPorcentaje ?? this.margenPorcentaje,
        activo: activo ?? this.activo,
        categoria: categoria ?? this.categoria,
        unidad: unidad ?? this.unidad,
        imagenUrl: imagenUrl ?? this.imagenUrl,
        stock: stock ?? this.stock,
        esRezago: esRezago ?? this.esRezago,
        marca: marca ?? this.marca,
        modelo: modelo ?? this.modelo,
        garantia: garantia ?? this.garantia,
        dimensiones: dimensiones ?? this.dimensiones,
        pesoKg: pesoKg ?? this.pesoKg,
        modalidadServicio: modalidadServicio ?? this.modalidadServicio,
        incluyeVisita: incluyeVisita ?? this.incluyeVisita,
        tarifaHoraExtra: tarifaHoraExtra ?? this.tarifaHoraExtra,
        duracionEstimada: duracionEstimada ?? this.duracionEstimada,
        tipoProyecto: tipoProyecto ?? this.tipoProyecto,
        tecnologias: tecnologias ?? this.tecnologias,
        modulos: modulos ?? this.modulos,
        horasEstimadas: horasEstimadas ?? this.horasEstimadas,
        garantiaEntrega: garantiaEntrega ?? this.garantiaEntrega,
        isPorPuntos: isPorPuntos ?? this.isPorPuntos,
        puntos: puntos ?? this.puntos,
        tarifaPunto: tarifaPunto ?? this.tarifaPunto,
        comisionFija: comisionFija ?? this.comisionFija,
        comisionPorcentaje: comisionPorcentaje ?? this.comisionPorcentaje,
        montoMinimo: montoMinimo ?? this.montoMinimo,
        montoMaximo: montoMaximo ?? this.montoMaximo,
        tipoPago: tipoPago ?? this.tipoPago,
        tipoContenido: tipoContenido ?? this.tipoContenido,
        revisionesIncluidas: revisionesIncluidas ?? this.revisionesIncluidas,
        tiempoEntrega: tiempoEntrega ?? this.tiempoEntrega,
        entregables: entregables ?? this.entregables,
        formatoSalida: formatoSalida ?? this.formatoSalida,
        tarifaHoraCreativa: tarifaHoraCreativa ?? this.tarifaHoraCreativa,
        imagenesUrls: imagenesUrls ?? this.imagenesUrls,
        caracteristicas: caracteristicas ?? this.caracteristicas,
      );

  /// La primera imagen disponible (para mostrar en cards del catálogo)
  String? get primeraImagen =>
      imagenesUrls.isNotEmpty ? imagenesUrls.first : imagenUrl;

  @override
  List<Object?> get props => [
        id,
        nombre,
        tipoCobro,
        pilar,
        precioBase,
        imagenesUrls,
        stock,
        esRezago,
      ];
}

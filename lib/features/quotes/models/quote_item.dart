// lib/data/models/quote_item.dart

import 'package:equatable/equatable.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
import 'package:kst_business/core/constants/app_constants.dart';

enum UrgencyLevel {
  standard('Estándar', AppConstants.urgencyStandard),
  express('Exprés', AppConstants.urgencyExpress),
  immediate('Inmediata', AppConstants.urgencyImmediate),
  emergency('Emergencia', AppConstants.urgencyEmergency);

  const UrgencyLevel(this.label, this.multiplier);
  final String label;
  final double multiplier;
}

class RequirementDetail extends Equatable {
  final String id;
  final String descripcion;
  final int esfuerzo;
  final int tiempo;
  final int complejidad;
  final int riesgo;
  final int puntos;

  const RequirementDetail({
    required this.id,
    required this.descripcion,
    required this.esfuerzo,
    required this.tiempo,
    required this.complejidad,
    required this.riesgo,
    required this.puntos,
  });

  factory RequirementDetail.fromJson(Map<String, dynamic> json) => RequirementDetail(
        id: json['id'] as String,
        descripcion: json['descripcion'] as String,
        esfuerzo: json['esfuerzo'] as int? ?? 1,
        tiempo: json['tiempo'] as int? ?? 1,
        complejidad: json['complejidad'] as int? ?? 1,
        riesgo: json['riesgo'] as int? ?? 1,
        puntos: json['puntos'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'descripcion': descripcion,
        'esfuerzo': esfuerzo,
        'tiempo': tiempo,
        'complejidad': complejidad,
        'riesgo': riesgo,
        'puntos': puntos,
      };

  @override
  List<Object?> get props => [id, descripcion, esfuerzo, tiempo, complejidad, riesgo, puntos];
}

class QuoteItem extends Equatable {
  final String id;
  final CatalogItem catalogItem;
  final double cantidad;
  final double precioUnitario;
  final double descuentoPorcentaje;
  final UrgencyLevel urgencia;
  final String? notas;

  // Extra fields for pilar-specific logic
  final double? horas;         // POR_HORA_MODULO
  final double? tarifaHora;    // POR_HORA_MODULO
  final double? montoExacto;   // MONTO_MAS_COMISION
  final bool esHorasEdicion;   // HIBRIDO_CREATIVO

  // Point matrix and duration fields
  final bool isPorPuntos;
  final double? tarifaPunto;
  final List<RequirementDetail>? requisitos;
  final bool isPorMinutos;
  final double? duracionMinutos;
  final double? tarifaMinuto;
  final List<dynamic>? materialesAnexados;

  const QuoteItem({
    required this.id,
    required this.catalogItem,
    this.cantidad = 1,
    required this.precioUnitario,
    this.descuentoPorcentaje = 0,
    this.urgencia = UrgencyLevel.standard,
    this.notas,
    this.horas,
    this.tarifaHora,
    this.montoExacto,
    this.esHorasEdicion = false,
    this.isPorPuntos = false,
    this.tarifaPunto,
    this.requisitos,
    this.isPorMinutos = false,
    this.duracionMinutos,
    this.tarifaMinuto,
    this.materialesAnexados,
  });

  /// Calculated subtotal after discount and urgency multiplier
  double get subtotal {
    double base;
    if (isPorPuntos) {
      final totalPuntos = requisitos?.fold<double>(0.0, (s, r) => s + r.puntos) ?? 0.0;
      // Software: base template price + points × point rate
      base = catalogItem.precioBase + (totalPuntos * (tarifaPunto ?? precioUnitario));
    } else if (isPorMinutos) {
      // Video: base template price + minutes × rate per minute
      base = catalogItem.precioBase + ((duracionMinutos ?? 0) * (tarifaMinuto ?? precioUnitario));
    } else {
      switch (catalogItem.tipoCobro) {
        case TipoCobro.porHoraModulo:
          base = (horas ?? cantidad) * (tarifaHora ?? precioUnitario);
          break;
        case TipoCobro.montoMasComision:
          // Micro-transactions dynamic commission based on category/name:
          final amount = montoExacto ?? precioUnitario;
          final cat = catalogItem.categoria?.toLowerCase() ?? '';
          final name = catalogItem.nombre.toLowerCase();
          double commission = 5.0; // Pedidos/General default commission
          
          if (cat.contains('pago') || cat.contains('recibo') || name.contains('recibo') || name.contains('cfe')) {
            commission = 12.0; // Utility Bills (Luz, agua, internet)
          } else if (cat.contains('recarga') || name.contains('recarga')) {
            commission = 0.0;  // Phone Recharges (No commission)
          }
          return amount + commission;
        default:
          base = precioUnitario * cantidad;
      }
    }

    // Apply discount (only if not MONTO_MAS_COMISION)
    final afterDiscount = base * (1 - descuentoPorcentaje / 100);

    // Apply urgency multiplier (only for services, not fixed-price products)
    double afterUrgency = afterDiscount;
    if (catalogItem.pilar != PilarNegocio.productosInventario) {
      afterUrgency = afterDiscount * urgencia.multiplier;
    }

    // Add cost of annexed materials/refacciones (without discount/urgency)
    double materialsCost = 0.0;
    if (materialesAnexados != null) {
      for (var mat in materialesAnexados!) {
        final double matQty = (mat['cantidad'] as num?)?.toDouble() ?? 1.0;
        final double matPrice = (mat['precio_base'] as num?)?.toDouble() ?? 0.0;
        materialsCost += matQty * matPrice;
      }
    }

    return afterUrgency + materialsCost;
  }

  bool get allowsDiscount =>
      catalogItem.tipoCobro != TipoCobro.montoMasComision;

  QuoteItem copyWith({
    double? cantidad,
    double? precioUnitario,
    double? descuentoPorcentaje,
    UrgencyLevel? urgencia,
    String? notas,
    double? horas,
    double? tarifaHora,
    double? montoExacto,
    bool? esHorasEdicion,
    bool? isPorPuntos,
    double? tarifaPunto,
    List<RequirementDetail>? requisitos,
    bool? isPorMinutos,
    double? duracionMinutos,
    double? tarifaMinuto,
    List<dynamic>? materialesAnexados,
  }) =>
      QuoteItem(
        id: id,
        catalogItem: catalogItem,
        cantidad: cantidad ?? this.cantidad,
        precioUnitario: precioUnitario ?? this.precioUnitario,
        descuentoPorcentaje: descuentoPorcentaje ?? this.descuentoPorcentaje,
        urgencia: urgencia ?? this.urgencia,
        notas: notas ?? this.notas,
        horas: horas ?? this.horas,
        tarifaHora: tarifaHora ?? this.tarifaHora,
        montoExacto: montoExacto ?? this.montoExacto,
        esHorasEdicion: esHorasEdicion ?? this.esHorasEdicion,
        isPorPuntos: isPorPuntos ?? this.isPorPuntos,
        tarifaPunto: tarifaPunto ?? this.tarifaPunto,
        requisitos: requisitos ?? this.requisitos,
        isPorMinutos: isPorMinutos ?? this.isPorMinutos,
        duracionMinutos: duracionMinutos ?? this.duracionMinutos,
        tarifaMinuto: tarifaMinuto ?? this.tarifaMinuto,
        materialesAnexados: materialesAnexados ?? this.materialesAnexados,
      );

  @override
  List<Object?> get props => [
        id,
        catalogItem,
        cantidad,
        precioUnitario,
        descuentoPorcentaje,
        urgencia,
        horas,
        tarifaHora,
        montoExacto,
        esHorasEdicion,
        isPorPuntos,
        tarifaPunto,
        requisitos,
        isPorMinutos,
        duracionMinutos,
        tarifaMinuto,
        materialesAnexados,
      ];
}

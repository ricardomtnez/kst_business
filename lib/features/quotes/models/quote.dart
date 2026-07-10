// lib/data/models/quote.dart

import 'package:equatable/equatable.dart';
import 'package:kst_business/features/clients/models/client.dart';
import 'quote_item.dart';

enum QuoteStatus {
  draft('Borrador'),
  sent('Enviada'),
  approved('Aprobada'),
  rejected('Rechazada'),
  expired('Vencida');

  const QuoteStatus(this.label);
  final String label;
}

class Quote extends Equatable {
  final String id;
  final String numero;
  final Client cliente;
  final List<QuoteItem> items;
  final QuoteStatus status;
  final int vigenciaDias;
  final String? notas;
  final String? vendedorId;
  final DateTime creadoEn;
  final DateTime? enviadoEn;
  final String? pdfUrl;

  const Quote({
    required this.id,
    required this.numero,
    required this.cliente,
    required this.items,
    this.status = QuoteStatus.draft,
    this.vigenciaDias = 15,
    this.notas,
    this.vendedorId,
    required this.creadoEn,
    this.enviadoEn,
    this.pdfUrl,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);
  double get iva => subtotal * 0.16;
  double get total => subtotal + iva;

  DateTime get fechaVencimiento =>
      creadoEn.add(Duration(days: vigenciaDias));

  bool get isExpired => DateTime.now().isAfter(fechaVencimiento);

  Quote copyWith({
    List<QuoteItem>? items,
    QuoteStatus? status,
    int? vigenciaDias,
    String? notas,
    String? pdfUrl,
    DateTime? enviadoEn,
  }) =>
      Quote(
        id: id,
        numero: numero,
        cliente: cliente,
        items: items ?? this.items,
        status: status ?? this.status,
        vigenciaDias: vigenciaDias ?? this.vigenciaDias,
        notas: notas ?? this.notas,
        vendedorId: vendedorId,
        creadoEn: creadoEn,
        enviadoEn: enviadoEn ?? this.enviadoEn,
        pdfUrl: pdfUrl ?? this.pdfUrl,
      );

  @override
  List<Object?> get props => [id, numero, cliente, items, status];
}

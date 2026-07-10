// lib/presentation/providers/quote_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/features/quotes/models/quote_item.dart';
import 'package:kst_business/features/clients/models/client.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
// ─── Quote Builder State ─────────────────────────────────────────────────────

class QuoteBuilderState {
  final Client? cliente;
  final List<QuoteItem> items;
  final UrgencyLevel urgencia;
  final int vigenciaDias;
  final String? notas;
  final bool isGenerating;
  final String? errorMsg;

  const QuoteBuilderState({
    this.cliente,
    this.items = const [],
    this.urgencia = UrgencyLevel.standard,
    this.vigenciaDias = 15,
    this.notas,
    this.isGenerating = false,
    this.errorMsg,
  });

  double get subtotal => items.fold(0, (s, i) => s + i.subtotal);
  double get iva => subtotal * 0.16;
  double get total => subtotal + iva;
  bool get isValid => cliente != null && items.isNotEmpty;

  QuoteBuilderState copyWith({
    Client? cliente,
    List<QuoteItem>? items,
    UrgencyLevel? urgencia,
    int? vigenciaDias,
    String? notas,
    bool? isGenerating,
    String? errorMsg,
  }) =>
      QuoteBuilderState(
        cliente: cliente ?? this.cliente,
        items: items ?? this.items,
        urgencia: urgencia ?? this.urgencia,
        vigenciaDias: vigenciaDias ?? this.vigenciaDias,
        notas: notas ?? this.notas,
        isGenerating: isGenerating ?? this.isGenerating,
        errorMsg: errorMsg,
      );
}

class QuoteBuilderNotifier extends StateNotifier<QuoteBuilderState> {
  QuoteBuilderNotifier() : super(const QuoteBuilderState());

  static const _uuid = Uuid();

  // Step 1 – Client
  void setClient(Client client) => state = state.copyWith(cliente: client);
  void clearClient() => state = QuoteBuilderState(
    items: state.items,
    urgencia: state.urgencia,
    vigenciaDias: state.vigenciaDias,
  );

  // Step 2 – Cart
  void addItem(CatalogItem catalogItem) {
    final item = QuoteItem(
      id: _uuid.v4(),
      catalogItem: catalogItem,
      precioUnitario: catalogItem.precioBase,
      urgencia: state.urgencia,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void addConfiguredItem(QuoteItem item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void updateItem(QuoteItem updated) {
    state = state.copyWith(
      items: state.items.map((i) => i.id == updated.id ? updated : i).toList(),
    );
  }

  void removeItem(String itemId) {
    state = state.copyWith(items: state.items.where((i) => i.id != itemId).toList());
  }

  void reorderItems(int oldIndex, int newIndex) {
    final list = [...state.items];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex < oldIndex ? newIndex : newIndex - 1, item);
    state = state.copyWith(items: list);
  }

  // Step 3 – Variables
  void setUrgency(UrgencyLevel level) {
    final updatedItems = state.items.map((i) => i.copyWith(urgencia: level)).toList();
    state = state.copyWith(urgencia: level, items: updatedItems);
  }

  void setVigencia(int days) => state = state.copyWith(vigenciaDias: days);
  void setNotas(String? notas) => state = state.copyWith(notas: notas);

  // Reset
  void reset() => state = const QuoteBuilderState();

  // Generate number
  Future<String> generateQuoteNumber() async {
    final now = DateTime.now();
    final isTicket = state.items.isNotEmpty && state.items.every((i) => i.catalogItem.pilar == PilarNegocio.microTransacciones);
    if (isTicket) {
      return 'TKT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 6).toUpperCase()}';
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    // Get seller initials from name
    final name = user?.userMetadata?['full_name'] as String? ?? 'Ezequiel Velez';
    final parts = name.trim().split(' ');
    String sellerInitials = 'EX';
    if (parts.length >= 2) {
      sellerInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].length >= 2) {
      sellerInitials = parts[0].substring(0, 2).toUpperCase();
    }

    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = 'COT-$sellerInitials$monthStr'; // E.g., COT-EV07
    
    int consecutive = 1;
    try {
      // Find the last quote number for this prefix
      final response = await supabase
          .from('cotizaciones')
          .select('numero')
          .like('numero', '$prefix-%')
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response != null) {
        final lastNumStr = response['numero'] as String;
        final suffixStr = lastNumStr.split('-').last;
        final lastSeq = int.tryParse(suffixStr) ?? 0;
        consecutive = lastSeq + 1;
      }
    } catch (_) {}

    final seqStr = consecutive.toString().padLeft(3, '0'); // E.g., 002
    return '$prefix-$seqStr'; // E.g., COT-EV07-002
  }

  Quote buildQuote(String numero) {
    final isTicket = state.items.isNotEmpty && state.items.every((i) => i.catalogItem.pilar == PilarNegocio.microTransacciones);
    final client = state.cliente ?? (isTicket 
        ? const Client(id: '00000000-0000-0000-0000-000000000000', nombre: 'Operaciones Internas KST', empresa: 'Key Solutions Technology')
        : null);

    return Quote(
      id: _uuid.v4(),
      numero: numero,
      cliente: client!,
      items: state.items,
      status: QuoteStatus.draft,
      vigenciaDias: state.vigenciaDias,
      notas: state.notas,
      creadoEn: DateTime.now(),
    );
  }

  Future<Quote> saveQuoteToSupabase() async {
    final numero = await generateQuoteNumber();
    final quote = buildQuote(numero);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final isTicket = quote.numero.startsWith('TKT-');
    if (isTicket) {
      // Ensure the internal placeholder client exists in the DB
      try {
        final check = await supabase.from('clientes').select('id').eq('id', '00000000-0000-0000-0000-000000000000').maybeSingle();
        if (check == null) {
          await supabase.from('clientes').insert({
            'id': '00000000-0000-0000-0000-000000000000',
            'nombre': 'Operaciones Internas KST',
            'empresa': 'Key Solutions Technology',
          });
        }
      } catch (_) {}
    }

    // 1. Insert parent Quote
    await supabase.from('cotizaciones').insert({
      'id': quote.id,
      'numero': quote.numero,
      'cliente_id': quote.cliente.id,
      'status': isTicket ? 'sent' : 'draft', // Tickets are sent immediately
      'vigencia_dias': quote.vigenciaDias,
      'notas': quote.notas,
      'vendedor_id': user?.id,
      'creado_en': quote.creadoEn.toUtc().toIso8601String(),
    });

    // 2. Insert items
    final itemsJson = quote.items.map((i) {
      return {
        'id': i.id,
        'cotizacion_id': quote.id,
        'catalog_item_id': i.catalogItem.id,
        'cantidad': i.cantidad,
        'precio_unitario': i.precioUnitario,
        'descuento_porcentaje': i.descuentoPorcentaje,
        'urgencia': i.urgencia.name,
        'notas': i.notas,
        'horas': i.horas,
        'tarifa_hora': i.tarifaHora,
        'monto_exacto': i.montoExacto,
        'es_horas_edicion': i.esHorasEdicion,
        'es_por_puntos': i.isPorPuntos,
        'tarifa_punto': i.tarifaPunto,
        'es_por_minutos': i.isPorMinutos,
        'duracion_minutos': i.duracionMinutos,
        'tarifa_minuto': i.tarifaMinuto,
        'detalles_tecnicos': {
          'requisitos': i.requisitos?.map((r) => r.toJson()).toList(),
          'materialesAnexados': i.materialesAnexados,
        },
      };
    }).toList();

    await supabase.from('cotizacion_items').insert(itemsJson);

    // 3. Decrement stock in catalog database for Products and annexed materials
    for (final item in quote.items) {
      if (item.catalogItem.pilar == PilarNegocio.productosInventario) {
        try {
          final res = await supabase.from('catalogo').select('stock').eq('id', item.catalogItem.id).maybeSingle();
          if (res != null) {
            final double currentStock = (res['stock'] as num?)?.toDouble() ?? 0.0;
            final newStock = (currentStock - item.cantidad).clamp(0, double.infinity);
            await supabase.from('catalogo').update({'stock': newStock}).eq('id', item.catalogItem.id);
          }
        } catch (_) {}
      }

      if (item.materialesAnexados != null) {
        for (final mat in item.materialesAnexados!) {
          try {
            final matId = mat['id'] as String;
            final double matQty = (mat['cantidad'] as num?)?.toDouble() ?? 1.0;
            final res = await supabase.from('catalogo').select('stock').eq('id', matId).maybeSingle();
            if (res != null) {
              final double currentStock = (res['stock'] as num?)?.toDouble() ?? 0.0;
              final newStock = (currentStock - matQty).clamp(0, double.infinity);
              await supabase.from('catalogo').update({'stock': newStock}).eq('id', matId);
            }
          } catch (_) {}
        }
      }
    }

    return quote;
  }

  Future<void> convertToJob(String quoteId, String currentFolio) async {
    final supabase = Supabase.instance.client;
    
    // Replace COT- or TKT- with TRB-
    String newFolio = currentFolio;
    if (currentFolio.startsWith('COT-')) {
      newFolio = currentFolio.replaceFirst('COT-', 'TRB-');
    } else if (currentFolio.startsWith('TKT-')) {
      newFolio = currentFolio.replaceFirst('TKT-', 'TRB-');
    } else if (!currentFolio.startsWith('TRB-')) {
      newFolio = 'TRB-$currentFolio';
    }

    await supabase.from('cotizaciones').update({
      'numero': newFolio,
      'status': 'approved',
    }).eq('id', quoteId);
  }
}

final quoteBuilderProvider =
    StateNotifierProvider<QuoteBuilderNotifier, QuoteBuilderState>(
  (ref) => QuoteBuilderNotifier(),
);

final quotesProvider = FutureProvider<List<Quote>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    
    // Fetch quotes along with joined client and item records
    final List<dynamic> rows = await supabase
        .from('cotizaciones')
        .select('*, clientes(*), cotizacion_items(*, catalogo(*))')
        .order('creado_en', ascending: false);
        
    return rows.map<Quote>((r) {
      final clientJson = r['clientes'] as Map<String, dynamic>;
      final client = Client(
        id: clientJson['id'] as String,
        nombre: clientJson['nombre'] as String,
        telefono: clientJson['telefono'] as String?,
        correo: clientJson['correo'] as String?,
        empresa: clientJson['empresa'] as String?,
      );
      
      final itemsList = r['cotizacion_items'] as List<dynamic>;
      final items = itemsList.map<QuoteItem>((i) {
        final catalogJson = i['catalogo'] as Map<String, dynamic>;
        final catalogItem = CatalogItem.fromJson(catalogJson);
        final details = i['detalles_tecnicos'];
        
        List<RequirementDetail>? parsedRequisitos;
        List<dynamic>? parsedMateriales;
        
        if (details != null) {
          if (details is Map) {
            if (details['requisitos'] != null) {
              parsedRequisitos = (details['requisitos'] as List<dynamic>)
                  .map((r) => RequirementDetail.fromJson(r as Map<String, dynamic>))
                  .toList();
            }
            if (details['materialesAnexados'] != null) {
              parsedMateriales = details['materialesAnexados'] as List<dynamic>;
            }
          } else if (details is List) {
            parsedRequisitos = details
                .map((r) => RequirementDetail.fromJson(r as Map<String, dynamic>))
                .toList();
          }
        }

        return QuoteItem(
          id: i['id'] as String,
          catalogItem: catalogItem,
          cantidad: (i['cantidad'] as num).toDouble(),
          precioUnitario: (i['precio_unitario'] as num).toDouble(),
          descuentoPorcentaje: (i['descuento_porcentaje'] as num).toDouble(),
          urgencia: UrgencyLevel.values.firstWhere(
            (u) => u.name == i['urgencia'],
            orElse: () => UrgencyLevel.standard,
          ),
          notas: i['notas'] as String?,
          horas: i['horas'] != null ? (i['horas'] as num).toDouble() : null,
          tarifaHora: i['tarifa_hora'] != null ? (i['tarifa_hora'] as num).toDouble() : null,
          montoExacto: i['monto_exacto'] != null ? (i['monto_exacto'] as num).toDouble() : null,
          esHorasEdicion: i['es_horas_edicion'] as bool? ?? false,
          isPorPuntos: i['es_por_puntos'] as bool? ?? false,
          tarifaPunto: i['tarifa_punto'] != null ? (i['tarifa_punto'] as num).toDouble() : null,
          requisitos: parsedRequisitos,
          isPorMinutos: i['es_por_minutos'] as bool? ?? false,
          duracionMinutos: i['duracion_minutos'] != null ? (i['duracion_minutos'] as num).toDouble() : null,
          tarifaMinuto: i['tarifa_minuto'] != null ? (i['tarifa_minuto'] as num).toDouble() : null,
          materialesAnexados: parsedMateriales,
        );
      }).toList();
      
      final statusStr = r['status'] as String;
      final status = QuoteStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => QuoteStatus.draft,
      );

      return Quote(
        id: r['id'] as String,
        numero: r['numero'] as String,
        cliente: client,
        items: items,
        status: status,
        vigenciaDias: r['vigencia_dias'] as int? ?? 15,
        notas: r['notas'] as String?,
        vendedorId: r['vendedor_id'] as String?,
        creadoEn: DateTime.parse(r['creado_en'] as String).toLocal(),
        enviadoEn: r['enviado_en'] != null ? DateTime.parse(r['enviado_en'] as String).toLocal() : null,
        pdfUrl: r['pdf_url'] as String?,
      );
    }).toList();
  } catch (e) {
    debugPrint("Error fetching quotes from Supabase: $e");
    return <Quote>[];
  }
});

class DashboardStats {
  final int countMonth;
  final double totalSales;
  final int activeClientsCount;
  final int pendingCount;
  final List<Quote> recentQuotes;

  const DashboardStats({
    this.countMonth = 0,
    this.totalSales = 0.0,
    this.activeClientsCount = 0,
    this.pendingCount = 0,
    this.recentQuotes = const [],
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final quotesAsync = await ref.watch(quotesProvider.future);
    
    // Fetch clients count
    final List<dynamic> clientsRes = await supabase.from('clientes').select('id');
    final activeClientsCount = clientsRes.length;
    
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    final monthQuotes = quotesAsync.where((q) => q.creadoEn.isAfter(firstDayOfMonth)).toList();
    final countMonth = monthQuotes.length;
    
    final approvedQuotes = quotesAsync.where((q) => q.status == QuoteStatus.approved).toList();
    final totalSales = approvedQuotes.fold<double>(0.0, (sum, q) => sum + q.total);
    
    final pendingCount = quotesAsync.where((q) => q.status == QuoteStatus.sent || q.status == QuoteStatus.draft).length;
    
    final recentQuotes = quotesAsync.take(5).toList();
    
    return DashboardStats(
      countMonth: countMonth,
      totalSales: totalSales,
      activeClientsCount: activeClientsCount,
      pendingCount: pendingCount,
      recentQuotes: recentQuotes,
    );
  } catch (e) {
    debugPrint("Error calculating dashboard stats: $e");
    return const DashboardStats();
  }
});

// ─── Catalog Search ────────────────────────────────────────────────────────

final catalogSearchQueryProvider = StateProvider<String>((ref) => '');

final catalogItemsProvider = FutureProvider<List<CatalogItem>>((ref) async {
  try {
    final supabase = Supabase.instance.client;
    final rows = await supabase
        .from('catalogo')
        .select()
        .order('pilar')
        .order('nombre');

    return rows.map<CatalogItem>((r) => CatalogItem.fromJson(r)).toList();
  } catch (e) {
    debugPrint("Error fetching catalog: $e");
    return <CatalogItem>[];
  }
});

// Reactive stock decrement based on active builder cart state
final catalogWithLocalStockProvider = Provider<AsyncValue<List<CatalogItem>>>((ref) {
  final catalogAsync = ref.watch(catalogItemsProvider);
  final quoteState = ref.watch(quoteBuilderProvider);

  return catalogAsync.whenData((items) {
    return items.map((item) {
      double cartQty = 0;
      for (final qItem in quoteState.items) {
        if (qItem.catalogItem.id == item.id) {
          cartQty += qItem.cantidad;
        }
        if (qItem.materialesAnexados != null) {
          for (final mat in qItem.materialesAnexados!) {
            if (mat['id'] == item.id) {
              cartQty += (mat['cantidad'] as num?)?.toDouble() ?? 1.0;
            }
          }
        }
      }
      
      if (cartQty > 0) {
        final currentStock = item.stock ?? 0.0;
        final newStock = (currentStock - cartQty).clamp(0.0, double.infinity);
        return item.copyWith(stock: newStock);
      }
      return item;
    }).toList();
  });
});

final filteredCatalogProvider = Provider<AsyncValue<List<CatalogItem>>>((ref) {
  final query = ref.watch(catalogSearchQueryProvider).toLowerCase();
  final catalogAsync = ref.watch(catalogWithLocalStockProvider); // Watched reactively
  return catalogAsync.whenData((items) {
    if (query.isEmpty) return items;
    return items
        .where((i) =>
            i.nombre.toLowerCase().contains(query) ||
            i.categoria?.toLowerCase().contains(query) == true ||
            i.descripcion.toLowerCase().contains(query))
        .toList();
  });
});

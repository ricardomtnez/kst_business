// lib/features/prices/presentation/list_prices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
import 'package:kst_business/features/quotes/models/quote_item.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/widgets/kst_sidebar.dart';
import 'package:kst_business/features/auth/providers/auth_provider.dart';

class ListPricesScreen extends ConsumerStatefulWidget {
  const ListPricesScreen({super.key});

  @override
  ConsumerState<ListPricesScreen> createState() => _ListPricesScreenState();
}

class _ListPricesScreenState extends ConsumerState<ListPricesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  final _pillars = [
    (PilarNegocio.productosInventario, 'KST Infraestructura & Redes'),
    (PilarNegocio.serviciosTecnicos, 'KST Soporte & Mantenimiento'),
    (PilarNegocio.proyectosComplexos, 'KST Software & Plataformas'),
    (PilarNegocio.microTransacciones, 'KST Finanzas & Pagos'),
    (PilarNegocio.serviciosCreativos, 'KST Media & Servicios Creativos'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pillars.length + 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showClearCatalogConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 10),
            Text('¿Vaciar catálogo?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Esto eliminará de forma permanente todos los productos y servicios del catálogo en la base de datos de Supabase. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final supabase = Supabase.instance.client;
                await supabase.from('catalogo').delete().neq('id', '00000000-0000-0000-0000-000000000000');
                ref.invalidate(catalogItemsProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text('Catálogo vaciado con éxito'),
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('Error al vaciar catálogo: $e'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar Todo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showConfigureItemSheet(BuildContext context, CatalogItem catalogItem, {QuoteItem? editItem}) {
    final isEditing = editItem != null;
    final qtyCtrl = TextEditingController(text: isEditing ? editItem.cantidad.toStringAsFixed(0) : '1');
    final priceCtrl = TextEditingController(text: isEditing ? editItem.precioUnitario.toStringAsFixed(2) : catalogItem.precioBase.toStringAsFixed(2));
    final discCtrl = TextEditingController(text: isEditing ? editItem.descuentoPorcentaje.toStringAsFixed(0) : '0');
    final horasCtrl = TextEditingController(text: isEditing ? (editItem.horas?.toStringAsFixed(0) ?? '') : '');
    final tarifaCtrl = TextEditingController(text: isEditing ? (editItem.tarifaHora?.toStringAsFixed(2) ?? '') : '');
    final montoCtrl = TextEditingController(text: isEditing ? (editItem.montoExacto?.toStringAsFixed(2) ?? '') : '');
    final descCtrl = TextEditingController(text: isEditing ? (editItem.notas ?? '') : catalogItem.descripcion);
    final titleCtrl = TextEditingController(text: isEditing ? (editItem.notas?.contains('||') == true ? editItem.notas!.split('||')[0].trim() : catalogItem.nombre) : catalogItem.nombre);
    
    UrgencyLevel selectedUrgency = isEditing ? editItem.urgencia : UrgencyLevel.standard;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Editar Concepto' : 'Configurar Concepto',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título del concepto'),
                ),
                const SizedBox(height: 12),

                if (catalogItem.tipoCobro == TipoCobro.porHoraModulo) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: horasCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Horas/Módulos'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: tarifaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Tarifa/Hora (\$)'),
                        ),
                      ),
                    ],
                  ),
                ] else if (catalogItem.tipoCobro == TipoCobro.montoMasComision) ...[
                  TextField(
                    controller: montoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto Recarga (\$)'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cantidad'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Precio Unitario (\$)'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: discCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Descuento %'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<UrgencyLevel>(
                        initialValue: selectedUrgency,
                        decoration: const InputDecoration(labelText: 'Nivel de Urgencia'),
                        items: UrgencyLevel.values
                            .map((u) => DropdownMenuItem(value: u, child: Text('${u.label} (${u.multiplier.toStringAsFixed(1)}x)')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedUrgency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción / Especificaciones'),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    final parsedQty = double.tryParse(qtyCtrl.text) ?? 1.0;
                    final parsedPrice = double.tryParse(priceCtrl.text) ?? catalogItem.precioBase;
                    final parsedDisc = double.tryParse(discCtrl.text) ?? 0.0;
                    final parsedHoras = double.tryParse(horasCtrl.text);
                    final parsedTarifa = double.tryParse(tarifaCtrl.text);
                    final parsedMonto = double.tryParse(montoCtrl.text);

                    String finalNotes = descCtrl.text.trim();
                    if (titleCtrl.text.trim() != catalogItem.nombre || descCtrl.text.trim() != catalogItem.descripcion) {
                      finalNotes = '${titleCtrl.text.trim()} || ${descCtrl.text.trim()}';
                    }

                    if (isEditing) {
                      final updated = editItem.copyWith(
                        cantidad: parsedQty,
                        precioUnitario: parsedPrice,
                        descuentoPorcentaje: parsedDisc,
                        urgencia: selectedUrgency,
                        horas: parsedHoras,
                        tarifaHora: parsedTarifa,
                        montoExacto: parsedMonto,
                        notas: finalNotes,
                      );
                      ref.read(quoteBuilderProvider.notifier).updateItem(updated);
                    } else {
                      final newItem = QuoteItem(
                        id: const Uuid().v4(),
                        catalogItem: catalogItem,
                        cantidad: parsedQty,
                        precioUnitario: parsedPrice,
                        descuentoPorcentaje: parsedDisc,
                        urgencia: selectedUrgency,
                        horas: parsedHoras,
                        tarifaHora: parsedTarifa,
                        montoExacto: parsedMonto,
                        notas: finalNotes,
                      );
                      ref.read(quoteBuilderProvider.notifier).addConfiguredItem(newItem);
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 800),
                        content: Text('${catalogItem.nombre} agregado a la cotización'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                  child: Text(isEditing ? 'Guardar Cambios' : 'Añadir al Carrito', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogWithLocalStockProvider);
    final quoteState = ref.watch(quoteBuilderProvider);
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;

    Color pColor(PilarNegocio p) => switch (p) {
          PilarNegocio.productosInventario => AppColors.secondary,
          PilarNegocio.serviciosTecnicos => AppColors.accent,
          PilarNegocio.proyectosComplexos => AppColors.info,
          PilarNegocio.microTransacciones => AppColors.warning,
          PilarNegocio.serviciosCreativos => AppColors.success,
        };

    return Scaffold(
      backgroundColor: AppColors.primary,
      drawer: const KstSidebar(),
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 26),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(quoteBuilderProvider).items.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded, size: 24),
                    onPressed: () => context.pushNamed('cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'clear') {
                  _showClearCatalogConfirmation(context);
                } else if (val == 'deleted') {
                  context.pushNamed('deleted-products');
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'deleted',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Productos Eliminados'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Vaciar Catálogo', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.secondary,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            const Tab(text: 'Todos'),
            const Tab(text: 'Rezago (Ofertas)'),
            ..._pillars.map((p) => Tab(text: p.$2)),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? Padding(
              padding: EdgeInsets.only(bottom: quoteState.items.isNotEmpty ? 68.0 : 0.0),
              child: FloatingActionButton.extended(
                onPressed: () => context.pushNamed('register-product'),
                backgroundColor: AppColors.secondary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
      bottomNavigationBar: quoteState.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  )
                ],
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${quoteState.items.length} Concepto(s) en cotización',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total parcial: ${_fmt.format(quoteState.total)}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.pushNamed('cart'),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 18, color: Colors.white),
                    label: const Text('Ver Carrito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar catálogo: $e', style: const TextStyle(color: AppColors.textSecondary)),
              TextButton(onPressed: () => ref.invalidate(catalogItemsProvider), child: const Text('Reintentar')),
            ],
          ),
        ),
        data: (items) {
          final query = _searchController.text.toLowerCase();
          final filteredItems = items.where((i) => i.activo && i.nombre.toLowerCase().contains(query)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Todos
              _buildCatalogList(context, filteredItems, pColor, isAdmin),
              // 2. Rezago
              _buildCatalogList(context, filteredItems.where((i) => i.esRezago).toList(), pColor, isAdmin),
              // 3..7 Pillars
              ..._pillars.map((p) => _buildCatalogList(
                    context,
                    filteredItems.where((i) => i.pilar == p.$1).toList(),
                    pColor,
                    isAdmin,
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPilarSpecificDetails(CatalogItem item, Color color) {
    final style = const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
    final iconColor = color.withValues(alpha: 0.8);

    Widget buildTag(IconData icon, String text, {Color? bg, Color? textCol}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg ?? Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bg != null ? Colors.transparent : AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textCol ?? iconColor),
            const SizedBox(width: 4),
            Text(text, style: style.copyWith(color: textCol ?? AppColors.textPrimary)),
          ],
        ),
      );
    }

    List<Widget> children = [];

    switch (item.pilar) {
      case PilarNegocio.productosInventario:
        if (item.marca != null && item.marca!.isNotEmpty) {
          children.add(buildTag(Icons.branding_watermark_outlined, item.marca!));
        }
        if (item.modelo != null && item.modelo!.isNotEmpty) {
          children.add(buildTag(Icons.mode_edit_outline_outlined, item.modelo!));
        }
        if (item.garantia != null && item.garantia!.isNotEmpty) {
          children.add(buildTag(Icons.verified_user_outlined, item.garantia!));
        }
        if (item.dimensiones != null && item.dimensiones!.isNotEmpty) {
          children.add(buildTag(Icons.aspect_ratio_outlined, item.dimensiones!));
        }
        if (item.pesoKg != null) {
          children.add(buildTag(Icons.scale_outlined, '${item.pesoKg} Kg'));
        }
        final double stock = item.stock ?? 0.0;
        if (stock > 0) {
          children.add(buildTag(
            Icons.inventory_2_outlined,
            'Stock: ${stock.toStringAsFixed(0)} ${item.unidad ?? "pza"}',
            bg: Colors.green.withValues(alpha: 0.1),
            textCol: Colors.green[800],
          ));
        } else {
          children.add(buildTag(
            Icons.inventory_2_outlined,
            'Agotado',
            bg: Colors.red.withValues(alpha: 0.1),
            textCol: Colors.red[800],
          ));
        }
        break;

      case PilarNegocio.serviciosTecnicos:
        if (item.modalidadServicio != null) {
          final mod = item.modalidadServicio!;
          final icon = mod == 'remoto'
              ? Icons.laptop_chromebook_outlined
              : (mod == 'presencial' ? Icons.business_outlined : Icons.home_work_outlined);
          final label = mod.toUpperCase();
          children.add(buildTag(icon, label));
        }
        children.add(buildTag(
          item.incluyeVisita ? Icons.check_circle_outline : Icons.info_outline,
          item.incluyeVisita ? 'Visita Incluida' : 'No incluye visita',
        ));
        if (item.tarifaHoraExtra != null && item.tarifaHoraExtra! > 0) {
          children.add(buildTag(Icons.add_alarm_rounded, 'Hora extra: \$${item.tarifaHoraExtra!.toStringAsFixed(0)}'));
        }
        if (item.duracionEstimada != null && item.duracionEstimada!.isNotEmpty) {
          children.add(buildTag(Icons.timer_outlined, item.duracionEstimada!));
        }
        break;

      case PilarNegocio.proyectosComplexos:
        if (item.tipoProyecto != null) {
          final tp = item.tipoProyecto!;
          final icon = tp == 'web'
              ? Icons.web_rounded
              : (tp == 'movil' ? Icons.phone_android_rounded : Icons.desktop_windows_outlined);
          children.add(buildTag(icon, tp.toUpperCase()));
        }
        if (item.garantiaEntrega != null && item.garantiaEntrega!.isNotEmpty) {
          children.add(buildTag(Icons.shield_outlined, item.garantiaEntrega!));
        }
        if (item.horasEstimadas != null && item.horasEstimadas! > 0) {
          children.add(buildTag(Icons.hourglass_empty_rounded, '~${item.horasEstimadas!.toStringAsFixed(0)} hrs'));
        }
        if (item.modulos.isNotEmpty) {
          children.add(buildTag(Icons.view_module_outlined, '${item.modulos.length} módulos'));
        }
        if (item.tecnologias.isNotEmpty) {
          for (final tech in item.tecnologias) {
            children.add(Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tech,
                style: style.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 9),
              ),
            ));
          }
        }
        break;

      case PilarNegocio.microTransacciones:
        if (item.comisionFija != null || item.comisionPorcentaje != null) {
          final fija = item.comisionFija ?? 0.0;
          final pct = item.comisionPorcentaje ?? 0.0;
          String label = '';
          if (fija > 0 && pct > 0) {
            label = 'Comisión: \$${fija.toStringAsFixed(2)} + ${pct.toStringAsFixed(1)}%';
          } else if (fija > 0) {
            label = 'Comisión: \$${fija.toStringAsFixed(2)}';
          } else if (pct > 0) {
            label = 'Comisión: ${pct.toStringAsFixed(1)}%';
          } else {
            label = 'Sin comisión';
          }
          children.add(buildTag(Icons.percent_rounded, label));
        }
        if (item.montoMinimo != null && item.montoMaximo != null) {
          children.add(buildTag(
            Icons.swap_vert_rounded,
            'Límites: \$${item.montoMinimo!.toStringAsFixed(0)} - \$${item.montoMaximo!.toStringAsFixed(0)}',
          ));
        }
        if (item.tipoPago != null) {
          children.add(buildTag(Icons.payment_rounded, 'Tipo: ${item.tipoPago!.toUpperCase()}'));
        }
        break;

      case PilarNegocio.serviciosCreativos:
        if (item.tipoContenido != null) {
          children.add(buildTag(Icons.palette_outlined, item.tipoContenido!.toUpperCase()));
        }
        if (item.revisionesIncluidas != null) {
          children.add(buildTag(Icons.rate_review_outlined, '${item.revisionesIncluidas} revisiones'));
        }
        if (item.tiempoEntrega != null && item.tiempoEntrega!.isNotEmpty) {
          children.add(buildTag(Icons.local_shipping_outlined, item.tiempoEntrega!));
        }
        if (item.formatoSalida != null && item.formatoSalida!.isNotEmpty) {
          children.add(buildTag(Icons.insert_drive_file_outlined, item.formatoSalida!));
        }
        if (item.entregables.isNotEmpty) {
          for (final ent in item.entregables) {
            children.add(Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ent,
                style: style.copyWith(fontSize: 9),
              ),
            ));
          }
        }
        break;
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }

  Widget _buildCatalogList(BuildContext context, List<CatalogItem> items, Color Function(PilarNegocio) pillarColor, bool isAdmin) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(catalogItemsProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            const Center(
              child: Text('Sin productos en esta categoría', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
    }

    final quoteState = ref.watch(quoteBuilderProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(catalogItemsProvider.future),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        itemBuilder: (ctx, idx) {
        final item = items[idx];
        final color = pillarColor(item.pilar);
        
        final existingItemIndex = quoteState.items.indexWhere((i) => i.catalogItem.id == item.id);
        final inCart = existingItemIndex >= 0;
        final cartQty = inCart ? quoteState.items[existingItemIndex].cantidad : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image or icon placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: color.withValues(alpha: 0.08),
                        child: item.primeraImagen != null
                            ? CachedNetworkImage(
                                imageUrl: item.primeraImagen!,
                                fit: BoxFit.cover,
                                errorWidget: (ctx, url, e) => Icon(Icons.image_outlined, color: color, size: 28),
                                placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : Icon(Icons.image_outlined, color: color, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          _buildPilarSpecificDetails(item, color),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt.format(item.precioBase),
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color),
                              ),
                              if (item.esRezago)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('OFERTA REZAGO', style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Edit Action for admin
              if (isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => context.pushNamed('register-product', extra: item),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                      child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ),

              // Card controls on bottom right
              Positioned(
                bottom: 8,
                right: 8,
                child: inCart
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 18),
                            onPressed: () => _showConfigureItemSheet(context, item, editItem: quoteState.items[existingItemIndex]),
                          ),
                          Text(
                            'x${cartQty.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      )
                    : TextButton.icon(
                        onPressed: () => _showConfigureItemSheet(context, item),
                        icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.secondary),
                        label: const Text('Cotizar', style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (idx * 40).ms).slideX(begin: 0.04);
      },
    ),
  );
}
}

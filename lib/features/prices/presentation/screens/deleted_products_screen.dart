// lib/features/prices/presentation/screens/deleted_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';

class DeletedProductsScreen extends ConsumerStatefulWidget {
  const DeletedProductsScreen({super.key});

  @override
  ConsumerState<DeletedProductsScreen> createState() => _DeletedProductsScreenState();
}

class _DeletedProductsScreenState extends ConsumerState<DeletedProductsScreen> {
  bool _loading = false;
  List<CatalogItem> _deletedItems = [];
  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _loading = true);
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('catalogo')
          .select()
          .eq('activo', false)
          .order('nombre');

      setState(() {
        _deletedItems = rows.map<CatalogItem>((r) => CatalogItem.fromJson(r)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al cargar papelera: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _restoreProduct(CatalogItem item) async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client
          .from('catalogo')
          .update({'activo': true})
          .eq('id', item.id);

      ref.invalidate(catalogItemsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${item.nombre} restaurado con éxito'),
          ),
        );
      }
      await _loadDeletedItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al restaurar: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _permanentDeleteProduct(CatalogItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('¿Eliminar permanentemente?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('Esto eliminará físicamente a "${item.nombre}" de la base de datos. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar para siempre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client
          .from('catalogo')
          .delete()
          .eq('id', item.id);

      ref.invalidate(catalogItemsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('${item.nombre} eliminado permanentemente'),
          ),
        );
      }
      await _loadDeletedItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error al eliminar: $e')),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color pColor(PilarNegocio p) => switch (p) {
          PilarNegocio.productosInventario => AppColors.secondary,
          PilarNegocio.serviciosTecnicos => AppColors.accent,
          PilarNegocio.proyectosComplexos => AppColors.info,
          PilarNegocio.microTransacciones => AppColors.warning,
          PilarNegocio.serviciosCreativos => AppColors.success,
        };

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Papelera de Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDeletedItems,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
          : _deletedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      const Text(
                        'La papelera está vacía',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _deletedItems.length,
                  itemBuilder: (ctx, i) {
                    final item = _deletedItems[i];
                    final color = pColor(item.pilar);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.inventory_2_outlined, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.categoria ?? item.pilar.label,
                                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Precio: ${_fmt.format(item.precioBase)}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.success),
                              tooltip: 'Restaurar',
                              onPressed: () => _restoreProduct(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                              tooltip: 'Eliminar permanentemente',
                              onPressed: () => _permanentDeleteProduct(item),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 40).ms).slideX(begin: 0.04);
                  },
                ),
    );
  }
}

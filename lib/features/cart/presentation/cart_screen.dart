// lib/features/cart/presentation/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(quoteBuilderProvider).items;
    final state = ref.watch(quoteBuilderProvider);
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    Color pilarColor(dynamic p) {
      final str = p.toString();
      if (str.contains('productosInventario')) return AppColors.secondary;
      if (str.contains('serviciosTecnicos')) return AppColors.accent;
      if (str.contains('proyectosComplexos')) return AppColors.info;
      if (str.contains('microTransacciones')) return AppColors.warning;
      return AppColors.success;
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Carrito de Cotización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.goNamed('prices'),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(quoteBuilderProvider.notifier).reset(),
              child: const Text(
                'Vaciar',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pushNamed('prices'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    child: const Text('Ver Catálogo', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final color = pilarColor(item.catalogItem.pilar);
                      
                      String title = item.catalogItem.nombre;
                      String desc = item.catalogItem.descripcion;
                      final notes = item.notas;
                      if (notes != null && notes.contains('||')) {
                        final parts = notes.split('||');
                        title = parts[0].trim();
                        desc = parts[1].trim();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(Icons.description_outlined, color: color, size: 20),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.catalogItem.pilar.label,
                                  style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(fmt.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.catalogItem.tipoCobro == TipoCobro.porHoraModulo
                                        ? '${item.horas?.toStringAsFixed(0)} hrs x ${fmt.format(item.tarifaHora)}'
                                        : '${item.cantidad.toStringAsFixed(0)} ${item.catalogItem.unidad ?? "pza"} x ${fmt.format(item.precioUnitario)}',
                                    style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                onPressed: () => ref.read(quoteBuilderProvider.notifier).removeItem(item.id),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.05);
                    },
                  ),
                ),
                
                // Totals and Checkout Card
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)),
                          Text(fmt.format(state.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('IVA (16%):', style: TextStyle(color: AppColors.textSecondary)),
                          Text(fmt.format(state.iva), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          Text(fmt.format(state.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed('checkout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white),
                          label: const Text(
                            'Continuar al Checkout',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

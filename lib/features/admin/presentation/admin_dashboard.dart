// lib/features/admin/presentation/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/widgets/stat_card.dart';
import 'package:kst_business/core/widgets/gradient_button.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({
    super.key,
    required this.statsAsync,
    required this.catalogAsync,
    required this.currencyFmt,
  });

  final AsyncValue<DashboardStats> statsAsync;
  final AsyncValue<List<dynamic>> catalogAsync;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogItems = catalogAsync.valueOrNull ?? [];
    
    // Filter items with stock <= 5 for stock alerts
    final lowStockItems = catalogItems
        .where((item) => item.pilar.key == 'A' && item.stock != null && item.stock! <= 5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Quick Action Button Row
        Row(
          children: [
            Expanded(
              child: GradientButton(
                label: 'Agregar Producto',
                icon: Icons.add_to_photos_rounded,
                onPressed: () => context.pushNamed('register-product'),
                height: 52,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.pushNamed('prices'),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: const Text('Ver Catálogo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  foregroundColor: AppColors.secondary,
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 28),

        // Statistics Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estadísticas Globales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
              onPressed: () {
                ref.invalidate(quotesProvider);
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(catalogItemsProvider);
              },
            ),
          ],
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 12),

        // Statistics Grid
        statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (stats) => GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              StatCard(
                title: 'Ventas aprobadas',
                value: currencyFmt.format(stats.totalSales),
                icon: Icons.monetization_on_outlined,
                color: AppColors.success,
                subtitle: 'Facturado global',
              ),
              StatCard(
                title: 'Cotizaciones del mes',
                value: '${stats.countMonth}',
                icon: Icons.analytics_outlined,
                color: AppColors.secondary,
                subtitle: 'Creadas en sistema',
                onTap: () => context.pushNamed('quotes'),
              ),
              StatCard(
                title: 'Clientes registrados',
                value: '${stats.activeClientsCount}',
                icon: Icons.people_outline_rounded,
                color: AppColors.accent,
                onTap: () => context.pushNamed('clients'),
              ),
              StatCard(
                title: 'Items en Catálogo',
                value: '${catalogItems.length}',
                icon: Icons.inventory_2_outlined,
                color: AppColors.info,
                subtitle: 'Servicios e inventario',
                onTap: () => context.pushNamed('prices'),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 28),

        // LOW STOCK ALERTS SECTION
        const Text(
          'Alertas de Inventario (Bajo Stock)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),

        if (lowStockItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todos los productos de inventario cuentan con stock suficiente.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStockItems.length,
            itemBuilder: (context, idx) {
              final item = lowStockItems[idx];
              final double stockVal = item.stock ?? 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                          Text('Quedan solo ${stockVal.toStringAsFixed(0)} unidades', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }
}

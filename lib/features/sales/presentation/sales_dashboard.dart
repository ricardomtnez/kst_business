// lib/features/sales/presentation/sales_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/widgets/stat_card.dart';

class SalesDashboard extends ConsumerWidget {
  const SalesDashboard({
    super.key,
    required this.statsAsync,
    required this.currencyFmt,
  });

  final AsyncValue<DashboardStats> statsAsync;
  final NumberFormat currencyFmt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mis Estadísticas',
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
              },
            ),
          ],
        ).animate().fadeIn(delay: 50.ms),
        const SizedBox(height: 12),

        // Stats Grid
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
                title: 'Mis ventas cerradas',
                value: currencyFmt.format(stats.totalSales),
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                subtitle: 'Estado Aprobadas',
              ),
               StatCard(
                title: 'Cotizaciones del mes',
                value: '${stats.countMonth}',
                icon: Icons.description_outlined,
                color: AppColors.secondary,
                subtitle: 'Creadas este mes',
                onTap: () => context.pushNamed('quotes'),
              ),
              StatCard(
                title: 'Clientes activos',
                value: '${stats.activeClientsCount}',
                icon: Icons.people_outline_rounded,
                color: AppColors.accent,
                onTap: () => context.pushNamed('clients'),
              ),
              StatCard(
                title: 'Pendientes de firma',
                value: '${stats.pendingCount}',
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                subtitle: 'Borrador o enviadas',
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 28),

        // Recent quotes
        const Text(
          'Mis Últimas Cotizaciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 12),

        _buildRecentQuotesList(statsAsync, currencyFmt).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 80), // Spacer to avoid covering items with the FAB
      ],
    );
  }

  Widget _buildRecentQuotesList(AsyncValue<DashboardStats> statsAsync, NumberFormat currencyFmt) {
    return statsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error al cargar cotizaciones: $e')),
      data: (stats) {
        if (stats.recentQuotes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Center(
              child: Text(
                'No hay cotizaciones registradas aún.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          );
        }
        
        return Column(
          children: stats.recentQuotes.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            
            final Color statusCol = switch (q.status) {
              QuoteStatus.draft => AppColors.textSecondary,
              QuoteStatus.sent => AppColors.info,
              QuoteStatus.approved => AppColors.success,
              QuoteStatus.rejected => AppColors.error,
              QuoteStatus.expired => AppColors.warning,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusCol.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined, color: statusCol, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.cliente.nombre,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          q.numero,
                          style: const TextStyle(
                            color: AppColors.textSecondary, 
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFmt.format(q.total),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusCol.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          q.status.label,
                          style: TextStyle(
                            color: statusCol, 
                            fontSize: 9.5, 
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.03);
          }).toList(),
        );
      },
    );
  }
}

// lib/features/quotes/presentation/screens/quote_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/utils/pdf_generator.dart';

class QuoteHistoryScreen extends ConsumerWidget {
  const QuoteHistoryScreen({super.key});

  void _showQuoteDetailsSheet(BuildContext context, WidgetRef ref, Quote q) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final isAlreadyJob = q.status == QuoteStatus.approved || q.numero.startsWith('TRB-');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAlreadyJob ? 'Detalle de Trabajo' : 'Detalle de Cotización',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Folio:', q.numero),
            _buildDetailRow('Cliente:', q.cliente.nombre),
            if (q.cliente.empresa != null) _buildDetailRow('Empresa:', q.cliente.empresa!),
            _buildDetailRow('Fecha:', dateFmt.format(q.creadoEn)),
            _buildDetailRow('Vigencia:', '${q.vigenciaDias} días'),
            _buildDetailRow('Total:', fmt.format(q.total)),
            _buildDetailRow('Estado:', q.status.label),
            if (q.notas != null && q.notas!.isNotEmpty) _buildDetailRow('Notas:', q.notas!),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final pdfBytes = await PdfGenerator.generate(q);
                      await Printing.sharePdf(bytes: pdfBytes, filename: 'cotizacion_${q.numero}.pdf');
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir PDF'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.secondary),
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ),
                if (!isAlreadyJob) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('¿Convertir en Trabajo?'),
                            content: Text('Esto actualizará el folio a TRB-${q.numero.split('-').skip(1).join('-')} y cambiará el estado a aprobado.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await ref.read(quoteBuilderProvider.notifier).convertToJob(q.id, q.numero);
                            ref.invalidate(quotesProvider);
                            ref.invalidate(dashboardStatsProvider);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.success,
                                  content: Text('Cotización convertida en Trabajo con éxito ✓'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.construction_rounded, color: Colors.white),
                      label: const Text('Convertir a Trabajo', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final quotesAsync = ref.watch(quotesProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    Color statusColor(QuoteStatus s) => switch (s) {
          QuoteStatus.draft => AppColors.textSecondary,
          QuoteStatus.sent => AppColors.info,
          QuoteStatus.approved => AppColors.success,
          QuoteStatus.rejected => AppColors.error,
          QuoteStatus.expired => AppColors.warning,
        };

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Historial de Cotizaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.goNamed('dashboard'),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartCount = ref.watch(quoteBuilderProvider).items.length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_rounded),
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('prices'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva'),
        backgroundColor: AppColors.secondary,
      ),
      body: quotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error al cargar cotizaciones', style: Theme.of(context).textTheme.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(quotesProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (quotes) {
          if (quotes.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                final _ = await ref.refresh(quotesProvider.future);
                ref.invalidate(dashboardStatsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Icon(Icons.description_outlined, color: AppColors.textDisabled, size: 56),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Sin cotizaciones registradas',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pushNamed('prices'),
                      child: const Text('Crear primera cotización'),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final _ = await ref.refresh(quotesProvider.future);
              ref.invalidate(dashboardStatsProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: quotes.length,
            itemBuilder: (ctx, i) {
              final q = quotes[i];
              final status = q.status;
              final color = statusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: ListTile(
                  onTap: () => _showQuoteDetailsSheet(context, ref, q),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined, color: color, size: 22),
                  ),
                  title: Text(q.cliente.nombre,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.numero,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      Text(dateFmt.format(q.creadoEn),
                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(fmt.format(q.total),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status.label,
                            style: TextStyle(
                                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.04);
            },
          ),
        );
      },
      ),
    );
  }
}

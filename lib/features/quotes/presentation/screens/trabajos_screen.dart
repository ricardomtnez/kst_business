// lib/features/quotes/presentation/screens/trabajos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/utils/pdf_generator.dart';

class TrabajosScreen extends ConsumerStatefulWidget {
  const TrabajosScreen({super.key});

  @override
  ConsumerState<TrabajosScreen> createState() => _TrabajosScreenState();
}

class _TrabajosScreenState extends ConsumerState<TrabajosScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(quotesProvider);
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Trabajos Activos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por folio o cliente...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: quotesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Error al cargar trabajos', style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => ref.invalidate(quotesProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (quotes) {
                // Filter jobs: status approved or starts with TRB-
                final jobs = quotes.where((q) => q.status == QuoteStatus.approved || q.numero.startsWith('TRB-')).toList();

                final filtered = _query.isEmpty
                    ? jobs
                    : jobs
                        .where((j) =>
                            j.cliente.nombre.toLowerCase().contains(_query) ||
                            j.numero.toLowerCase().contains(_query) ||
                            (j.cliente.empresa?.toLowerCase().contains(_query) ?? false))
                        .toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      final _ = await ref.refresh(quotesProvider.future);
                      ref.invalidate(dashboardStatsProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Icon(Icons.construction_outlined, color: AppColors.textDisabled, size: 56),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _query.isEmpty ? 'Sin trabajos registrados' : 'Sin resultados',
                            style: const TextStyle(color: AppColors.textSecondary),
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
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final job = filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.construction_rounded, color: AppColors.success, size: 22),
                        ),
                        title: Text(
                          job.cliente.nombre,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.numero, style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(dateFmt.format(job.creadoEn), style: const TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  fmt.format(job.total),
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TRABAJO',
                                    style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, color: AppColors.secondary),
                              tooltip: 'Compartir PDF',
                              onPressed: () async {
                                final pdfBytes = await PdfGenerator.generate(job);
                                await Printing.sharePdf(bytes: pdfBytes, filename: 'trabajo_${job.numero}.pdf');
                              },
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
          ),
        ],
      ),
    );
  }
}

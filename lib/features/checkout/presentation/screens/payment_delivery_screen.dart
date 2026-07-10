// lib/features/checkout/presentation/screens/payment_delivery_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/clients/models/client.dart';
import 'package:kst_business/features/quotes/models/quote.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/widgets/gradient_button.dart';
import 'package:kst_business/core/utils/pdf_generator.dart';
import 'package:kst_business/features/clients/presentation/clients_screen.dart' show clientsProvider;

class PaymentDeliveryScreen extends ConsumerStatefulWidget {
  const PaymentDeliveryScreen({super.key});

  @override
  ConsumerState<PaymentDeliveryScreen> createState() => _PaymentDeliveryScreenState();
}

class _PaymentDeliveryScreenState extends ConsumerState<PaymentDeliveryScreen> {
  final _clientSearchCtrl = TextEditingController();
  final _vigenciaCtrl = TextEditingController(text: '15');
  final _notasCtrl = TextEditingController();

  // New Client Fields
  final _nameCtrl = TextEditingController();
  final _empresaCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _showNewClientForm = false;
  bool _generating = false;
  bool _showClientDropdown = false;
  String _clientQuery = '';
  final _fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

  @override
  void dispose() {
    _clientSearchCtrl.dispose();
    _vigenciaCtrl.dispose();
    _notasCtrl.dispose();
    _nameCtrl.dispose();
    _empresaCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _createNewClient() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final id = const Uuid().v4();
    final client = Client(
      id: id,
      nombre: _nameCtrl.text.trim(),
      telefono: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      correo: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      empresa: _empresaCtrl.text.trim().isEmpty ? null : _empresaCtrl.text.trim(),
    );
    try {
      await Supabase.instance.client.from('clientes').insert({
        'id': id,
        'nombre': client.nombre,
        'telefono': client.telefono,
        'correo': client.correo,
        'empresa': client.empresa,
      });
      if (!mounted) return;
      ref.invalidate(clientsProvider);
      ref.read(quoteBuilderProvider.notifier).setClient(client);
      setState(() {
        _showNewClientForm = false;
        _nameCtrl.clear();
        _empresaCtrl.clear();
        _phoneCtrl.clear();
        _emailCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente guardado y seleccionado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Error al crear cliente: $e')),
      );
    }
  }

  Future<void> _submitQuotation() async {
    final state = ref.read(quoteBuilderProvider);
    if (state.cliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.error, content: Text('Por favor selecciona un cliente')),
      );
      return;
    }
    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: AppColors.error, content: Text('Agrega al menos un concepto a la cotización')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      // Set parameters
      ref.read(quoteBuilderProvider.notifier).setVigencia(int.tryParse(_vigenciaCtrl.text) ?? 15);
      ref.read(quoteBuilderProvider.notifier).setNotas(_notasCtrl.text.trim());

      // 1. Save quote to Supabase
      final quote = await ref.read(quoteBuilderProvider.notifier).saveQuoteToSupabase();

      // 2. Generate PDF bytes
      final pdfBytes = await PdfGenerator.generate(quote);

      // 3. Upload to storage
      final fileName = 'cotizacion_${quote.id}.pdf';
      final filePath = 'quotes/$fileName';
      await Supabase.instance.client.storage.from('quotes').uploadBinary(
            filePath,
            pdfBytes,
            fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage.from('quotes').getPublicUrl(filePath);

      // 4. Update url in db
      await Supabase.instance.client
          .from('cotizaciones')
          .update({'pdf_url': publicUrl})
          .eq('id', quote.id);

      ref.invalidate(quotesProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.read(quoteBuilderProvider.notifier).reset();

      if (mounted) {
        _showSuccessDialog(quote.copyWith(pdfUrl: publicUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.error, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  void _showSuccessDialog(Quote quote) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('¡Éxito!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cotización ${quote.numero} generada y guardada correctamente.',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            const Text('¿Qué deseas hacer ahora?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.goNamed('dashboard');
            },
            child: const Text('Ir al Inicio'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final pdfBytes = await PdfGenerator.generate(quote);
              await Printing.sharePdf(bytes: pdfBytes, filename: 'cotizacion_${quote.numero}.pdf');
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Compartir PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quoteBuilderProvider);
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Configurar Propuesta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.goNamed('cart'),
        ),
      ),
      body: _generating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando y generando propuesta...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── CLIENT SELECTOR ───
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 10),
                          if (state.cliente != null) ...[
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                                  child: Text(state.cliente!.initials, style: const TextStyle(color: AppColors.secondary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(state.cliente!.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (state.cliente!.empresa != null)
                                        Text(state.cliente!.empresa!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref.read(quoteBuilderProvider.notifier).clearClient(),
                                  child: const Text('Cambiar'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _clientSearchCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Buscar por nombre o empresa...',
                                      prefixIcon: Icon(Icons.search),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _clientQuery = val.toLowerCase();
                                        _showClientDropdown = val.isNotEmpty;
                                        _showNewClientForm = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Nuevo'),
                                  onPressed: () => setState(() => _showNewClientForm = !_showNewClientForm),
                                ),
                              ],
                            ),
                            
                            if (_showClientDropdown)
                              clientsAsync.when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text('Error: $e'),
                                data: (clients) {
                                  final filtered = clients
                                      .where((c) =>
                                          c.nombre.toLowerCase().contains(_clientQuery) ||
                                          (c.empresa?.toLowerCase().contains(_clientQuery) ?? false))
                                      .toList();

                                  if (filtered.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text('No se encontraron clientes', style: TextStyle(color: AppColors.textSecondary)),
                                    );
                                  }

                                  return Container(
                                    constraints: const BoxConstraints(maxHeight: 180),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.surfaceBorder),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      itemBuilder: (ctx, i) {
                                        final c = filtered[i];
                                        return ListTile(
                                          title: Text(c.nombre, style: const TextStyle(fontSize: 13)),
                                          subtitle: c.empresa != null ? Text(c.empresa!, style: const TextStyle(fontSize: 11)) : null,
                                          onTap: () {
                                            ref.read(quoteBuilderProvider.notifier).setClient(c);
                                            setState(() {
                                              _showClientDropdown = false;
                                              _clientSearchCtrl.clear();
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),

                            if (_showNewClientForm)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: [
                                    const Divider(),
                                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nombre completo (Requerido)')),
                                    const SizedBox(height: 8),
                                    TextField(controller: _empresaCtrl, decoration: const InputDecoration(labelText: 'Empresa')),
                                    const SizedBox(height: 8),
                                    TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
                                    const SizedBox(height: 8),
                                    TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Correo electrónico')),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => setState(() => _showNewClientForm = false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: _createNewClient,
                                          child: const Text('Guardar Cliente'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── CONCEPTOS SUMMARY CARD (READ-ONLY) ───
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Conceptos Cotizados (${state.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: state.items.length,
                            itemBuilder: (ctx, i) {
                              final item = state.items[i];
                              String title = item.catalogItem.nombre;
                              final notes = item.notas;
                              if (notes != null && notes.contains('||')) {
                                title = notes.split('||')[0].trim();
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '• $title (x${item.cantidad.toStringAsFixed(0)})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                    ),
                                    Text(
                                      _fmt.format(item.subtotal),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── OPTIONS & NOTES ───
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Parámetros de la Cotización', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _vigenciaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Días de Vigencia', prefixIcon: Icon(Icons.timer_outlined)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notasCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Condiciones Especiales / Comentarios generales', prefixIcon: Icon(Icons.notes)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── TOTALS BLOCK ───
                  Card(
                    color: AppColors.primaryVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)),
                              Text(_fmt.format(state.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IVA (16%):', style: TextStyle(color: AppColors.textSecondary)),
                              Text(_fmt.format(state.iva), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                              Text(_fmt.format(state.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.secondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── ACTION BUTTON ───
                  GradientButton(
                    label: 'Generar Propuesta Comercial',
                    icon: Icons.assignment_turned_in_rounded,
                    onPressed: (state.cliente != null && state.items.isNotEmpty) ? _submitQuotation : null,
                  ),
                ],
              ),
            ),
    );
  }
}

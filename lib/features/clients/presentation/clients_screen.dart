// lib/presentation/screens/clients/clients_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/features/clients/models/client.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final rows = await Supabase.instance.client
      .from('clientes')
      .select()
      .order('nombre');
  return rows.map<Client>((r) => Client.fromJson(r)).toList();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showNewClientDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final empresaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nuevo Cliente',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nombre *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: empresaCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Empresa'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setSt(() => saving = true);
                      try {
                        await Supabase.instance.client.from('clientes').insert({
                          'id': const Uuid().v4(),
                          'nombre': nameCtrl.text.trim(),
                          'empresa': empresaCtrl.text.trim().isEmpty ? null : empresaCtrl.text.trim(),
                          'telefono': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          'correo': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ref.invalidate(clientsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cliente guardado ✓')),
                          );
                        }
                      } catch (e) {
                        setSt(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    empresaCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('Clientes'),
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
        onPressed: _showNewClientDialog,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo'),
        backgroundColor: AppColors.secondary,
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
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: clientsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Error al cargar clientes', style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => ref.invalidate(clientsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (clients) {
                final filtered = _query.isEmpty
                    ? clients
                    : clients
                        .where((c) =>
                            c.nombre.toLowerCase().contains(_query) ||
                            c.empresa?.toLowerCase().contains(_query) == true ||
                            c.correo?.toLowerCase().contains(_query) == true)
                        .toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(clientsProvider.future),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        const Icon(Icons.person_search, color: AppColors.textDisabled, size: 56),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _query.isEmpty ? 'Sin clientes registrados' : 'Sin resultados',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(clientsProvider.future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final c = filtered[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            radius: 22,
                            child: Text(
                              c.initials,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            c.nombre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (c.empresa != null)
                                Text(
                                  c.empresa!,
                                  style: const TextStyle(color: AppColors.secondary, fontSize: 12),
                                ),
                              if (c.telefono != null)
                                Text(
                                  c.telefono!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 11),
                                ),
                              if (c.correo != null)
                                Text(
                                  c.correo!,
                                  style: const TextStyle(
                                      color: AppColors.textDisabled, fontSize: 11),
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.receipt_long_outlined,
                                color: AppColors.secondary),
                            tooltip: 'Nueva cotización',
                            onPressed: () {
                              ref.read(quoteBuilderProvider.notifier).setClient(c);
                              context.pushNamed('prices');
                            },
                          ),
                        ),
                      ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.04);
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

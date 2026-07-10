// lib/presentation/screens/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/core/constants/app_constants.dart';
import 'package:kst_business/features/auth/providers/auth_provider.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';
import 'package:kst_business/core/widgets/kst_sidebar.dart';
import 'package:kst_business/features/dashboard/widgets/welcome_card.dart';
import 'package:kst_business/features/admin/presentation/admin_dashboard.dart';
import 'package:kst_business/features/sales/presentation/sales_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final catalogAsync = ref.watch(catalogItemsProvider);

    final currencyFmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    // Safe profile checks
    final profile = profileAsync.valueOrNull;
    final bool isSeller = profile?.role == AppConstants.roleVendedor;
    final bool isAdmin = profile?.role == AppConstants.roleAdmin;

    return Scaffold(
      backgroundColor: AppColors.primary,
      drawer: const KstSidebar(),
      floatingActionButton: (isSeller || isAdmin)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16),
              child: FloatingActionButton.extended(
                onPressed: () => context.pushNamed('prices'),
                backgroundColor: AppColors.secondary,
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                label: const Text('Nueva Cotización', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar datos: $err'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(dashboardStatsProvider);
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (profileData) {
          final String displayName = profileData?.displayName ?? user?.email ?? 'Usuario';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary, size: 26),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: const Text(
                  'Inicio',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
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
                            icon: const Icon(Icons.shopping_cart_rounded, color: AppColors.textPrimary, size: 24),
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
                  const SizedBox(width: 8),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Premium Welcome Card (separated component)
                    WelcomeCard(
                      displayName: displayName,
                      isAdmin: isAdmin,
                      area: profileData?.area,
                    ),
                    const SizedBox(height: 24),
                    
                    if (isAdmin)
                      AdminDashboard(
                        statsAsync: statsAsync,
                        catalogAsync: catalogAsync,
                        currencyFmt: currencyFmt,
                      )
                    else
                      SalesDashboard(
                        statsAsync: statsAsync,
                        currencyFmt: currencyFmt,
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

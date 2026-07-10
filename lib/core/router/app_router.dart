// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kst_business/features/auth/presentation/login_screen.dart';
import 'package:kst_business/features/auth/presentation/splash_screen.dart';
import 'package:kst_business/features/dashboard/presentation/dashboard_screen.dart';
import 'package:kst_business/features/prices/presentation/list_prices_screen.dart';
import 'package:kst_business/features/cart/presentation/cart_screen.dart';
import 'package:kst_business/features/checkout/presentation/screens/payment_delivery_screen.dart';
import 'package:kst_business/features/quotes/presentation/screens/quote_history_screen.dart';
import 'package:kst_business/features/clients/presentation/clients_screen.dart';
import 'package:kst_business/features/auth/providers/auth_provider.dart';
import 'package:kst_business/features/prices/models/catalog_item.dart';
import 'package:kst_business/features/prices/presentation/screens/register_product_screen.dart';
import 'package:kst_business/features/prices/presentation/screens/deleted_products_screen.dart';
import 'package:kst_business/features/quotes/presentation/screens/trabajos_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // Fast check if user is logged in
      final session = authAsync.valueOrNull?.session ?? Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      
      final isLoginPage = state.matchedLocation == '/login';
      final isSplashPage = state.matchedLocation == '/splash';

      if (!isLoggedIn) {
        return (isLoginPage || isSplashPage) ? null : '/login';
      }

      if (isLoggedIn && isLoginPage) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/quotes',
        name: 'quotes',
        builder: (context, state) => const QuoteHistoryScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const PaymentDeliveryScreen(),
      ),
      GoRoute(
        path: '/prices',
        name: 'prices',
        builder: (context, state) => const ListPricesScreen(),
      ),
      GoRoute(
        path: '/clients',
        name: 'clients',
        builder: (context, state) => const ClientsScreen(),
      ),
      GoRoute(
        path: '/register-product',
        name: 'register-product',
        builder: (context, state) {
          final editItem = state.extra as CatalogItem?;
          return RegisterProductScreen(editItem: editItem);
        },
      ),
      GoRoute(
        path: '/deleted-products',
        name: 'deleted-products',
        builder: (context, state) => const DeletedProductsScreen(),
      ),
      GoRoute(
        path: '/jobs',
        name: 'jobs',
        builder: (context, state) => const TrabajosScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/sales-dashboard',
        name: 'sales-dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/manager-dashboard',
        name: 'manager-dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

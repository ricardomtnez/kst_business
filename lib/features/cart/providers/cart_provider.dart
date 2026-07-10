// lib/features/cart/providers/cart_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kst_business/features/quotes/models/quote_item.dart';
import 'package:kst_business/features/quotes/providers/quote_provider.dart';

final cartProvider = Provider<List<QuoteItem>>((ref) {
  return ref.watch(quoteBuilderProvider).items;
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(quoteBuilderProvider).subtotal;
});

final cartIvaProvider = Provider<double>((ref) {
  return ref.watch(quoteBuilderProvider).iva;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(quoteBuilderProvider).total;
});

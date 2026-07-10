// lib/presentation/widgets/dashboard/welcome_card.dart

import 'package:flutter/material.dart';
import 'package:kst_business/core/theme/app_theme.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({
    super.key,
    required this.displayName,
    required this.isAdmin,
    this.area,
  });

  final String displayName;
  final bool isAdmin;
  final String? area;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Panel de Control Administrativo' : 'Panel de Ventas y Cotización',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '¡Hola, $displayName!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (area != null && area!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Área: $area',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 36),
        ],
      ),
    );
  }
}

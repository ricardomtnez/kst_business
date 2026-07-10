// lib/presentation/widgets/common/kst_logo.dart

import 'package:flutter/material.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/core/constants/app_constants.dart';

class KstLogo extends StatelessWidget {
  const KstLogo({super.key, this.size = 60, this.showText = false});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.24),
            gradient: const LinearGradient(
              colors: [Color(0xFF0056A4), Color(0xFF003B75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF004B8D).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.22),
            child: Image.asset(
              'assets/images/icono.png',
              fit: BoxFit.contain,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    'KST',
                    style: TextStyle(
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            AppConstants.companyName,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

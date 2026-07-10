// lib/presentation/widgets/common/kst_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kst_business/core/theme/app_theme.dart';
import 'package:kst_business/core/constants/app_constants.dart';
import 'package:kst_business/features/auth/models/user_profile.dart';
import 'package:kst_business/features/auth/providers/auth_provider.dart';

class KstSidebar extends ConsumerWidget {
  const KstSidebar({super.key});

  // Helper to check which path is currently active in GoRouter
  bool _isRouteActive(BuildContext context, String routeName) {
    try {
      final GoRouterState state = GoRouterState.of(context);
      final currentLoc = state.matchedLocation;
      if (routeName == 'dashboard' && currentLoc == '/dashboard') return true;
      if (routeName == 'prices' && currentLoc == '/prices') return true;
      if (routeName == 'quotes' && currentLoc == '/quotes') return true;
      if (routeName == 'clients' && currentLoc == '/clients') return true;
      if (routeName == 'jobs' && currentLoc == '/jobs') return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  // Returns user initials for the avatar
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User profile card header
          profileAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 28, backgroundColor: Colors.white12),
                  SizedBox(height: 16),
                  ContainerPlaceholder(width: 140, height: 16),
                  SizedBox(height: 8),
                  ContainerPlaceholder(width: 80, height: 12),
                ],
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 28, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'Usuario KST',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Text(
                    'Error al cargar perfil',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            data: (profile) {
              if (profile == null) return const SizedBox();
              
              final String nameDisplay = profile.displayName;
              final initials = _getInitials(nameDisplay);
              final String areaStr = profile.area?.trim().isNotEmpty == true 
                  ? profile.area! 
                  : 'Sin Área Configurada';
              final String phoneStr = profile.phone?.trim().isNotEmpty == true 
                  ? profile.phone! 
                  : 'Sin Teléfono Configurado';
              
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          child: CircleAvatar(
                            radius: 27,
                            backgroundColor: Colors.white,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                        
                        // Role Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: profile.role == AppConstants.roleAdmin 
                                ? AppColors.accent.withValues(alpha: 0.25)
                                : Colors.white12,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: profile.role == AppConstants.roleAdmin 
                                  ? AppColors.accent.withValues(alpha: 0.5)
                                  : Colors.white30,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            profile.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: profile.role == AppConstants.roleAdmin 
                                  ? AppColors.accent 
                                  : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      nameDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Area Row
                    Row(
                      children: [
                        const Icon(Icons.business_center_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            areaStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    
                    // Phone Row
                    Row(
                      children: [
                        const Icon(Icons.phone_iphone_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            phoneStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    
                    // Email Row
                    Row(
                      children: [
                        const Icon(Icons.email_rounded, size: 13, color: Colors.white60),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                     const SizedBox(height: 12),
                     // Edit profile button
                     GestureDetector(
                       onTap: () => _showEditProfileDialog(context, ref, profile),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.12),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: const Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                             SizedBox(width: 6),
                             Text(
                               'Editar Información de Cuenta',
                               style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                       ),
                     ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Navigation links list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Inicio',
                  isActive: _isRouteActive(context, 'dashboard'),
                  onTap: () {
                    Navigator.pop(context);
                    context.goNamed('dashboard');
                  },
                ),
                _SidebarItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Catálogo',
                  isActive: _isRouteActive(context, 'prices'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed('prices');
                  },
                ),
                _SidebarItem(
                  icon: Icons.description_outlined,
                  activeIcon: Icons.description_rounded,
                  label: 'Cotizaciones',
                  isActive: _isRouteActive(context, 'quotes'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed('quotes');
                  },
                ),
                _SidebarItem(
                  icon: Icons.construction_outlined,
                  activeIcon: Icons.construction_rounded,
                  label: 'Trabajos',
                  isActive: _isRouteActive(context, 'jobs'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed('jobs');
                  },
                ),
                _SidebarItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Clientes',
                  isActive: _isRouteActive(context, 'clients'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed('clients');
                  },
                ),
                
                // Administrator Quick Actions Section
                if (ref.watch(isAdminProvider).valueOrNull ?? false) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Divider(height: 1),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'ADMINISTRACIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDisabled,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _SidebarItem(
                    icon: Icons.add_to_photos_outlined,
                    activeIcon: Icons.add_to_photos_rounded,
                    label: 'Registrar Producto',
                    isActive: false,
                    accentColor: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context); // Close sidebar
                      context.pushNamed('register-product');
                    },
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Logout tile and version info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'KST Business v1.0.0',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile profile) {
    final String currentName = (profile.fullName != null && profile.fullName != profile.email) 
        ? profile.fullName! 
        : ((profile.firstName != null || profile.lastName != null)
            ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim() 
            : '');
    final nameCtrl = TextEditingController(text: currentName);
    final areaCtrl = TextEditingController(text: profile.area);
    final phoneCtrl = TextEditingController(text: profile.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Editar Información de Cuenta',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Nombre Completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: areaCtrl,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Área / Departamento'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newArea = areaCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();

              String? firstName;
              String? lastName;
              if (newName.contains(' ')) {
                final parts = newName.split(' ');
                firstName = parts.first;
                lastName = parts.sublist(1).join(' ');
              } else {
                firstName = newName;
              }

              bool success = false;
              dynamic lastError;

              try {
                await Supabase.instance.client.from('user_profiles').update({
                  'first_name': firstName,
                  'last_name': lastName,
                  'area': newArea,
                  'phone': newPhone,
                }).eq('id', profile.id);
                success = true;
              } catch (e) {
                lastError = e;
              }

              try {
                await Supabase.instance.client.from('profiles').update({
                  'first_name': firstName,
                  'last_name': lastName,
                  'area': newArea,
                  'phone': newPhone,
                }).eq('id', profile.id);
                success = true;
              } catch (e) {
                lastError ??= e;
              }

              if (success) {
                ref.invalidate(userProfileProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado con éxito en la base de datos')),
                  );
                }
              } else {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar perfil: $lastError')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = accentColor ?? AppColors.secondary;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        dense: true,
        selected: isActive,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedTileColor: primaryColor.withValues(alpha: 0.08),
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? primaryColor : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? primaryColor : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

// Simple shimmer placeholder for profile loading state
class ContainerPlaceholder extends StatelessWidget {
  const ContainerPlaceholder({super.key, required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

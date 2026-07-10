import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kst_business/core/constants/app_constants.dart';
import 'package:kst_business/features/auth/models/user_profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  // Watch authStateProvider to reactive trigger updates
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? ref.watch(supabaseClientProvider).auth.currentUser;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final supabase = ref.watch(supabaseClientProvider);
  
  final metaName = user.userMetadata?['full_name'] as String? ?? 
                   user.userMetadata?['name'] as String? ?? 
                   user.userMetadata?['fullName'] as String?;
  final metaRole = user.userMetadata?['role'] as String? ?? AppConstants.roleVendedor;
  final metaArea = user.userMetadata?['area'] as String? ?? 
                   user.userMetadata?['department'] as String?;
  final metaPhone = user.userMetadata?['phone'] as String? ?? 
                    user.userMetadata?['phone_number'] as String?;

  Map<String, dynamic>? profileData;
  dynamic error1;

  Future<void> performFetch() async {
    try {
      profileData = await supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
          
      // Fallback: if query by ID returned null, query by email
      if (profileData == null && user.email != null) {
        profileData = await supabase
            .from('user_profiles')
            .select()
            .eq('email', user.email!)
            .maybeSingle();
      }
    } catch (e, st) {
      error1 = e;
      debugPrint("DEBUG ERROR user_profiles: $e\n$st");
    }
  }

  // Initial fetch
  await performFetch();

  // If null, wait for 600ms to allow Supabase authorization headers to settle, and retry
  if (profileData == null) {
    await Future.delayed(const Duration(milliseconds: 600));
    await performFetch();
  }

  final mergedData = <String, dynamic>{};
  if (profileData != null) {
    profileData!.forEach((key, value) {
      if (value != null) {
        mergedData[key] = value;
      }
    });
  }

  // File debug logging
  if (!kIsWeb) {
    try {
      final logFile = File('db_debug_log.txt');
      final logMessage = "=== DB PROFILE FETCH ${DateTime.now().toIso8601String()} ===\n"
          "User ID: ${user.id}\n"
          "User Email: ${user.email}\n"
          "user_profiles row: $profileData (Err: $error1)\n"
          "Merged Data: $mergedData\n"
          "====================================\n\n";
      logFile.writeAsStringSync(logMessage, mode: FileMode.append);
    } catch (_) {}
  }

  if (mergedData.isEmpty) {
    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      role: metaRole,
      phone: metaPhone,
      fullName: metaName,
      area: metaArea,
    );
  }

  final dbProfile = UserProfile.fromJson(mergedData);
  
  // Self-healing database sync: If DB row has NULL or email as name, and metadata has a proper name/area, write it back to DB
  bool needsUpdate = false;
  String? newFullName = dbProfile.fullName;
  String? newArea = dbProfile.area;
  String? newPhone = dbProfile.phone;

  if ((dbProfile.fullName == null || dbProfile.fullName == dbProfile.email) && metaName != null) {
    newFullName = metaName;
    needsUpdate = true;
  }
  if (dbProfile.area == null && metaArea != null) {
    newArea = metaArea;
    needsUpdate = true;
  }
  if (dbProfile.phone == null && metaPhone != null) {
    newPhone = metaPhone;
    needsUpdate = true;
  }

  if (needsUpdate) {
    String? firstName = dbProfile.firstName;
    String? lastName = dbProfile.lastName;
    if (newFullName != null && newFullName.contains(' ')) {
      final parts = newFullName.split(' ');
      firstName = parts.first;
      lastName = parts.sublist(1).join(' ');
    } else {
      firstName = newFullName;
    }

    // Run async database write
    supabase.from('user_profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      'area': newArea,
      'phone': newPhone,
    }).eq('id', user.id).then((_) {
      ref.invalidateSelf();
    }).catchError((_) {});
  }

  return UserProfile(
    id: dbProfile.id,
    email: dbProfile.email,
    firstName: dbProfile.firstName,
    lastName: dbProfile.lastName,
    fullName: dbProfile.fullName ?? metaName,
    role: dbProfile.role,
    area: dbProfile.area ?? metaArea,
    isActive: dbProfile.isActive,
    createdAt: dbProfile.createdAt,
    updatedAt: dbProfile.updatedAt,
    phone: dbProfile.phone ?? metaPhone,
  );
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  return profile?.role ?? AppConstants.roleVendedor;
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final role = await ref.watch(userRoleProvider.future);
  return role == AppConstants.roleAdmin;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final SupabaseClient _supabase;
  final Ref _ref;

  void _init() {
    final user = _supabase.auth.currentUser;
    state = AsyncValue.data(user);
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _ref.invalidate(userProfileProvider);
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final profile = _ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;

    final nextRole = profile.role == AppConstants.roleAdmin ? AppConstants.roleVendedor : AppConstants.roleAdmin;

    try {
      // Try updating user_profiles table role
      await _supabase.from('user_profiles').update({
        'role': nextRole
      }).eq('id', user.id);
    } catch (_) {
      // Try profiles table role
      try {
        await _supabase.from('profiles').update({
          'role': nextRole
        }).eq('id', user.id);
      } catch (_) {
        // Fallback to updating metadata
        await _supabase.auth.updateUser(UserAttributes(
          data: {'role': nextRole}
        ));
      }
    }

    _ref.invalidate(userProfileProvider);
    _ref.invalidate(userRoleProvider);
    _ref.invalidate(isAdminProvider);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _ref.invalidate(userProfileProvider);
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider), ref);
});

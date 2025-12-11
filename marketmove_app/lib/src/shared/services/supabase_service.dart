import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth Methods
  static User? get currentUser => client.auth.currentUser;
  
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String role = 'user',
    String? planType,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
        'plan_type': planType,
      },
    );
    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Profile Methods
  static Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return UserModel.fromJson({
      ...response,
      'email': user.email,
    });
  }

  static Future<List<UserModel>> getAllUsers() async {
    final response = await client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  static Future<void> updateUserRole(String userId, String role) async {
    await client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId);
  }

  static Future<void> updateUserPlan(String userId, String planType, DateTime? expiresAt) async {
    await client
        .from('profiles')
        .update({
          'plan_type': planType,
          'plan_expires_at': expiresAt?.toIso8601String(),
        })
        .eq('id', userId);
  }
}

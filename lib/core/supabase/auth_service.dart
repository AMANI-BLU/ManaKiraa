import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Session? get currentSession => _client.auth.currentSession;
  static User? get currentUser => _client.auth.currentUser;
  static bool isDeletingAccount = false;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'com.manakira.app://reset-callback/',
    );
  }

  static Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  static Future<AuthResponse> verifyResetOTP({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  static Future<AuthResponse> signInWithGoogle() async {
    // For Supabase Google Auth on Android, you MUST use the Web Client ID as serverClientId
    // to receive an idToken back.
    const webClientId =
        '812539086704-hnf9lm9l0go8st71lhb01on8iep1sh23.apps.googleusercontent.com';
    const iosClientId =
        '812539086704-1135r8a5qd2gcb0ig79fuoqgdctambn4.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    // Force the account picker to show by signing out first
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (accessToken == null || idToken == null) {
      throw 'Google Sign In failed. No tokens found.';
    }

    return await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  static Future<void> signInWithFacebook() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: kIsWeb ? null : 'com.manakira.app://login-callback/',
    );
  }

  static Future<String?> uploadProfilePicture(File file) async {
    final user = currentUser;
    if (user == null) return null;

    final fileExtension = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${user.id}/avatar_$timestamp.$fileExtension';
    final filePath = fileName;

    await _client.storage
        .from('avatars')
        .upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '0', upsert: false),
        );

    final url = _client.storage.from('avatars').getPublicUrl(filePath);
    return url;
  }

  static Future<UserResponse> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    final data = {'full_name': fullName};
    if (avatarUrl != null) {
      data['avatar_url'] = avatarUrl;
    }
    return await _client.auth.updateUser(UserAttributes(data: data));
  }

  static Future<void> signOut() async {
    // Clear FCM token so this device stops receiving notifications for this user
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _client
            .from('profiles')
            .update({'fcm_token': null})
            .eq('id', userId);
      } catch (_) {}
    }
    await _client.auth.signOut();
  }

  static Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    try {
      isDeletingAccount = true;
      // Call the database function to delete both profile and auth user
      await _client.rpc('delete_user_account');

      // Sign out (clears local session)
      await signOut();
    } finally {
      isDeletingAccount = false;
    }
  }

  static Future<bool?> checkIsActive(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('is_active')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null; // Profile missing = Not found
      return response['is_active'] ?? true;
    } catch (_) {
      return true; // Keep them in if there is a network error fetching
    }
  }

  static Stream<bool?> getAccountStatusStream(String userId, String? email) {
    // Master Admin is always exempt
    if (email == 'admin@manakiraa.com') {
      return Stream.value(true);
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) {
          debugPrint('📡 Realtime Profile Update: $data');
          if (data.isEmpty) {
            debugPrint('⚠️ Profile missing!');
            return null; // Null means account record is incomplete/deleted
          }
          final isActive = data.first['is_active'] ?? true;
          debugPrint('✅ Account is_active: $isActive');
          return isActive;
        });
  }

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}

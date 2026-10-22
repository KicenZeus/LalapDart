import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient = ApiClient();

  AuthNotifier() : super(AuthState()) {
    initAuth();
  }

  /// Inisialisasi sesi dari penyimpanan aman (Keychain / Keystore)
  Future<void> initAuth() async {
    try {
      final token = await _apiClient.getToken();
      final userDataStr = await _apiClient.getUserData();

      if (token != null && userDataStr != null) {
        final userMap = jsonDecode(userDataStr) as Map<String, dynamic>;
        state = state.copyWith(
          token: token,
          user: UserModel.fromJson(userMap),
          isInitialized: true,
        );
        return;
      }
    } catch (_) {
      await _apiClient.clearAuthData();
    }
    state = state.copyWith(isInitialized: true, clearUser: true);
  }

  /// Proses Login Pengguna
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      final data = response.data['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);

      await _apiClient.saveToken(token);
      await _apiClient.saveUserData(jsonEncode(user.toJson()));

      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Gagal masuk. Periksa username dan sandi.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan sistem: $e',
      );
      return false;
    }
  }

  /// Logout Sesi
  Future<void> logout() async {
    await _apiClient.clearAuthData();
    state = state.copyWith(clearUser: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

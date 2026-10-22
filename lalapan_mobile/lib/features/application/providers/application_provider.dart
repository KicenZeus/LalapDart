import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/application_model.dart';

class ApplicationListState {
  final List<ApplicationModel> items;
  final bool isLoading;
  final String? errorMessage;
  final int total;

  ApplicationListState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.total = 0,
  });

  ApplicationListState copyWith({
    List<ApplicationModel>? items,
    bool? isLoading,
    String? errorMessage,
    int? total,
  }) {
    return ApplicationListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      total: total ?? this.total,
    );
  }
}

class ApplicationListNotifier extends StateNotifier<ApplicationListState> {
  final ApiClient _apiClient = ApiClient();

  ApplicationListNotifier() : super(ApplicationListState());

  Future<void> loadApplications({String? status, String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.dio.get('/applications', queryParameters: queryParams);
      final data = response.data['data'];
      final List rawItems = data['items'] ?? [];

      final items = rawItems.map((e) => ApplicationModel.fromJson(e)).toList();
      state = state.copyWith(
        items: items,
        total: data['pagination']?['total'] ?? items.length,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.response?.data?['message'] ?? 'Gagal memuat pengajuan.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Kesalahan: $e',
      );
    }
  }

  Future<ApplicationModel?> createDraft({
    required BabyModel baby,
    required MotherModel mother,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/applications',
        data: {
          'baby': baby.toJson(),
          'mother': mother.toJson(),
        },
      );

      final newApp = ApplicationModel.fromJson(response.data['data']);
      await loadApplications();
      return newApp;
    } catch (e) {
      rethrow;
    }
  }
}

final applicationListProvider =
    StateNotifierProvider<ApplicationListNotifier, ApplicationListState>((ref) {
  return ApplicationListNotifier();
});

/// Detail Application Provider
final applicationDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/applications/$id');
  return response.data['data'] as Map<String, dynamic>;
});

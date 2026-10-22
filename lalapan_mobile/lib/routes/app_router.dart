import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_provider.dart';
import '../features/auth/views/login_screen.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/public_tracking/views/public_tracking_screen.dart';
import '../features/application/views/application_list_screen.dart';
import '../features/application/views/application_form_screen.dart';
import '../features/verification/views/verification_queue_screen.dart';
import '../features/document_viewer/views/document_viewer_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isPublic = state.matchedLocation == '/';

      if (!authState.isInitialized) {
        return null; // Tunggu restore session selesai
      }

      // Halaman publik bisa diakses siapapun tanpa login
      if (isPublic) return null;

      // Jika belum login dan mencoba akses route yang diproteksi
      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      // Jika sudah login dan mencoba ke halaman login lagi
      if (isAuth && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // 1. Halaman Lacak Publik (Tanpa Login)
      GoRoute(
        path: '/',
        builder: (context, state) => const PublicTrackingScreen(),
      ),

      // 2. Login Petugas
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 3. Dashboard Utama Petugas
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // 4. Modul Pengajuan Faskes
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationListScreen(),
      ),
      GoRoute(
        path: '/applications/new',
        builder: (context, state) => const ApplicationFormScreen(),
      ),

      // 5. Modul Verifikasi Dukcapil
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationQueueScreen(),
      ),

      // 6. Interactive Document Viewer
      GoRoute(
        path: '/viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DocumentViewerScreen(
            title: extra['title'] ?? 'Pratinjau Dokumen',
            fileUrl: extra['fileUrl'] ?? '',
            token: extra['token'],
          );
        },
      ),
    ],
  );
});

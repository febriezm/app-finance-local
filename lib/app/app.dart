import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import 'router.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../features/security/presentation/widgets/app_lock_listener.dart';

class MyFinanceApp extends ConsumerWidget {
  const MyFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        final protectedChild = AppLockListener(
          child: child ?? const SizedBox.shrink(),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            // Jika dibuka di browser / layar lebar PC (> 500px),
            // tampilkan simulasi frame fisik iPhone 16 Pro lengkap dengan Dynamic Island!
            if (kIsWeb && constraints.maxWidth > 500) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Scaffold(
                backgroundColor: isDark ? const Color(0xFF0A0C0E) : const Color(0xFFE5E7EB),
                body: Center(
                  child: Container(
                    width: 393,
                    height: 852,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(52),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF2D3436),
                        width: 9,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Isi aplikasi MyFinance di dalam layar iPhone
                        Positioned.fill(
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              padding: const EdgeInsets.only(top: 48, bottom: 24),
                              viewPadding: const EdgeInsets.only(top: 48, bottom: 24),
                            ),
                            child: protectedChild,
                          ),
                        ),

                        // Simulasi Dynamic Island Apple iPhone
                        Positioned(
                          top: 11,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 116,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Jika diakses dari layar mobile (< 500px), tampilkan ukuran penuh
            return protectedChild;
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/config/tenant_build_config.dart';
import '../../../core/storage/storage_service.dart';
import '../../../routes/app_routes.dart';
import '../../tenant/models/tenant_config.dart';

/// Animated splash view featuring the Stitch WoodApp logo with a smooth
/// scale & fade entrance animation, redirecting based on stored local state.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();

    // Give time for entrance animation before checking redirect
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _redirect();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  TenantConfig? get _tenantConfig {
    final json = StorageService.instance.tenantConfig;
    return json != null ? TenantConfig.fromJson(json) : null;
  }

  void _redirect() async {
    final storage = StorageService.instance;

    // Auto-seed tenant config if not already stored
    if (storage.tenantSlug == null || storage.tenantConfig == null) {
      final activeConfig = await TenantConfig.loadActiveConfig();
      await storage.saveTenantSlug(activeConfig.tenantId ?? TenantBuildConfig.tenantId);
      await storage.saveTenantConfig(activeConfig.toJson());
    }

    if (!storage.isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tenant = _tenantConfig;
    final displayName = tenant?.companyName ??
        tenant?.appName ??
        tenant?.name ??
        TenantBuildConfig.companyName;
    final logoAsset = (tenant?.logo != null && tenant!.logo!.isNotEmpty)
        ? tenant.logo!
        : TenantBuildConfig.logoPath;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnim.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Branded SVG Logo container
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: SvgPicture.asset(
                          logoAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Solution ERP Bois & Négoce',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/config/tenant_build_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../../tenant/models/tenant_config.dart';
import '../controllers/auth_controller.dart';

/// Modern Login screen displaying dynamic tenant branding with Elance fallback.
/// Reference implementation: fo-acya-app/elance-app.ui/src/app/login/page.tsx
class LoginView extends GetView<AuthController> {
  LoginView({super.key});

  final RxBool _obscurePassword = true.obs;

  /// Exact existing Elance logo asset path in WOODAPP, mirroring Elance web app.
  static const String elanceLogoAsset = 'assets/images/logo.svg';

  TenantConfig get _fallbackTenantConfig {
    if (Get.testMode) return TenantConfig.fromBuildConfig();
    final json = StorageService.instance.tenantConfig;
    if (json != null) return TenantConfig.fromJson(json);
    return TenantConfig.fromBuildConfig();
  }

  @override
  Widget build(BuildContext context) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Obx(() {
              // Reactive tenant config loaded & refreshed by AuthController
              final tenant = controller.tenantConfig.value ?? _fallbackTenantConfig;
              final isTenantInactive = tenant.status == 'Suspended' || tenant.status == 'Expired';

              final displayName = tenant.companyName ??
                  tenant.name ??
                  tenant.appName ??
                  (TenantBuildConfig.isEmbedded ? TenantBuildConfig.companyName : 'Élancé');

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Branded Logo Header ─────────────────────────────────────
                  Container(
                    height: 84,
                    constraints: const BoxConstraints(minWidth: 84, maxWidth: 140),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: buildLogo(tenant, colorScheme),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── Inactive Tenant Warning (mirrors Elance login/page.tsx) ──
                  if (isTenantInactive) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        "Votre entreprise est désactivée. Contactez l'administrateur.",
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                // Credentials Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identifiant',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: loginController,
                          autocorrect: false,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Identifiant ou email',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Mot de passe',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Obx(() => TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword.value,
                              decoration: InputDecoration(
                                hintText: 'Mot de passe',
                                prefixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: colorScheme.primary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword.value
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () =>
                                      _obscurePassword.value = !_obscurePassword.value,
                                ),
                              ),
                              onSubmitted: (_) => _submit(
                                loginController.text,
                                passwordController.text,
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Error Banner
                Obx(() {
                  final error = controller.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(
                              color: colorScheme.onErrorContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // Login Submit Button
                Obx(() {
                  final isLoading = controller.status.value == ViewStatus.loading;
                  final isDisabled = isLoading || isTenantInactive;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isDisabled
                          ? null
                          : () => _submit(
                                loginController.text,
                                passwordController.text,
                              ),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    ),
  );
}

  /// Builds the tenant logo according to the exact fallback priority:
  /// Current tenant -> Tenant logo available? -> YES: Display tenant logo
  ///                                           -> NO / ERROR: Display exact Elance logo
  @visibleForTesting
  Widget buildLogo(TenantConfig tenant, ColorScheme colorScheme) {
    // 1. Dynamic remote logo URL (e.g. from /api/enterprise/config)
    final rawLogoUrl = tenant.logoUrl?.trim();
    if (rawLogoUrl != null && rawLogoUrl.isNotEmpty) {
      final resolvedUrl = _resolveUrl(rawLogoUrl, tenant.baseUrl);
      final isSvg = resolvedUrl.toLowerCase().split('?').first.endsWith('.svg');

      if (isSvg) {
        return SvgPicture.network(
          resolvedUrl,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => _buildPlaceholder(colorScheme),
          errorBuilder: (_, _, _) => _buildElanceLogo(),
        );
      } else {
        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          fit: BoxFit.contain,
          placeholder: (_, _) => _buildPlaceholder(colorScheme),
          errorWidget: (_, _, _) => _buildElanceLogo(),
        );
      }
    }

    // 2. Pre-configured local tenant asset (e.g. assets/tenants/mansour-construction/logo.svg)
    final customAsset = tenant.logo?.trim();
    if (customAsset != null &&
        customAsset.isNotEmpty &&
        customAsset != elanceLogoAsset) {
      return SvgPicture.asset(
        customAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildElanceLogo(),
      );
    }

    // 3. Fallback: Exact existing Elance logo asset
    return _buildElanceLogo();
  }

  /// Renders the exact existing Elance logo asset (assets/images/logo.svg).
  /// Preserves exact 1:1 isometric aspect ratio and gradient styling without distortion.
  Widget _buildElanceLogo() {
    return SvgPicture.asset(
      elanceLogoAsset,
      fit: BoxFit.contain,
    );
  }

  /// Lightweight loading spinner indicator while a remote logo is fetching.
  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  /// Resolves relative logo URLs against the tenant API base URL.
  String _resolveUrl(String url, String? tenantBaseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = (tenantBaseUrl != null && tenantBaseUrl.trim().isNotEmpty)
        ? tenantBaseUrl
        : ApiClient.instance.dio.options.baseUrl;
    return Uri.parse(base).resolve(url).toString();
  }

  Future<void> _submit(String login, String password) async {
    final success = await controller.login(login, password);
    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}

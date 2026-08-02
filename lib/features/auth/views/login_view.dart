import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/config/tenant_build_config.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../../tenant/models/tenant_config.dart';
import '../controllers/auth_controller.dart';

/// Modern Login screen built with Stitch UI standards.
/// Displays active tenant branding or pre-configured company parameters.
class LoginView extends GetView<AuthController> {
  LoginView({super.key});

  final RxBool _obscurePassword = true.obs;

  TenantConfig? get _tenantConfig {
    final json = StorageService.instance.tenantConfig;
    return json != null ? TenantConfig.fromJson(json) : null;
  }

  @override
  Widget build(BuildContext context) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final tenant = _tenantConfig;
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = tenant?.companyName ??
        tenant?.appName ??
        tenant?.name ??
        TenantBuildConfig.appName;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Branded Logo Header
                Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(14),
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
                  child: (tenant?.logoUrl != null && tenant!.logoUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: tenant.logoUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) => SvgPicture.asset(
                              TenantBuildConfig.logoPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : SvgPicture.asset(
                          TenantBuildConfig.logoPath,
                          fit: BoxFit.contain,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

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
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(String login, String password) async {
    final success = await controller.login(login, password);
    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../../tenant/models/tenant_config.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  TenantConfig? get _tenantConfig {
    final json = StorageService.instance.tenantConfig;
    return json != null ? TenantConfig.fromJson(json) : null;
  }

  @override
  Widget build(BuildContext context) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final tenant = _tenantConfig;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tenant?.logoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: tenant!.logoUrl!,
                      height: 72,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  )
                else
                  Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                Text(
                  tenant?.name ?? 'Connexion',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: loginController,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Identifiant ou email',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _submit(loginController.text, passwordController.text),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final error = controller.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      error,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
                Obx(() {
                  final isLoading = controller.status.value == ViewStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _submit(loginController.text, passwordController.text),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Se connecter'),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.tenantSelection),
                  child: const Text("Ce n'est pas mon entreprise"),
                ),
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

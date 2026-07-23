import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../controllers/tenant_controller.dart';

class TenantSelectionView extends GetView<TenantController> {
  const TenantSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: controller.slug.value);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apartment_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  "Saisissez le nom de votre entreprise pour continuer",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: textController,
                  textInputAction: TextInputAction.go,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'entreprise',
                    hintText: 'ex: socobois',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  onSubmitted: (_) => _submit(textController.text),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final error = controller.errorMessage.value;
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
                Obx(() {
                  final isLoading = controller.status.value == ViewStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(textController.text),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continuer'),
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

  Future<void> _submit(String value) async {
    final success = await controller.selectTenant(value);
    if (success) {
      Get.offNamed(AppRoutes.login);
    }
  }
}

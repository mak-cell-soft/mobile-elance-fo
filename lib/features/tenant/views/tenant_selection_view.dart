import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../core/utils/view_status.dart';
import '../../../routes/app_routes.dart';
import '../controllers/tenant_controller.dart';

/// Tenant Selection screen built with Stitch UI standards.
/// Allows users to select their enterprise organization before login.
class TenantSelectionView extends GetView<TenantController> {
  const TenantSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController(text: controller.slug.value);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Branded Header with SVG Logo
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Bienvenue sur WoodApp',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Saisissez le nom de votre entreprise pour accéder à votre espace',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Main Form Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entreprise',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: textController,
                          textInputAction: TextInputAction.go,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: 'ex: socobois',
                            prefixIcon: Icon(
                              Icons.business_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          onSubmitted: (_) => _submit(textController.text),
                        ),
                        const SizedBox(height: 16),
                        
                        // Suggestion chip
                        Text(
                          'Exemples rapides :',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('socobois'),
                              avatar: const Icon(Icons.apartment, size: 16),
                              onPressed: () {
                                textController.text = 'socobois';
                                _submit('socobois');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Error feedback
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

                // Submit Action Button
                Obx(() {
                  final isLoading = controller.status.value == ViewStatus.loading;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submit(textController.text),
                      child: isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Continuer'),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
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

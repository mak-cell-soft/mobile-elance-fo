import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../routes/app_routes.dart';

/// Decides where to land the user based on what's already stored locally:
/// no tenant yet -> tenant selection, tenant but no session -> login,
/// both present -> home.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    final storage = StorageService.instance;

    if (storage.tenantSlug == null) {
      Get.offAllNamed(AppRoutes.tenantSelection);
      return;
    }

    if (!storage.isLoggedIn) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    Get.offAllNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

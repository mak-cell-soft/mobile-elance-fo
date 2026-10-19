import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/config/env.dart';
import 'core/network/api_client.dart';
import 'core/storage/storage_service.dart';
import 'features/notifications/services/fcm_service.dart';
import 'main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(Flavor.development);
  try {
    await Firebase.initializeApp();
    debugPrint('[Firebase] Initialized successfully for development flavor.');
  } catch (e, st) {
    debugPrint('[Firebase] Development Firebase Core initialization failed: $e\n$st');
    rethrow;
  }
  await bootstrap(Flavor.development);

  // Development-only local API and tenant override for isolated testing
  ApiClient.instance.setBaseUrl('http://localhost:5068/api/');
  await StorageService.instance.saveTenantSlug('development');
  debugPrint('[Development] Local API baseUrl configured: ${ApiClient.instance.dio.options.baseUrl}');
  debugPrint('[Development] Active tenant slug configured: ${StorageService.instance.tenantSlug}');

  // Initialize development-only FCM device token integration
  try {
    await FcmService.instance.init();
  } catch (e) {
    debugPrint('[FCM] Gracefully handled non-fatal startup error: $e');
  }
}

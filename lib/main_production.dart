import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/config/env.dart';
import 'features/notifications/services/fcm_service.dart';
import 'main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EnvConfig.init(Flavor.production);

  // 1. Safe, non-fatal Firebase Core initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      debugPrint('[Firebase] Initialized successfully for production flavor.');
    }
  } catch (e) {
    // Non-fatal: ERP app must continue even if Firebase Core fails
    debugPrint('[Firebase] Production Firebase initialization non-fatal error: $e');
  }

  // 2. Shared application bootstrap
  await bootstrap(Flavor.production);

  // 3. Safe, non-fatal FCM initialization
  try {
    await FcmService.instance.init();
  } catch (e) {
    debugPrint('[FCM] Gracefully handled non-fatal startup error: $e');
  }
}

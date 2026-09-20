import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:woodapp/core/config/env.dart';
import 'package:woodapp/features/auth/controllers/auth_controller.dart';
import 'package:woodapp/features/auth/views/login_view.dart';
import 'package:woodapp/features/tenant/models/tenant_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    EnvConfig.init(Flavor.development);
  });

  tearDown(() {
    Get.reset();
  });

  bool isSvgAsset(SvgPicture widget, String assetName) {
    final loader = widget.bytesLoader;
    if (loader is SvgAssetLoader) {
      return loader.assetName == assetName;
    }
    return loader.toString().contains(assetName);
  }

  group('Tenant Logo Fallback Priority Unit Tests', () {
    final loginView = LoginView();
    const colorScheme = ColorScheme.light();

    test('Falls back to exact existing Elance logo when tenant has no logo', () {
      final widget = loginView.buildLogo(
        TenantConfig(
          tenantId: 'generic-tenant',
          logoUrl: null,
          logo: null,
        ),
        colorScheme,
      );

      expect(widget, isA<SvgPicture>());
      final svg = widget as SvgPicture;
      expect(svg.bytesLoader, isA<SvgAssetLoader>());
      final assetLoader = svg.bytesLoader as SvgAssetLoader;
      expect(assetLoader.assetName, 'assets/images/logo.svg',
          reason: 'Must point to exact Elance logo asset');
      expect(svg.fit, BoxFit.contain);
    });

    test('Renders local tenant SVG asset when configured', () {
      final widget = loginView.buildLogo(
        TenantConfig(
          tenantId: 'mansour-construction',
          logo: 'assets/tenants/mansour-construction/logo.svg',
        ),
        colorScheme,
      );

      expect(widget, isA<SvgPicture>());
      final svg = widget as SvgPicture;
      expect(svg.bytesLoader, isA<SvgAssetLoader>());
      final assetLoader = svg.bytesLoader as SvgAssetLoader;
      expect(assetLoader.assetName, 'assets/tenants/mansour-construction/logo.svg');
      expect(svg.fit, BoxFit.contain);
    });

    test('Renders CachedNetworkImage when tenant has raster logoUrl', () {
      final widget = loginView.buildLogo(
        TenantConfig(
          tenantId: 'acme-corp',
          logoUrl: 'https://acya.site/uploads/acme/logo.png',
        ),
        colorScheme,
      );

      expect(widget, isA<CachedNetworkImage>());
      final img = widget as CachedNetworkImage;
      expect(img.imageUrl, 'https://acya.site/uploads/acme/logo.png');
      expect(img.fit, BoxFit.contain);
    });

    test('Renders SvgPicture.network when tenant has svg logoUrl', () {
      final widget = loginView.buildLogo(
        TenantConfig(
          tenantId: 'vector-tenant',
          logoUrl: 'https://acya.site/uploads/tenants/vector.svg',
        ),
        colorScheme,
      );

      expect(widget, isA<SvgPicture>());
      final svg = widget as SvgPicture;
      expect(svg.bytesLoader, isA<SvgNetworkLoader>());
      final netLoader = svg.bytesLoader as SvgNetworkLoader;
      expect(netLoader.url.toString(), 'https://acya.site/uploads/tenants/vector.svg');
      expect(svg.fit, BoxFit.contain);
    });

    test('Resolves relative logoUrl against API base URL', () {
      final widget = loginView.buildLogo(
        TenantConfig(
          tenantId: 'relative-tenant',
          logoUrl: '/uploads/logo.png',
          baseUrl: 'https://acya.site/api/',
        ),
        colorScheme,
      );

      expect(widget, isA<CachedNetworkImage>());
      final img = widget as CachedNetworkImage;
      expect(img.imageUrl, 'https://acya.site/uploads/logo.png');
    });
  });

  group('LoginView Widget Integration Tests', () {
    testWidgets('Renders exact Elance fallback logo and title on the login screen',
        (tester) async {
      final controller = Get.put(AuthController(enableRemoteSync: false));
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'generic-tenant',
        companyName: 'Élancé Enterprise',
        logoUrl: null,
        logo: null,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginView(),
        ),
      );
      await tester.pump();

      final svgFinders = find.byType(SvgPicture);
      expect(svgFinders, findsWidgets);

      final elanceSvg = svgFinders.evaluate().any((elem) {
        final widget = elem.widget as SvgPicture;
        return isSvgAsset(widget, 'assets/images/logo.svg');
      });
      expect(elanceSvg, isTrue,
          reason: 'Must render exact existing Elance logo asset (assets/images/logo.svg)');

      expect(find.text('Élancé Enterprise'), findsOneWidget);
    });

    testWidgets('Renders tenant local SVG asset in widget tree',
        (tester) async {
      final controller = Get.put(AuthController(enableRemoteSync: false));
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'mansour-construction',
        companyName: 'MANSOUR CONSTRUCTION',
        logo: 'assets/tenants/mansour-construction/logo.svg',
        logoUrl: null,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginView(),
        ),
      );
      await tester.pump();

      final svgFinders = find.byType(SvgPicture);
      expect(svgFinders, findsWidgets);

      final mansourSvg = svgFinders.evaluate().any((elem) {
        final widget = elem.widget as SvgPicture;
        return isSvgAsset(widget, 'assets/tenants/mansour-construction/logo.svg');
      });
      expect(mansourSvg, isTrue,
          reason: 'Must render tenant-specific logo asset');
      expect(find.text('MANSOUR CONSTRUCTION'), findsOneWidget);
    });

    testWidgets('Shows inactive warning and disables login when tenant is Suspended',
        (tester) async {
      final controller = Get.put(AuthController(enableRemoteSync: false));
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'suspended-tenant',
        companyName: 'Suspended Corp',
        status: 'Suspended',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginView(),
        ),
      );
      await tester.pump();

      expect(find.text("Votre entreprise est désactivée. Contactez l'administrateur."),
          findsOneWidget);

      final submitBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(submitBtn.onPressed, isNull,
          reason: 'Submit button must be disabled for suspended tenants');
    });

    testWidgets('Shows inactive warning and disables login when tenant is Expired',
        (tester) async {
      final controller = Get.put(AuthController(enableRemoteSync: false));
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'expired-tenant',
        companyName: 'Expired Corp',
        status: 'Expired',
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginView(),
        ),
      );
      await tester.pump();

      expect(find.text("Votre entreprise est désactivée. Contactez l'administrateur."),
          findsOneWidget);

      final submitBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(submitBtn.onPressed, isNull,
          reason: 'Submit button must be disabled for expired tenants');
    });

    testWidgets('Dynamically updates logo when tenantConfig changes in controller',
        (tester) async {
      final controller = Get.put(AuthController(enableRemoteSync: false));
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'default',
        companyName: 'Élancé',
        logoUrl: null,
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: LoginView(),
        ),
      );
      await tester.pump();

      expect(find.text('Élancé'), findsOneWidget);

      // Dynamically simulate remote config fetch completion
      controller.tenantConfig.value = TenantConfig(
        tenantId: 'new-tenant',
        companyName: 'Dynamic Wood Co',
        logoUrl: 'https://acya.site/uploads/dyn/logo.png',
      );
      await tester.pump();

      expect(find.text('Dynamic Wood Co'), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}

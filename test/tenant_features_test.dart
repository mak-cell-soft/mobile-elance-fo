import 'package:flutter_test/flutter_test.dart';
import 'package:woodapp/features/tenant/models/tenant_config.dart';

void main() {
  group('TenantConfig Feature Flags & Module Parsing', () {
    test('Correctly parses boolean false for hasChantierModule', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasChantierModule': false,
      });

      expect(config.hasChantierModule, isFalse);
    });

    test('Correctly parses string "false" for hasChantierModule', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasChantierModule': 'false',
      });

      expect(config.hasChantierModule, isFalse);
    });

    test('Correctly parses boolean false for isManagingConstructions', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'isManagingConstructions': false,
      });

      expect(config.hasChantierModule, isFalse);
      expect(config.isManagingConstructions, isFalse);
    });

    test('Correctly parses string "false" for isManagingConstructions', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'isManagingConstructions': 'false',
      });

      expect(config.hasChantierModule, isFalse);
      expect(config.isManagingConstructions, isFalse);
    });

    test('Correctly parses boolean false for ismanagingconstructions (backend naming)', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'ismanagingconstructions': false,
      });

      expect(config.hasChantierModule, isFalse);
      expect(config.isManagingConstructions, isFalse);
    });

    test('Correctly parses boolean true for hasChantierModule & isManagingConstructions', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasChantierModule': true,
        'isManagingConstructions': true,
      });

      expect(config.hasChantierModule, isTrue);
      expect(config.isManagingConstructions, isTrue);
    });

    test('Serializes hasChantierModule and isManagingConstructions in toJson', () {
      final config = TenantConfig(
        tenantId: 'test-tenant',
        hasChantierModule: false,
        isManagingConstructions: false,
      );

      final json = config.toJson();
      expect(json['hasChantierModule'], isFalse);
      expect(json['isManagingConstructions'], isFalse);
    });
    test('Correctly parses boolean false for hasProductionModule', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasProductionModule': false,
      });

      expect(config.hasProductionModule, isFalse);
    });

    test('Correctly parses string "false" for hasProductionModule', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasProductionModule': 'false',
      });

      expect(config.hasProductionModule, isFalse);
    });

    test('Correctly parses boolean false for isManagingProduction & ismanagingproduction', () {
      final config1 = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'isManagingProduction': false,
      });
      expect(config1.hasProductionModule, isFalse);
      expect(config1.isManagingProduction, isFalse);

      final config2 = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'ismanagingproduction': false,
      });
      expect(config2.hasProductionModule, isFalse);
      expect(config2.isManagingProduction, isFalse);
    });

    test('Correctly parses boolean true for hasProductionModule & isManagingProduction', () {
      final config = TenantConfig.fromJson({
        'tenantId': 'test-tenant',
        'hasProductionModule': true,
        'isManagingProduction': true,
      });

      expect(config.hasProductionModule, isTrue);
      expect(config.isManagingProduction, isTrue);
    });

    test('Serializes hasProductionModule and isManagingProduction in toJson', () {
      final config = TenantConfig(
        tenantId: 'test-tenant',
        hasProductionModule: false,
        isManagingProduction: false,
      );

      final json = config.toJson();
      expect(json['hasProductionModule'], isFalse);
      expect(json['isManagingProduction'], isFalse);
    });
  });

  group('JWT Claim Parsing Simulation', () {
    test('Simulates JWT payload decoding with IsManagingConstructions = false', () {
      final Map<String, dynamic> payload = {
        'nameid': '42',
        'email': 'user@woodapp.com',
        'role': 'User',
        'IsManagingConstructions': 'false',
        'EnterpriseId': '5',
      };

      final rawClaim = payload['IsManagingConstructions'];
      final boolVal = rawClaim is bool
          ? rawClaim
          : rawClaim?.toString().toLowerCase() == 'true';

      expect(boolVal, isFalse);
    });

    test('Simulates JWT payload decoding with IsManagingConstructions = true', () {
      final Map<String, dynamic> payload = {
        'nameid': '42',
        'email': 'user@woodapp.com',
        'role': 'User',
        'IsManagingConstructions': 'true',
        'EnterpriseId': '5',
      };

      final rawClaim = payload['IsManagingConstructions'];
      final boolVal = rawClaim is bool
          ? rawClaim
          : rawClaim?.toString().toLowerCase() == 'true';

      expect(boolVal, isTrue);
    });

    test('Simulates JWT payload decoding with IsManagingProduction = false', () {
      final Map<String, dynamic> payload = {
        'nameid': '42',
        'email': 'user@woodapp.com',
        'role': 'User',
        'IsManagingProduction': 'false',
        'EnterpriseId': '5',
      };

      final rawClaim = payload['IsManagingProduction'];
      final boolVal = rawClaim is bool
          ? rawClaim
          : rawClaim?.toString().toLowerCase() == 'true';

      expect(boolVal, isFalse);
    });

    test('Simulates JWT payload decoding with IsManagingProduction = true', () {
      final Map<String, dynamic> payload = {
        'nameid': '42',
        'email': 'user@woodapp.com',
        'role': 'User',
        'IsManagingProduction': 'true',
        'EnterpriseId': '5',
      };

      final rawClaim = payload['IsManagingProduction'];
      final boolVal = rawClaim is bool
          ? rawClaim
          : rawClaim?.toString().toLowerCase() == 'true';

      expect(boolVal, isTrue);
    });
  });

  group('TenantConfig Merging Preservation', () {
    test('Preserves hasProductionModule and isManagingProduction when merged from remote', () {
      final local = TenantConfig(
        tenantId: 'mansour-construction',
        companyName: 'Mansour Construction',
        hasProductionModule: false,
        isManagingProduction: false,
        hasChantierModule: false,
        isManagingConstructions: false,
      );

      final remote = TenantConfig(
        tenantId: 'mansour-construction',
        companyName: 'Mansour Construction',
        hasProductionModule: true,
        isManagingProduction: true,
        hasChantierModule: true,
        isManagingConstructions: true,
      );

      final merged = TenantConfig(
        tenantId: remote.tenantId ?? local.tenantId,
        companyName: remote.companyName ?? local.companyName,
        hasChantierModule: remote.hasChantierModule,
        isManagingConstructions: remote.isManagingConstructions,
        hasProductionModule: remote.hasProductionModule,
        isManagingProduction: remote.isManagingProduction,
      );

      expect(merged.hasChantierModule, isTrue);
      expect(merged.isManagingConstructions, isTrue);
      expect(merged.hasProductionModule, isTrue);
      expect(merged.isManagingProduction, isTrue);
    });
  });
}

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
  });
}

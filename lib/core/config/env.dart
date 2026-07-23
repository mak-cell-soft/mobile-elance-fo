enum Flavor { development, preprod, production }

class EnvConfig {
  EnvConfig._();

  static late Flavor flavor;

  static void init(Flavor value) {
    flavor = value;
  }

  static String get name {
    switch (flavor) {
      case Flavor.development:
        return 'Development';
      case Flavor.preprod:
        return 'Preprod';
      case Flavor.production:
        return 'Production';
    }
  }

  // All flavors currently point at the single deployed server (acya.site).
  // Once dedicated dev/preprod backends exist, split these values per flavor.
  static String get apiBaseUrl {
    switch (flavor) {
      case Flavor.development:
        return 'https://acya.site/api/';
      case Flavor.preprod:
        return 'https://acya.site/api/';
      case Flavor.production:
        return 'https://acya.site/api/';
    }
  }

  static bool get isProduction => flavor == Flavor.production;
}

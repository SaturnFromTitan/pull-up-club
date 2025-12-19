class AppConstants {
  static const String appTitle = "Pull-Up Club";
  static const String appStoreUrl =
      "https://apps.apple.com/app/pull-up-club/id6754757771";
  static const String defaultPackageName = "com.saturnfromtitan.pullupclub";

  // Remote config
  // even though we use a custom URL for github pages, we still refernce the original github
  // repository URL. It redirects to the custom URL, so it still works.
  // We hope that this is more robust as we might not continue to pay for the custom domain.
  static const String remoteConfigUrl =
      "https://saturnfromtitan.github.io/pull-up-club/app-config.json";

  // Default app config values
  // ⚠️ These values should resemble the values in the docs/app_config.json
  static const String defaultMinAppVersion = "1.1.0";
  static const String defaultSentryDsn =
      "https://e8445aeb8a976bca9c47de2073137e70@o4510399352012800.ingest.de.sentry.io/4510399355289680";

  // Supabase configuration defaults
  static const String defaultBackendUrl = "https://kifrblptoxfyefexpega.supabase.co";
  static const String defaultBackendPublishableKey =
      "sb_publishable_UQQXGFFXnawExrEkjFWKrA_ay_l8E8J";
}

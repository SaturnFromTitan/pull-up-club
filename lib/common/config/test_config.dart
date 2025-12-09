class TestConfig {
  TestConfig._();

  /// Whether the app is running in test mode
  /// In test mode, rest durations are shortened to 5 seconds
  static bool get isTestMode {
    // the environment is only used for the integration tests
    // ignore: do_not_use_environment
    const testModeEnv = String.fromEnvironment("TEST_MODE", defaultValue: "false");
    // Compare case-insensitively, but since it's a const, we check both cases
    return testModeEnv.toLowerCase() == "true";
  }

  static const int testRestDurationMillis = 4 * 1_000;
}

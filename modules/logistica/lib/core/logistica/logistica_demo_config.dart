class LogisticaDemoConfig {
  static const demoSeedEnabled = bool.fromEnvironment(
    'DEMO_SEED_ENABLED',
    defaultValue: false,
  );
}

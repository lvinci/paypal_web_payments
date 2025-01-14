/// Represents the different environments available for PayPal integration.
enum PaypalEnvironment {
  /// The production environment where real transactions are processed.
  /// Use this when your application is live and handling actual payments.
  live,

  /// The testing environment provided by PayPal for development and testing.
  /// Use this during development to simulate payments and transactions.
  sandbox,
}

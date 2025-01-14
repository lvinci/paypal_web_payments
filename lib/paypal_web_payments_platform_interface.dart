import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'paypal_web_payments_method_channel.dart';

abstract class PaypalWebPaymentsPlatform extends PlatformInterface {
  /// Constructs a PaypalWebPaymentsPlatform.
  PaypalWebPaymentsPlatform() : super(token: _token);

  static final Object _token = Object();

  static PaypalWebPaymentsPlatform _instance = MethodChannelPaypalWebPayments();

  /// The default instance of [PaypalWebPaymentsPlatform] to use.
  ///
  /// Defaults to [MethodChannelPaypalWebPayments].
  static PaypalWebPaymentsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PaypalWebPaymentsPlatform] when
  /// they register themselves.
  static set instance(PaypalWebPaymentsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}

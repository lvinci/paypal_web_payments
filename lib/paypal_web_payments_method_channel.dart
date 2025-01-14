import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'paypal_web_payments_platform_interface.dart';

/// An implementation of [PaypalWebPaymentsPlatform] that uses method channels.
class MethodChannelPaypalWebPayments extends PaypalWebPaymentsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('paypal_web_payments');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

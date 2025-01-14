
import 'paypal_web_payments_platform_interface.dart';

class PaypalWebPayments {
  Future<String?> getPlatformVersion() {
    return PaypalWebPaymentsPlatform.instance.getPlatformVersion();
  }
}

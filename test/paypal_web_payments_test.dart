import 'package:flutter_test/flutter_test.dart';
import 'package:paypal_web_payments/paypal_web_payments.dart';
import 'package:paypal_web_payments/paypal_web_payments_platform_interface.dart';
import 'package:paypal_web_payments/paypal_web_payments_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPaypalWebPaymentsPlatform
    with MockPlatformInterfaceMixin
    implements PaypalWebPaymentsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PaypalWebPaymentsPlatform initialPlatform = PaypalWebPaymentsPlatform.instance;

  test('$MethodChannelPaypalWebPayments is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPaypalWebPayments>());
  });

  test('getPlatformVersion', () async {
    PaypalWebPayments paypalWebPaymentsPlugin = PaypalWebPayments();
    MockPaypalWebPaymentsPlatform fakePlatform = MockPaypalWebPaymentsPlatform();
    PaypalWebPaymentsPlatform.instance = fakePlatform;

    expect(await paypalWebPaymentsPlugin.getPlatformVersion(), '42');
  });
}

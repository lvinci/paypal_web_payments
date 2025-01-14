import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypal_web_payments/paypal_web_payments_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPaypalWebPayments platform = MethodChannelPaypalWebPayments();
  const MethodChannel channel = MethodChannel('paypal_web_payments');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

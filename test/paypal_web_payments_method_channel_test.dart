import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paypal_web_payments/paypal_web_payments.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel('com.github.lvinci/paypal_web_payments');

  late PaypalPaymentService paymentService;

  // Mock callback implementations
  bool onFailureCalled = false;
  bool onCanceledCalled = false;
  bool onSuccessCalled = false;

  setUp(() {
    paymentService = PaypalPaymentService(
      onFailureCallback: (_, __) => onFailureCalled = true,
      onCanceledCallback: () => onCanceledCalled = true,
      onSuccessCallback: (_, __) => onSuccessCalled = true,
    );
  });

  group('Paypal Payment Service Tests', () {
    const String clientId = 'testClientId';
    const String returnUrl = 'https://test.return.url';
    const String orderId = 'testOrderId';

    test('initializePaypalClient sends correct arguments', () async {
      final log = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await paymentService.initializePaypalClient(
        clientId: clientId,
        returnUrl: returnUrl,
        environment: PaypalEnvironment.sandbox,
      );

      expect(log, hasLength(1), reason: 'Expected one method call');
      expect(
        log.first.method,
        'initializePaypalClient',
        reason: 'Method should be initializePaypalClient',
      );
      expect(
        log.first.arguments,
        {
          'clientId': clientId,
          'environment': 'SANDBOX',
          'returnUrl': returnUrl,
        },
        reason: 'Arguments should match input',
      );
    });

    test('startCheckout sends correct arguments', () async {
      final log = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await paymentService.startCheckout(orderId: orderId);

      expect(log, hasLength(1), reason: 'Expected one method call');
      expect(
        log.first.method,
        'startCheckout',
        reason: 'Method should be startCheckout',
      );
      expect(
        log.first.arguments,
        {'orderId': orderId},
        reason: 'Arguments should match input',
      );
    });

    test('onCanceledCallback does not crash with invalid arguments', () async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('onCanceledCallback', 'invalidArgument'),
        ),
        (data) {},
      );

      expect(
        onCanceledCalled,
        isFalse,
        reason:
            'onCanceledCallback should not be called with invalid arguments',
      );
    });

    test('onFailureCallback handles missing or invalid arguments gracefully',
        () async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('onFailureCallback', {
            'code': 'invalidCode', // Invalid type
          }),
        ),
        (data) {},
      );

      expect(
        onFailureCalled,
        isTrue,
        reason: 'onFailureCallback should handle invalid argument types',
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('onFailureCallback', 'invalidArgument'),
        ),
        (data) {},
      );

      expect(
        onFailureCalled,
        isTrue,
        reason: 'onFailureCallback should handle invalid argument structure',
      );
    });

    test('onSuccessCallback handles missing or invalid arguments gracefully',
        () async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('onSuccessCallback', {
            'orderId': 12345, // Invalid type
          }),
        ),
        (data) {},
      );

      expect(
        onSuccessCalled,
        isTrue,
        reason: 'onSuccessCallback should handle invalid argument types',
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('onSuccessCallback', 'invalidArgument'),
        ),
        (data) {},
      );

      expect(
        onSuccessCalled,
        isTrue,
        reason: 'onSuccessCallback should handle invalid argument structure',
      );
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}

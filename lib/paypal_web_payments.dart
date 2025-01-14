import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:paypal_web_payments/paypal_callbacks.dart';
import 'package:paypal_web_payments/paypal_environment.dart';

export 'paypal_environment.dart';
export 'paypal_callbacks.dart';

/// Service class for handling PayPal payments in Flutter applications.
///
/// This class provides methods to initialize the PayPal client,
/// start the checkout process, and handle callbacks for payment events.
class PaypalPaymentService {
  /// Creates an instance of [PaypalPaymentService].
  ///
  /// Requires callbacks for handling payment results
  PaypalPaymentService({
    required this.onFailureCallback,
    required this.onCanceledCallback,
    required this.onSuccessCallback,
  }) {
    _platform.setMethodCallHandler(_methodCallHandler);
  }

  /// Callback invoked when a payment fails
  final PaypalPaymentFailureCallback onFailureCallback;

  /// Callback invoked when a payment is canceled
  final PaypalPaymentCanceledCallback onCanceledCallback;

  /// Callback invoked when a payment is successful
  final PaypalPaymentSuccessCallback onSuccessCallback;

  /// Method channel used for communication between Flutter and the native app
  static const MethodChannel _platform =
      MethodChannel('com.github.lvinci/paypal_web_payments');

  /// Initializes the PayPal client with the given environment and return URL.
  ///
  /// Parameters:
  /// - [clientId]: The PayPal client ID for authentication
  /// - [returnUrl]: The URL to return to after payment completion
  /// - [environment]: The PayPal environment, defaults to live
  Future<void> initializePaypalClient({
    required String clientId,
    required String returnUrl,
    PaypalEnvironment environment = PaypalEnvironment.live,
  }) async {
    await _platform.invokeMethod('initializePaypalClient', {
      'clientId': clientId,
      'environment': environment.name.toUpperCase(),
      'returnUrl': returnUrl,
    });
  }

  /// Starts the PayPal checkout process for the specified order ID.
  ///
  /// Parameters:
  /// - [orderId]: The unique identifier for the PayPal order.
  Future<void> startCheckout({required String orderId}) async {
    await _platform.invokeMethod('startCheckout', {'orderId': orderId});
  }

  /// Handles incoming method calls from the native platform.
  ///
  /// This method is responsible for invoking the appropriate callbacks
  /// based on the native method call.
  Future<void> _methodCallHandler(MethodCall call) async {
    try {
      // Check whether arguments are in the expected format
      final arguments = call.arguments;
      if (arguments is! Map) {
        return;
      }
      // Check which method was called by the native plugin
      switch (call.method) {
        // Paypal payment was canceled by the user
        case 'onCanceledCallback':
          onCanceledCallback();
          break;
        // Paypal payment was unsuccessful
        case 'onFailureCallback':
          final code = arguments['code'];
          final description = arguments['description'];
          onFailureCallback(
            code is int ? code : 0,
            description is String ? description : '',
          );
          break;
        // Paypal payment was successful
        case 'onSuccessCallback':
          final orderId = arguments['orderId'];
          final payerId = arguments['payerId'];
          onSuccessCallback(
            orderId is String ? orderId : '',
            payerId is String ? payerId : '',
          );
          break;
      }
    } on Exception catch (e) {
      debugPrint('Error in _methodCallHandler: $e');
    }
  }
}

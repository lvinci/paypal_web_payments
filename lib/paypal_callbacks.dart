/// A callback function type for handling PayPal payment failures.
///
/// This callback is triggered when a PayPal payment fails, providing
/// details about the failure.
///
/// Parameters:
/// - [code]: the error code associated with the failure
/// - [description]: the reason for the failure.
typedef PaypalPaymentFailureCallback = void Function(
  int code,
  String description,
);

/// A callback function type for handling successful PayPal payments.
///
/// This callback is triggered when a PayPal payment is successfully completed,
/// providing relevant details about the transaction.
///
/// Parameters:
/// - [orderId]: the unique identifier for the PayPal order.
/// - [payerId]: the unique identifier for the payer.
typedef PaypalPaymentSuccessCallback = void Function(
  String orderId,
  String payerId,
);

/// A callback function type for handling canceled PayPal payments.
///
/// This callback is triggered when a PayPal payment is canceled by the user
/// before completion.
typedef PaypalPaymentCanceledCallback = void Function();

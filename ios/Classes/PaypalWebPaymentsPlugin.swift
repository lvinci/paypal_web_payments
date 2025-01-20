import Flutter
import UIKit
import PayPal

public class PaypalWebPaymentsPlugin: NSObject, FlutterPlugin {
    
    /// A global variable to store the Flutter method channel for communication between Flutter and native code.
    static var methodChannel: FlutterMethodChannel? = nil
    
    /// A global variable to store the PayPal web checkout client instance.
    var paypalClient: PayPalWebCheckoutClient? = nil
    
    /// A global instance for handling PayPal payment callbacks.
    var paypalCallbacks = PaypalPaymentCallbacks()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        var channel = FlutterMethodChannel(name: "com.github.lvinci/paypal_web_payments", binaryMessenger: registrar.messenger())
        let instance = PaypalWebPaymentsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        methodChannel = channel
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            return result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
        }
        
        switch call.method {
        case "initializePaypalClient":
            handleInitializePaypalClient(args: args, result: result)
        case "startCheckout":
            handleStartCheckout(args: args, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Handles the "initializePaypalClient" method call
    private func handleInitializePaypalClient(args: [String: Any], result: @escaping FlutterResult) {
        guard let clientId = args["clientId"] as? String,
              let environment = args["environment"] as? String else {
            return result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing clientId or environment", details: nil))
        }
        
        initializePaypalClient(clientId: clientId, environment: environment)
        result(true)
    }
    
    /// Handles the "startCheckout" method call
    private func handleStartCheckout(args: [String: Any], result: @escaping FlutterResult) {
        guard let orderId = args["orderId"] as? String else {
            return result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing orderId", details: nil))
        }
        
        let success = startCheckout(orderId: orderId)
        result(success)
    }
    
    /// Initializes the PayPal web checkout client with a given client ID and environment.
    /// - Parameters:
    ///   - clientId: The client ID obtained from PayPal for your app.
    ///   - environment: The environment to use, either "SANDBOX" for testing or "LIVE" for production.
    private func initializePaypalClient(clientId: String, environment: String) {
        let config = CoreConfig(clientID: clientId, environment: environment == "SANDBOX" ? .sandbox : .live)
        paypalClient = PayPalWebCheckoutClient(config: config)
    }
    
    /// Initiates a PayPal checkout process for the given order ID.
    /// - Parameter:
    ///   - orderId: The ID of the order to be checked out.
    /// - Returns: A Bool indicating whether the checkout process was successfully initiated.
    private func startCheckout(orderId: String) -> Bool {
        guard let paypalClient = paypalClient else { return false }
        let request = PayPalWebCheckoutRequest(orderID: orderId, fundingSource: .paypal)
        paypalCallbacks.startCheckout(paypalClient: paypalClient, request: request)
        return true
    }
    
    /// A class that implements the `PayPalWebCheckoutDelegate` protocol to handle PayPal checkout callbacks.
    class PaypalPaymentCallbacks: PayPalWebCheckoutDelegate {
        
        /// Starts the PayPal checkout process for the provided request.
        /// - Parameter:
        ///   - request: The PayPal web checkout request.
        func startCheckout(paypalClient: PayPalWebCheckoutClient, request: PayPalWebCheckoutRequest) {
            paypalClient.delegate = self
            paypalClient.start(request: request)
        }
        
        /// Invoked when the PayPal checkout process finishes successfully.
        /// - Parameters:
        ///   - client: The PayPal web checkout client.
        ///   - result: The result of the checkout process.
        func payPal(_ client: PayPalWebCheckoutClient, didFinishWithResult result: PayPalWebCheckoutResult) {
            methodChannel?.invokeMethod("onSuccessCallback", arguments: [
                "orderId": result.orderID,
                "payerId": result.payerID
            ])
        }
        
        /// Invoked when the PayPal checkout process finishes with an error.
        /// - Parameters:
        ///   - client: The PayPal web checkout client.
        ///   - error: The error that occurred during the checkout process.
        func payPal(_ client: PayPalWebCheckoutClient, didFinishWithError error: CoreSDKError) {
            methodChannel?.invokeMethod("onFailureCallback", arguments: [
                "code": error.code ?? 0,
                "description": error.errorDescription ?? "",
            ])
        }
        
        /// Invoked when the user cancels the PayPal checkout process.
        /// - Parameter:
        ///   - client: The PayPal web checkout client.
        func payPalDidCancel(_ client: PayPalWebCheckoutClient) {
            methodChannel?.invokeMethod("onCanceledCallback", arguments: [])
        }
    }
}

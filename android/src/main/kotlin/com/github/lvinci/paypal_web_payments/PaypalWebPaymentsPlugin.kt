package com.github.lvinci.paypal_web_payments

import android.content.Intent
import androidx.fragment.app.FragmentActivity
import com.paypal.android.corepayments.CoreConfig
import com.paypal.android.corepayments.Environment
import com.paypal.android.corepayments.PayPalSDKError
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutClient
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutFundingSource
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutListener
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutRequest
import com.paypal.android.paypalwebpayments.PayPalWebCheckoutResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * PaypalWebPaymentsPlugin integrates PayPal Web Payments with Flutter.
 *
 * Responsibilities:
 * - Initializes the PayPal client with a `clientId`, `environment`, and `returnUrl`.
 * - Manages the PayPal checkout process and handles success, failure, and cancellation events.
 * - Communicates with Flutter via a `MethodChannel`.
 * - Handles activity lifecycle events for proper intent and resource management.
 */
class PaypalWebPaymentsPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /**
   * The name of the method channel used for communication between Flutter and the native code.
   */
  private val methodChannelName = "com.github.lvinci/paypal_web_payments"

  /**
   * Error code used to indicate invalid arguments passed to a method.
   */
  private val invalidArgErrorCode = "INVALID_ARGUMENT"

  /**
   * Client instance for handling PayPal Web Checkout operations.
   */
  private var paypalCheckoutClient: PayPalWebCheckoutClient? = null

  /**
   * MethodChannel for communicating with the Flutter application.
   */
  private lateinit var channel: MethodChannel

  /**
   * Reference to the FragmentActivity, used for handling activity-specific operations.
   */
  private var fragmentActivity: FragmentActivity? = null

  /**
   * Stores the result of the PayPal link intent to manage callbacks accurately.
   */
  private var result: PayPalWebCheckoutResult? = null

  /**
   * Called when the plugin is attached to the Flutter engine.
   *
   * @param flutterPluginBinding Provides the necessary bindings to interact with the Flutter engine.
   */
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannelName)
    channel.setMethodCallHandler(this)
  }

  /**
   * Called when the plugin is detached from the Flutter engine.
   *
   * @param binding Provides the necessary bindings to interact with the Flutter engine.
   */
  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  /**
   * Called when the plugin is attached to an activity.
   *
   * @param binding Provides access to the activity and allows listeners to be added.
   */
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    val activity = binding.activity
    if (activity is FragmentActivity) {
      this.fragmentActivity = activity
    }
    // Set up the listener for new intents
    binding.addOnNewIntentListener { intent ->
      handleNewIntent(intent)
      true
    }
  }

  /**
   * Called when the activity configuration changes and the plugin is detached.
   */
  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  /**
   * Called when the plugin is reattached to an activity after a configuration change.
   *
   * @param binding Provides access to the activity and allows listeners to be added.
   */
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  /**
   * Called when the plugin is detached from the activity.
   */
  override fun onDetachedFromActivity() {
    this.fragmentActivity = null
  }

  /**
   * Handles method calls from the Flutter application.
   *
   * @param call Represents the method call from Flutter.
   * @param result Used to send results back to the Flutter application.
   */
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initializePaypalClient" -> runInitializePaypalClient(call, result)
      "startCheckout" -> runStartCheckout(call, result)
      else -> result.notImplemented()
    }
  }

  /**
   * Initializes the PayPal client with the provided configuration.
   *
   * @param call The method call containing parameters.
   * @param result The result callback to return success or error.
   */
  private fun runInitializePaypalClient(call: MethodCall, result: Result) {
    val environment = when (call.argument<String>("environment")?.uppercase()) {
      "LIVE" -> Environment.LIVE
      "SANDBOX" -> Environment.SANDBOX
      else -> null
    }
    if (environment == null) {
      result.error(invalidArgErrorCode, "environment", null)
      return
    }
    val clientId = call.argument<String>("clientId")
    if (clientId == null) {
      result.error(invalidArgErrorCode, "clientId", null)
      return
    }
    val returnUrl = call.argument<String>("returnUrl")
    if (returnUrl == null) {
      result.error(invalidArgErrorCode, "returnUrl", null)
      return
    }
    initializePaypalClient(clientId, environment, returnUrl)
    result.success(true)
  }

  /**
   * Starts the PayPal checkout process with the specified order ID.
   *
   * @param call The method call containing parameters.
   * @param result The result callback to return success or error.
   */
  private fun runStartCheckout(call: MethodCall, result: Result) {
    val orderId = call.argument<String>("orderId")
    if (orderId == null) {
      result.error(invalidArgErrorCode, "orderId", null)
      return
    }
    startCheckout(orderId)
    result.success(true)
  }

  /**
   * Initializes the PayPal client with the given parameters and registers listeners.
   *
   * @param clientId The client ID for PayPal integration.
   * @param environment The environment for PayPal (LIVE or SANDBOX).
   * @param returnUrl The URL to return to after payment.
   */
  private fun initializePaypalClient(
    clientId: String,
    environment: Environment,
    returnUrl: String
  ) {
    // Initialize config and paypal client
    val config = CoreConfig(clientId, environment)
    // HERE IS THE PROBLEM. HOW CAN I get a FragmentActivity in the place of this
    this.paypalCheckoutClient =
      fragmentActivity?.let { PayPalWebCheckoutClient(it, config, returnUrl) }
    // Register callbacks
    this.paypalCheckoutClient?.listener = object : PayPalWebCheckoutListener {
      override fun onPayPalWebSuccess(result: PayPalWebCheckoutResult) {
        onSuccessCallback(result.orderId, result.payerId)
      }

      override fun onPayPalWebFailure(error: PayPalSDKError) {
        onFailureCallback(error.code, error.errorDescription)
      }

      override fun onPayPalWebCanceled() {
        onCanceledCallback()
      }
    }
  }

  /**
   * Initiates the PayPal checkout process with the specified order ID.
   *
   * @param orderId The ID of the order to be processed.
   */
  private fun startCheckout(orderId: String) {
    this.result = PayPalWebCheckoutResult(orderId, null)
    val request = PayPalWebCheckoutRequest(orderId, PayPalWebCheckoutFundingSource.PAYPAL)
    this.paypalCheckoutClient?.start(request)
  }

  /**
   * Handles new intents received by the activity.
   * The intent is handled manually because the PayPal SDK sometimes does not recognize
   * successful payment flows correctly.
   *
   * @param intent The new intent received.
   */
  private fun handleNewIntent(intent: Intent) {
    val uri = intent.data
    if (uri != null) {
      val payerId = uri.getQueryParameter("PayerID")
      val token = uri.getQueryParameter("token")
      if (token != null) {
        this.result = PayPalWebCheckoutResult(this.result?.orderId, payerId)
        return
      }
      this.result = PayPalWebCheckoutResult(this.result?.orderId, null)
    }
  }


  /**
   * Sends a failure callback to the Flutter side.
   *
   * @param code An error code indicating the type of failure.
   * @param description A description providing details about the failure.
   */
  private fun onFailureCallback(code: Int, description: String) {
    this.channel.invokeMethod(
      "onFailureCallback", mapOf(
        "code" to code,
        "description" to description
      )
    )
  }

  /**
   * Sends a cancellation callback to the Flutter side.
   *
   * If a payer ID is present in the result, triggers a success callback.
   * Otherwise, sends a canceled message.
   */
  private fun onCanceledCallback() {
    // If the result does have a payer id, consider the process as successful
    if (this.result?.payerId != null) {
      onSuccessCallback(this.result?.orderId, this.result?.payerId)
      return
    }
    // Send cancelled message
    this.channel.invokeMethod("onCanceledCallback", null)
  }

  /**
   * Sends a success callback to the Flutter side.
   *
   * @param orderId The unique identifier for the order.
   * @param payerId The identifier for the payer involved in the transaction.
   */
  private fun onSuccessCallback(orderId: String?, payerId: String?) {
    this.channel.invokeMethod(
      "onSuccessCallback", mapOf(
        "orderId" to orderId,
        "payerId" to payerId
      )
    )
  }

}

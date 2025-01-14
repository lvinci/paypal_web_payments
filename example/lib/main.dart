import 'package:flutter/material.dart';
import 'package:paypal_web_payments/paypal_web_payments.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // ignore: unused_field
  final _paypalWebPaymentsPlugin = PaypalPaymentService(
    onFailureCallback: (int code, String description) {},
    onCanceledCallback: () {},
    onSuccessCallback: (String orderId, String payerId) {},
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
      ),
    );
  }
}

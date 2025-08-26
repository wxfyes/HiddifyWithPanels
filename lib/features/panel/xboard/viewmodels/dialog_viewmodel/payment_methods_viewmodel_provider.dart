// payment_methods_view_model_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';


class PaymentMethodsViewModelParams {
  final String tradeNo;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;
  final Function(String) onOpenInAppPayment; // 新增：应用内支付回调

  PaymentMethodsViewModelParams({
    required this.tradeNo,
    required this.totalAmount,
    required this.onPaymentSuccess,
    required this.onOpenInAppPayment, // 新增：应用内支付回调
  });
}

final paymentMethodsViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<PaymentMethodsViewModel, PaymentMethodsViewModelParams>(
  (ref, params) => PaymentMethodsViewModel(
    tradeNo: params.tradeNo,
    totalAmount: params.totalAmount,
    onPaymentSuccess: params.onPaymentSuccess,
    onOpenInAppPayment: params.onOpenInAppPayment, // 新增：应用内支付回调
  ),
);

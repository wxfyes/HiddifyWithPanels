// payment_methods_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel_provider.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
// 导入 ViewModel Provider

class PaymentMethodsDialog extends ConsumerStatefulWidget {
  final String tradeNo;
  final List<dynamic> paymentMethods;
  final double totalAmount;
  final Translations t;
  final WidgetRef ref;
  final Function(String) onOpenInAppPayment; // 新增：应用内支付回调

  const PaymentMethodsDialog({
    super.key,
    required this.tradeNo,
    required this.paymentMethods,
    required this.totalAmount,
    required this.t,
    required this.ref,
    required this.onOpenInAppPayment, // 新增：应用内支付回调
  });

  @override
  _PaymentMethodsDialogState createState() => _PaymentMethodsDialogState();
}

class _PaymentMethodsDialogState extends ConsumerState<PaymentMethodsDialog> {
  late final PaymentMethodsViewModelParams _params;
  late final AutoDisposeChangeNotifierProvider<PaymentMethodsViewModel>
      _provider;

  @override
  void initState() {
    super.initState();

    _params = PaymentMethodsViewModelParams(
      tradeNo: widget.tradeNo,
      totalAmount: widget.totalAmount,
      onPaymentSuccess: () {
        // 支付成功回调 - 安全关闭对话框
        try {
          if (kDebugMode) {
            print('支付成功，准备关闭对话框');
          }
          
          // 检查 context 是否还有效
          if (!mounted) {
            if (kDebugMode) {
              print('Widget 已销毁，无法关闭对话框');
            }
            return;
          }
          
          // 安全关闭对话框，只关闭一次
          try {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              if (kDebugMode) {
                print('成功关闭第一个对话框');
              }
            }
            
            // 等待一帧后再关闭第二个对话框
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
                if (kDebugMode) {
                  print('成功关闭第二个对话框');
                }
              }
            });
          } catch (e) {
            if (kDebugMode) {
              print('关闭对话框失败: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('支付成功处理失败: $e');
          }
        }
      },
      onOpenInAppPayment: widget.onOpenInAppPayment, // 新增：应用内支付回调
    );

    _provider = paymentMethodsViewModelProvider(_params);
  }

  // 显示EPay子选择页面的方法
  void _showEPaySubSelection(BuildContext context, Map<String, dynamic> paymentMethod, PaymentMethodsViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '选择支付方式',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: const Text('支付宝支付'),
                subtitle: Text('手续费: ${paymentMethod['handling_fee_percent']}%'),
                onTap: () {
                  Navigator.of(context).pop(); // 关闭子选择页面
                  Navigator.of(context).pop(); // 关闭支付方式选择页面
                  if (kDebugMode) {
                    print('选择EPay支付宝支付');
                  }
                  // 修改支付方式名称，标识为支付宝
                  final modifiedMethod = Map<String, dynamic>.from(paymentMethod);
                  modifiedMethod['name'] = 'EPay支付宝支付';
                  viewModel.handlePayment(modifiedMethod);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text('微信支付'),
                subtitle: Text('手续费: ${paymentMethod['handling_fee_percent']}%'),
                onTap: () {
                  Navigator.of(context).pop(); // 关闭子选择页面
                  Navigator.of(context).pop(); // 关闭支付方式选择页面
                  if (kDebugMode) {
                    print('选择EPay微信支付');
                  }
                  // 修改支付方式名称，标识为微信
                  final modifiedMethod = Map<String, dynamic>.from(paymentMethod);
                  modifiedMethod['name'] = 'EPay微信支付';
                  viewModel.handlePayment(modifiedMethod);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭子选择页面
              },
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(_provider);
    final t = ref.watch(translationsProvider); // 引入本地化文件
    return AlertDialog(
      title: Text(
        t.purchase.selectPaymentMethod,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: 8),
                        // 添加余额支付选项
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                  title: const Text(
                    '余额支付',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.purchase.total}: ${widget.totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          '(无手续费)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (kDebugMode) {
                      print('选择余额支付');
                    }
                    Navigator.of(context).pop(); // 关闭对话框
                    // 调用余额支付
                    viewModel.handleBalancePayment();
                  },
                ),
                Divider(
                  color: Colors.grey[300],
                  thickness: 0.5,
                ),
              ],
            ),
            // 其他支付方式
            ...widget.paymentMethods.map((method) {
              final Map<String, dynamic> paymentMethod =
                  method as Map<String, dynamic>;

              final feePercent = paymentMethod['handling_fee_percent'] != null
                  ? double.tryParse(
                          paymentMethod['handling_fee_percent'].toString()) ??
                      0.0
                  : 0.0;
              final handlingFee = widget.totalAmount * feePercent / 100;
              final totalPrice = widget.totalAmount + handlingFee;

              return Column(
                children: [
                  ListTile(
                    title: Text(
                      paymentMethod['name']?.toString() ?? t.purchase.unknown,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Displaying the final price prominently
                          Text(
                            '${t.purchase.totalPrice}: ${totalPrice.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            '(${widget.totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb} + '
                            '${handlingFee.toStringAsFixed(2)} ${widget.t.purchase.rmb} ${t.purchase.fee})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Temporary package price (less emphasized)
                          Text(
                            '${t.purchase.total}: ${widget.totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${t.purchase.fee}: ${feePercent.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      final paymentId = paymentMethod['id'];
                      if (paymentId == 2) {
                        // MGate (支付宝) - 直接处理支付
                        if (kDebugMode) {
                          print('选择MGate支付平台，直接处理支付');
                        }
                        Navigator.of(context).pop(); // Close dialog
                        viewModel.handlePayment(paymentMethod);
                      } else if (paymentId == 11) {
                        // EPay - 显示子选择页面
                        if (kDebugMode) {
                          print('选择EPay支付平台，显示子选择页面');
                        }
                        _showEPaySubSelection(context, paymentMethod, viewModel);
                      } else {
                        // 其他支付平台，直接处理
                        Navigator.of(context).pop(); // Close dialog
                        viewModel.handlePayment(paymentMethod);
                      }
                    },
                  ),
                  Divider(
                    color: Colors.grey[300],
                    thickness: 0.5,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text(
            t.purchase.close,
            style: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

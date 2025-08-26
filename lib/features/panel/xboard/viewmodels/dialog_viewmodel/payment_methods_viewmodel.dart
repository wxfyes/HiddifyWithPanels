// payment_methods_view_model.dart

// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/monitor_pay_status.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethodsViewModel extends ChangeNotifier {
  final String tradeNo;
  final double totalAmount;
  final VoidCallback onPaymentSuccess;
  final Function(String) onOpenInAppPayment; // 新增：应用内支付回调
  final PurchaseService _purchaseService = PurchaseService();

  PaymentMethodsViewModel({
    required this.tradeNo,
    required this.totalAmount,
    required this.onPaymentSuccess,
    required this.onOpenInAppPayment, // 新增：应用内支付回调
  });

  Future<void> handlePayment(dynamic selectedMethod) async {
    final accessToken = await getToken(); // 获取用户的token
    try {
      if (kDebugMode) {
        print('开始处理支付，支付方式: ${selectedMethod['name']} (ID: ${selectedMethod['id']})');
      }

      // 调用 submitOrder 并获取完整的响应字典
      final response = await _purchaseService.submitOrder(
        tradeNo,
        selectedMethod['id'].toString(),
        accessToken!,
      );

      if (kDebugMode) {
        print('支付响应: $response');
      }

      // 获取 type 和 data 字段
      final type = response['type'];
      final data = response['data'];

      // 确保 type 是 int 并且 data 是期望的类型
      if (type is int) {
        // 处理支付响应
        if (type == -1 && data == true) {
          // 余额支付成功
          if (kDebugMode) {
            print('余额支付成功，订单已完成');
          }
          handlePaymentSuccess();
          return;
        } else if (type == 1 && data is String) {
          // 需要跳转支付平台（余额不足或选择其他支付方式）
          if (kDebugMode) {
            print('需要跳转支付平台，支付链接: $data');
          }
          
          // 根据支付平台ID处理不同的流程
          final paymentId = selectedMethod['id'];
          if (paymentId == 2) {
            // MGate (支付宝) - 跳转支付宝支付页面
            if (kDebugMode) {
              print('MGate支付平台，跳转支付宝支付页面');
            }
          } else if (paymentId == 11) {
            // EPay - 跳转支付页面
            if (kDebugMode) {
              print('EPay支付平台，跳转支付页面');
            }
          }
          
          // 跳转支付平台
          try {
            onOpenInAppPayment(data);
          } catch (e) {
            if (kDebugMode) {
              print('跳转支付平台失败: $e');
            }
          }
          
          // 开始监听订单状态
          try {
            monitorOrderStatus();
          } catch (e) {
            if (kDebugMode) {
              print('订单状态监听失败: $e');
            }
          }
          return;
        }
      }

      // 处理其他未知情况
      if (kDebugMode) {
        print('支付处理失败: 意外的响应。');
      }
    } catch (e) {
      if (kDebugMode) {
        print('支付错误: $e');
      }
    }
  }

  void handlePaymentSuccess() {
    if (kDebugMode) {
      print('订单已标记为已支付。');
    }
    
    // 延迟调用回调，确保组件状态稳定
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        onPaymentSuccess();
      } catch (e) {
        if (kDebugMode) {
          print('支付成功回调失败: $e');
        }
      }
    });
  }

  Future<void> monitorOrderStatus() async {
    final accessToken = await getToken();
    if (accessToken == null) return;

    MonitorPayStatus().monitorOrderStatus(tradeNo, accessToken, (bool isPaid) {
      if (isPaid) {
        if (kDebugMode) {
          print('订单支付成功');
        }
        handlePaymentSuccess();
      } else {
        if (kDebugMode) {
          print('订单未支付');
        }
      }
    });
  }

  void openPaymentUrl(String paymentUrl) {
    // 改为在应用内显示支付页面，而不是跳转到外部浏览器
    onOpenInAppPayment(paymentUrl);
  }

  // 处理余额支付
  Future<void> handleBalancePayment() async {
    final accessToken = await getToken();
    try {
      if (kDebugMode) {
        print('开始处理余额支付');
      }

      // 调用 submitOrder，传递 method = 0 表示余额支付
      final response = await _purchaseService.submitOrder(
        tradeNo,
        '0', // method = 0 表示余额支付
        accessToken!,
      );

      if (kDebugMode) {
        print('余额支付响应: $response');
      }

      // 处理响应
      final type = response['type'];
      final data = response['data'];

      if (type == -1 && data == true) {
        // 余额支付成功
        if (kDebugMode) {
          print('余额支付成功，订单已完成');
        }
        handlePaymentSuccess();
      } else if (type == 1 && data is String) {
        // 余额不足，需要跳转支付平台补齐
        if (kDebugMode) {
          print('余额不足，需要跳转支付平台补齐剩余金额');
        }
        try {
          onOpenInAppPayment(data);
        } catch (e) {
          if (kDebugMode) {
            print('跳转支付平台失败: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('余额支付处理失败: 意外的响应');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('余额支付错误: $e');
      }
    }
  }
}

// purchase_details_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class PurchaseDetailsViewModel extends ChangeNotifier {
  final int planId;
  String? selectedPeriod;
  double? selectedPrice;
  String? tradeNo;

  final PurchaseService _purchaseService = PurchaseService();
  final OrderService _orderService = OrderService();

  PurchaseDetailsViewModel({
    required this.planId,
    this.selectedPeriod,
    this.selectedPrice,
  });

  void setSelectedPrice(double? price, String? period) {
    selectedPrice = price;
    selectedPeriod = period;
    notifyListeners();
  }

  // 新增：验证选择状态的方法
  bool get isSelectionValid => selectedPrice != null && selectedPeriod != null;

  // 新增：获取当前选择状态的方法
  String get selectionStatus {
    if (selectedPrice == null && selectedPeriod == null) {
      return '未选择任何选项';
    } else if (selectedPrice == null) {
      return '已选择时长但价格为空';
    } else if (selectedPeriod == null) {
      return '已选择价格但时长为空';
    } else {
      return '选择完整';
    }
  }

  Future<List<dynamic>> handleSubscribe() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      return [];
    }

    try {
      // 检查未支付的订单
      final List<Order> orders =
          await _orderService.fetchUserOrders(accessToken);
      for (final order in orders) {
        if (order.status == 0) {
          // 如果订单未支付
          await _orderService.cancelOrder(order.tradeNo!, accessToken);
        }
      }

      // 创建新订单
      final orderResponse = await _purchaseService.createOrder(
        planId,
        selectedPeriod!,
        accessToken,
      );

      if (orderResponse != null) {
        tradeNo = orderResponse['data']?.toString();
        if (kDebugMode) {
          print("[purchase] order created, tradeNo=$tradeNo");
        }
        final paymentMethods =
            await _purchaseService.getPaymentMethods(accessToken, tradeNo: tradeNo);
        return paymentMethods;
      } else {
        if (kDebugMode) {
          print('[purchase] order create failed: ${orderResponse?['message']}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('[purchase] error: $e');
      }
      return [];
    }
  }
}

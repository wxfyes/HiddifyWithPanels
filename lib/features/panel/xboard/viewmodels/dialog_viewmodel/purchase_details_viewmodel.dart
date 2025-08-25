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

  Future<List<dynamic>> handleSubscribe() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("[purchase] Access token is null");
      return [];
    }

    try {
      // 检查未支付的订单
      final List<Order> orders =
          await _orderService.fetchUserOrders(accessToken);
      print('[purchase] fetched orders: count=${orders.length}');
      for (final order in orders) {
        print('[purchase] order: tradeNo=${order.tradeNo} status=${order.status}');
        if (order.status == 0) {
          // 如果订单未支付
          await _orderService.cancelOrder(order.tradeNo!, accessToken);
          print('[purchase] cancelled unpaid order ${order.tradeNo}');
        }
      }
      print("[purchase] creating order with planId=$planId period=$selectedPeriod price=$selectedPrice");
      // 创建新订单
      final orderResponse = await _purchaseService.createOrder(
        planId,
        selectedPeriod!,
        accessToken,
      );
      print("[purchase] order save response: $orderResponse");
      if (orderResponse != null) {
        tradeNo = orderResponse['data']?.toString();
        if (kDebugMode) {
          print("[purchase] order created, tradeNo=$tradeNo");
        }
        final paymentMethods =
            await _purchaseService.getPaymentMethods(accessToken, tradeNo: tradeNo);
        print('[purchase] payment methods result length=${paymentMethods.length}');
        return paymentMethods;
      } else {
        if (kDebugMode) {
          print('[purchase] order create failed: ${orderResponse?['message']}');
        }
        return [];
      }
    } catch (e) {
      print('[purchase] error: $e');
      return [];
    }
  }
}

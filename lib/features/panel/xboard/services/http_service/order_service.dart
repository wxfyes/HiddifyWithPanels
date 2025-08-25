// services/order_service.dart
import 'package:hiddify/features/panel/xboard/models/order_model.dart';

import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class OrderService {
  final HttpService _httpService = HttpService();

  Future<List<Order>> fetchUserOrders(String accessToken) async {
    Map<String, String> header = {'Authorization': accessToken};
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/order/fetch",
        headers: header,
      );
      if (result["status"] == "success") {
        final ordersJson = result["data"] as List;
        return ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // 兼容 Bearer 前缀
    final result = await _httpService.getRequest(
      "/api/v1/user/order/fetch",
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (result["status"] == "success") {
      final ordersJson = result["data"] as List;
      return ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to fetch user orders: ${result['message']}");
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(
      String tradeNo, String accessToken) async {
    try {
      return await _httpService.getRequest(
        "/api/v1/user/order/detail?trade_no=$tradeNo",
        headers: {'Authorization': accessToken},
      );
    } catch (_) {
      return await _httpService.getRequest(
        "/api/v1/user/order/detail?trade_no=$tradeNo",
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
  }

  Future<Map<String, dynamic>> cancelOrder(
      String tradeNo, String accessToken) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/user/order/cancel",
        {"trade_no": tradeNo},
        headers: {'Authorization': accessToken},
      );
    } catch (_) {
      return await _httpService.postRequest(
        "/api/v1/user/order/cancel",
        {"trade_no": tradeNo},
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
  }

  Future<Map<String, dynamic>> createOrder(
      String accessToken, int planId, String period) async {
    try {
      return await _httpService.postRequest(
        "/api/v1/user/order/save",
        {"plan_id": planId, "period": period},
        headers: {'Authorization': accessToken},
      );
    } catch (_) {
      return await _httpService.postRequest(
        "/api/v1/user/order/save",
        {"plan_id": planId, "period": period},
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
  }
}

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
    // 将前端的 period 值映射为后端期望的值
    String mappedPeriod = _mapPeriodToBackend(period);
    
    // 添加调试日志
    print('[OrderService] Original period: $period, Mapped period: $mappedPeriod');
    
    try {
      return await _httpService.postRequest(
        "/api/v1/user/order/save",
        {
          "plan_id": planId, 
          "period": mappedPeriod,
          "auth_data": accessToken, // 添加 auth_data 参数
        },
        headers: {'Authorization': accessToken}, // 保留原有的 Authorization 头部
        sendAsJson: true, // 使用 JSON 格式，Laravel 通常能更好地处理
      );
    } catch (_) {
      return await _httpService.postRequest(
        "/api/v1/user/order/save",
        {
          "plan_id": planId, 
          "period": mappedPeriod,
          "auth_data": accessToken, // 添加 auth_data 参数
        },
        headers: {'Authorization': 'Bearer $accessToken'},
        sendAsJson: true, // 使用 JSON 格式，Laravel 通常能更好地处理
      );
    }
  }

  // 映射 period 值的方法 - 后端期望的是带 _price 后缀的值
  String _mapPeriodToBackend(String period) {
    // 后端期望的 period 值：month_price, quarter_price, half_year_price, year_price, two_year_price, three_year_price, onetime_price, reset_price, deposit
    // 所以不需要映射，直接返回原值
    return period;
  }
}

// services/payment_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken,) async {
    return await _httpService.postRequest(
      "/api/v1/user/order/checkout",
      {"trade_no": tradeNo, "method": method, "auth_data": accessToken},
      headers: {
        'Referer': 'https://123.108.70.221:8443',
        'User-Agent': 'HiddifyWithPanels/2.5.7',
      },
    );
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken, {String? tradeNo}) async {
    // 先按 EZ-Theme 逻辑：不带 trade_no 直接获取一次
    for (final path in [
      "/api/v1/user/order/getPaymentMethod",
      "/api/v1/user/payment/getPaymentMethod",
    ]) {
      for (final header in [
        {'Authorization': accessToken},
        {'Authorization': 'Bearer $accessToken'},
      ]) {
        try {
          print('[payment] try no-trade payment methods: $path header=${header.keys.first}');
          final response = await _httpService.getRequest(path, headers: header);
          print('[payment] response from $path: $response');
          if (response['data'] is List && (response['data'] as List).isNotEmpty) {
            return (response['data'] as List).cast<dynamic>();
          }
        } catch (_) {
          // ignore and continue
        }
      }
    }

    // 再尝试多条可能需要 trade_no 的兼容 API 路径
    final possiblePaths = [
      "/api/v1/user/order/getPaymentMethod",
      "/api/v1/user/order/getPaymentMethods",
      "/api/v1/user/payment/getPaymentMethod",
      "/api/v1/user/payment/getPaymentMethods",
      "/api/v1/user/order/paymentMethods",
      "/api/v1/user/payment/methods",
      "/api/v1/user/order/payment_methods",
      "/api/v1/user/payment_methods",
      "/api/v1/payment/methods",
      "/api/v1/user/order/methods",
    ];

    for (final path in possiblePaths) {
      for (final header in [
        {'Authorization': accessToken},
        {'Authorization': 'Bearer $accessToken'},
      ]) {
        try {
          final fullPath = tradeNo != null ? "$path?trade_no=$tradeNo" : path;
          print("[payment] trying methods: $fullPath header=${header.keys.first}");
          final response = await _httpService.getRequest(fullPath, headers: header);
          print("[payment] response from $fullPath: $response");
          
          // 检查不同的响应格式
          if (response['data'] != null) {
            final data = response['data'];
            if (data is List) {
              print("Found payment methods list with ${data.length} items");
              return data.cast<dynamic>();
            } else if (data is Map) {
              // 如果data是Map，可能包含payment_methods字段
              if (data['payment_methods'] is List) {
                print("Found payment_methods in data map");
                return (data['payment_methods'] as List).cast<dynamic>();
              }
            }
          }
          
          // 检查是否有直接的payment_methods字段
          if (response['payment_methods'] is List) {
            print("Found payment_methods in root response");
            return (response['payment_methods'] as List).cast<dynamic>();
          }
          
          // 检查是否有methods字段
          if (response['methods'] is List) {
            print("Found methods in root response");
            return (response['methods'] as List).cast<dynamic>();
          }
          
          print("No valid payment methods data found in response from $path");
        } catch (e) {
          print("Error getting payment methods from $path: $e");
          continue;
        }
      }
    }
    
    print("All payment methods API paths failed");
    return [];
  }
}

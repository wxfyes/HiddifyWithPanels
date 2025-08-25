// services/payment_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken,) async {
    return await _httpService.postRequest(
      "/api/v1/user/order/checkout",
      {"trade_no": tradeNo, "method": method},
      headers: {'Authorization': accessToken},
    );
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    // 尝试多个可能的API路径
    final possiblePaths = [
      "/api/v1/user/order/getPaymentMethod",
      "/api/v1/user/order/getPaymentMethods",
      "/api/v1/user/payment/getPaymentMethod",
      "/api/v1/user/payment/getPaymentMethods",
    ];

    for (final path in possiblePaths) {
      try {
        print("Trying payment methods API: $path");
        final response = await _httpService.getRequest(
          path,
          headers: {'Authorization': accessToken},
        );
        print("Payment methods response from $path: $response");
        if (response['data'] != null) {
          return (response['data'] as List).cast<dynamic>();
        } else {
          print("No data field in payment methods response from $path");
        }
      } catch (e) {
        print("Error getting payment methods from $path: $e");
        continue;
      }
    }
    
    print("All payment methods API paths failed");
    return [];
  }
}

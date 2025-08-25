// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法
  Future<String?> getSubscriptionLink(String accessToken) async {
    Map<String, dynamic> result;
    try {
      result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': accessToken,
        },
      );
    } catch (_) {
      result = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    }

    // 兼容多种返回格式
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is Map<String, dynamic>) {
        if (data.containsKey("subscribe_url")) {
          return data["subscribe_url"] as String?;
        }
        if (data.containsKey("url")) {
          return data["url"] as String?;
        }
      } else if (data is String) {
        return data;
      }
    }
    if (result.containsKey("subscribe_url")) {
      return result["subscribe_url"] as String?;
    }

    // 返回 null 或抛出异常，如果数据结构不匹配
    throw Exception("Failed to retrieve subscription link");
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    try {
      await _httpService.getRequest(
        "/api/v1/user/resetSecurity",
        headers: {
          'Authorization': accessToken,
        },
      );
    } catch (_) {
      await _httpService.getRequest(
        "/api/v1/user/resetSecurity",
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
    }
    // 大多数后端 reset 不直接返回链接，重置后再取一次订阅链接
    return await getSubscriptionLink(accessToken);
  }
}

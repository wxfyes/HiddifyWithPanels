// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static const String ossDomain =
      'https://tianque.126581.xyz/config.json';
  
  static const String v2boardDomain = 'https://your-v2board-panel.com';

  static List<String> paymentHosts = <String>[];
  static String cashierPath = "/#/payment?trade_no=";
  static bool allowSelfSigned = false;

  static Future<String> fetchValidDomain() async {
    print('DomainService.fetchValidDomain() called');
    print('Fetching config from: $ossDomain');
    
    try {
      final response = await http
          .get(Uri.parse(ossDomain))
          .timeout(const Duration(seconds: 10));
      
      print('Config response status: ${response.statusCode}');
      print('Config response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body) as List<dynamic>;
        print('Config items count: ${items.length}');
        
        String? firstUrl;
        for (final dynamic it in items) {
          if (it is Map<String, dynamic>) {
            // 支付配置块
            if (it.containsKey('payment_hosts') ||
                it.containsKey('cashier_path') ||
                it.containsKey('allow_self_signed')) {
              try {
                final List<dynamic>? hosts = it['payment_hosts'] as List<dynamic>?;
                if (hosts != null) {
                  paymentHosts = hosts.map((e) => e.toString()).toList();
                }
                final String? path = it['cashier_path'] as String?;
                if (path != null && path.isNotEmpty) cashierPath = path;
                final dynamic allow = it['allow_self_signed'];
                if (allow is bool) allowSelfSigned = allow;
              } catch (_) {}
              continue;
            }
            // url 列表
            final String? domain = it['url'] as String?;
            if (domain != null && domain.isNotEmpty) {
              firstUrl ??= domain;
              // 直接返回第一个域名，跳过检测（因为反代服务器可能响应慢）
              print('Using domain from config: $domain');
              return domain;
            }
          }
        }
        // 如果没有任何域名，且有 firstUrl，返回它
        if (firstUrl != null) {
          print('Using firstUrl as fallback: $firstUrl');
          return firstUrl!;
        }
      }

      // 如果远程配置失败，使用默认域名
      print('Using fallback domain: $v2boardDomain');
      return v2boardDomain;
    } catch (e) {
      print('Error fetching valid domain: $ossDomain:  $e');
      // 出错时返回默认域名，而不是抛出异常
      print('Using fallback domain due to error: $v2boardDomain');
      return v2boardDomain;
    }
  }

  static Future<bool> _checkDomainAccessibility(String domain) async {
    try {
      final response = await http
          .get(Uri.parse('$domain/api/v1/guest/comm/config'))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

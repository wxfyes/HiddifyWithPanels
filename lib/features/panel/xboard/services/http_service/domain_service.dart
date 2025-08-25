// services/domain_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DomainService {
  static const String ossDomain =
      'https://tianque.126581.xyz/config.json';
  
  // 添加您的 v2board 面板域名作为备选
  static const String v2boardDomain = 'https://your-v2board-panel.com';

  // 支付/收银台相关远程配置（自动化）
  static List<String> paymentHosts = <String>[]; // host:port 列表
  static String cashierPath = "/#/payment?from=orders"; // 默认主题
  static bool allowSelfSigned = false; // 是否放行自签

// 从返回的 JSON 中挑选一个可以正常访问的域名，同时解析支付配置
  static Future<String> fetchValidDomain() async {
    try {
      // 首先尝试从OSS获取域名列表
      final response = await http
          .get(Uri.parse(ossDomain))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> items =
            json.decode(response.body) as List<dynamic>;
        for (final dynamic it in items) {
          if (it is Map<String, dynamic>) {
            // 解析支付配置块
            if (it.containsKey('payment_hosts') ||
                it.containsKey('cashier_path') ||
                it.containsKey('allow_self_signed')) {
              try {
                final List<dynamic>? hosts = it['payment_hosts'] as List<dynamic>?;
                if (hosts != null) {
                  paymentHosts = hosts.map((e) => e.toString()).toList();
                }
                final String? path = it['cashier_path'] as String?;
                if (path != null && path.isNotEmpty) {
                  cashierPath = path;
                }
                final dynamic allow = it['allow_self_signed'];
                if (allow is bool) allowSelfSigned = allow;
              } catch (_) {}
              continue;
            }
            // 解析可用 url
            final String? domain = it['url'] as String?;
            if (domain != null) {
              if (await _checkDomainAccessibility(domain)) {
                if (kDebugMode) {
                  print('Valid domain found: $domain');
                }
                return domain;
              }
            }
          }
        }
      }
      
      // 如果OSS域名都不可用，尝试使用v2board域名
      if (await _checkDomainAccessibility(v2boardDomain)) {
        if (kDebugMode) {
          print('Using v2board domain: $v2boardDomain');
        }
        return v2boardDomain;
      }
      
      throw Exception('No accessible domains found.');
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching valid domain: $ossDomain:  $e');
      }
      rethrow;
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

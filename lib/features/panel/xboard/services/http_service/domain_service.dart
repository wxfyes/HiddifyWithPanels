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
    try {
      final response = await http
          .get(Uri.parse(ossDomain))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> items = json.decode(response.body) as List<dynamic>;
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
              // 自签/被墙时跳过探活，直接使用
              if (allowSelfSigned) {
                if (kDebugMode) print('Using (allow_self_signed) domain: $domain');
                return domain;
              }
              if (await _checkDomainAccessibility(domain)) {
                if (kDebugMode) print('Valid domain found: $domain');
                return domain;
              }
            }
          }
        }
        // 如果没有任何可探活成功的，且有 firstUrl，返回它（配合自签场景）
        if (firstUrl != null) return firstUrl!;
      }

      if (await _checkDomainAccessibility(v2boardDomain)) {
        if (kDebugMode) print('Using v2board domain: $v2boardDomain');
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

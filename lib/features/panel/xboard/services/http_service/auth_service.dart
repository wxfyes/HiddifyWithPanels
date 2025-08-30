// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/login",
      {"email": email, "password": password},
      requiresHeaders: true,
      sendAsJson: false, // 登录保持 x-www-form-urlencoded
    );
  }

  Future<Map<String, dynamic>> register(String email, String password,
      String inviteCode, String emailCode) async {
    final Map<String, dynamic> body = {
      "email": email,
      "password": password,
      "email_code": emailCode,
    };
    if (inviteCode.trim().isNotEmpty) {
      body["invite_code"] = inviteCode.trim();
    }

    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      body,
      requiresHeaders: true,
      sendAsJson: false,
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    // 尝试多个可能的接口路径
    try {
      // 方案1：尝试可能的正确路径
      final response = await _httpService.postRequest(
        "/api/v1/passport/auth/sendEmailVerify",
        {"email": email, "scene": "register"},
        requiresHeaders: true,
        sendAsJson: false,
      );
      return response;
    } catch (e) {
      print('接口 /api/v1/passport/auth/sendEmailVerify 不可用: $e');
      
      try {
        // 方案2：尝试另一个可能的路径
        final response2 = await _httpService.postRequest(
          "/api/v1/guest/auth/sendEmailVerify",
          {"email": email, "scene": "register"},
          requiresHeaders: true,
          sendAsJson: false,
        );
        return response2;
      } catch (e2) {
        print('接口 /api/v1/guest/auth/sendEmailVerify 也不可用: $e2');
        
        // 如果都不可用，返回错误信息
        return {
          'status': 'error',
          'message': '邮箱验证服务暂时不可用，请进官网注册'
        };
      }
    }
  }

  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
      requiresHeaders: true,
      sendAsJson: true,
    );
  }
}

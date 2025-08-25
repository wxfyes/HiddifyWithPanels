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
      "code": emailCode, // 兼容后端将邮箱验证码字段命名为 code 的情况
    };
    if (inviteCode.trim().isNotEmpty) {
      body["invite_code"] = inviteCode.trim();
    }

    // 优先尝试 JSON，失败后退回 x-www-form-urlencoded
    try {
      return await _httpService.postRequest(
        "/api/v1/passport/auth/register",
        body,
        requiresHeaders: true,
        sendAsJson: true,
      );
    } catch (_) {
      return await _httpService.postRequest(
        "/api/v1/passport/auth/register",
        body,
        requiresHeaders: true,
        sendAsJson: false,
      );
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    // 兼容 xiao-v2board：多数后端接受表单 & guest 前缀
    try {
      return await _httpService.postRequest(
        "/api/v1/guest/comm/sendEmailVerify",
        {"email": email, "scene": "register"},
        requiresHeaders: true,
        sendAsJson: false,
      );
    } catch (_) {
      return await _httpService.postRequest(
        "/api/v1/passport/comm/sendEmailVerify",
        {"email": email, "scene": "register"},
        requiresHeaders: true,
        sendAsJson: false,
      );
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

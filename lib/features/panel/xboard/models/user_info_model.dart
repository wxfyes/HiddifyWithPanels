class UserInfo {
  final String email;
  final double transferEnable;
  final int? lastLoginAt; // 允许为 null
  final int createdAt;
  final bool banned; // 账户状态, true: 被封禁, false: 正常
  final bool remindExpire;
  final bool remindTraffic;
  final int? expiredAt; // 允许为 null
  final double balance; // 消费余额
  final double commissionBalance; // 剩余佣金余额
  final int planId;
  final double? discount; // 允许为 null
  final double? commissionRate; // 允许为 null
  final String? telegramId; // 允许为 null
  final String uuid;
  final String avatarUrl;

  UserInfo({
    required this.email,
    required this.transferEnable,
    this.lastLoginAt,
    required this.createdAt,
    required this.banned,
    required this.remindExpire,
    required this.remindTraffic,
    this.expiredAt,
    required this.balance,
    required this.commissionBalance,
    required this.planId,
    this.discount,
    this.commissionRate,
    this.telegramId,
    required this.uuid,
    required this.avatarUrl,
  });

  // 从 JSON 创建 UserInfo 实例
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    try {
      return UserInfo(
        // 字符串字段，如果为 null，返回空字符串
        email: _safeString(json['email']),

        // 转换为 double，如果为 null，返回 0.0
        transferEnable: _safeDouble(json['transfer_enable']),

        // 时间字段可以为 null
        lastLoginAt: _safeInt(json['last_login_at']),

        // 确保 createdAt 为 int，并提供默认值
        createdAt: _safeInt(json['created_at']) ?? 0,

        // 处理布尔值
        banned: _safeBool(json['banned']),
        remindExpire: _safeBool(json['remind_expire']),
        remindTraffic: _safeBool(json['remind_traffic']),

        // 允许 expiredAt 为 null
        expiredAt: _safeInt(json['expired_at']),

        // 转换 balance 为 double，并处理 null
        balance: _safeDouble(json['balance']),

        // 转换 commissionBalance 为 double，并处理 null
        commissionBalance: _safeDouble(json['commission_balance']),

        // 保证 planId 是 int，提供默认值 0
        planId: _safeInt(json['plan_id']) ?? 0,

        // 允许 discount 和 commissionRate 为 null
        discount: _safeDouble(json['discount']),
        commissionRate: _safeDouble(json['commission_rate']),

        // 修复 telegramId 类型转换问题 - 可能是 int 或 String
        telegramId: _parseTelegramId(json['telegram_id']),

        // uuid 和 avatarUrl，如果为 null 返回空字符串
        uuid: _safeString(json['uuid']),
        avatarUrl: _safeString(json['avatar_url']),
      );
    } catch (e) {
      print('Error parsing UserInfo from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // 辅助方法：解析 telegram_id，可能是 int 或 String
  static String? _parseTelegramId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  // 安全的字符串转换
  static String _safeString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  // 安全的整数转换
  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  // 安全的双精度浮点数转换
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // 安全的布尔值转换
  static bool _safeBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}

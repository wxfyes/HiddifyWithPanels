import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/core/model/environment.dart';

part 'remote_version_entity.freezed.dart';

@Freezed()
class RemoteVersionEntity with _$RemoteVersionEntity {
  const RemoteVersionEntity._();

  const factory RemoteVersionEntity({
    required String version,
    required String buildNumber,
    required String releaseTag,
    required bool preRelease,
    required String url,
    required DateTime publishedAt,
    required Environment flavor,
    // 新增字段：GitHub Release支持
    String? releaseNotes,
    String? downloadUrl,
    @Default({}) Map<String, String> platformSpecificUrls,
  }) = _RemoteVersionEntity;

  String get presentVersion =>
      flavor == Environment.prod ? version : "$version ${flavor.name}";

  /// 获取特定平台的下载链接
  String? getPlatformDownloadUrl(String platform) {
    return platformSpecificUrls[platform.toLowerCase()];
  }

  /// 获取当前平台的最佳下载链接
  String get bestDownloadUrl {
    // 优先使用平台特定链接，如果没有则使用通用链接
    final currentPlatform = _getCurrentPlatform();
    return platformSpecificUrls[currentPlatform] ?? downloadUrl ?? url;
  }

  String _getCurrentPlatform() {
    // 这里可以根据实际需要扩展平台检测逻辑
    if (identical(0, 0.0)) {
      // Web
      return 'web';
    } else {
      // 移动端和桌面端
      return 'desktop';
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'unified_update_repository.g.dart';

@riverpod
class UnifiedUpdateRepository extends _$UnifiedUpdateRepository {
  @override
  Future<RemoteVersionEntity> build() async {
    return _getLatestVersionFromGitHub();
  }

  Future<RemoteVersionEntity> _getLatestVersionFromGitHub() async {
    try {
      // 使用GitHub API获取最新Release
      final response = await _fetchGitHubRelease();
      
      if (response != null) {
        return _parseGitHubRelease(response);
      }

      throw AppUpdateFailure.unexpected(
        Exception('Failed to fetch latest version from GitHub'),
        StackTrace.current,
      );
    } catch (e, stackTrace) {
      throw AppUpdateFailure.unexpected(e, stackTrace);
    }
  }

  Future<Map<String, dynamic>?> _fetchGitHubRelease() async {
    try {
      final response = await http.get(
        Uri.parse(Constants.githubReleasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'HiddifyWithPanels-Update-Checker',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        return releases.isNotEmpty ? releases.first : null;
      }
    } catch (e) {
      print('Error fetching GitHub release: $e');
    }
    return null;
  }

  RemoteVersionEntity _parseGitHubRelease(Map<String, dynamic> release) {
    final tagName = release['tag_name'] as String;
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final publishedAt = DateTime.parse(release['published_at'] as String);
    
    // 解析平台特定的下载链接
    final assets = release['assets'] as List<dynamic>? ?? [];
    final platformUrls = <String, String>{};
    
    for (final asset in assets) {
      final name = asset['name'] as String;
      final downloadUrl = asset['browser_download_url'] as String;
      
      // 根据文件名判断平台
      if (name.contains('Android') || name.contains('.apk') || name.contains('.aab')) {
        platformUrls['android'] = downloadUrl;
      } else if (name.contains('Windows') || name.contains('.exe') || name.contains('.msix')) {
        platformUrls['windows'] = downloadUrl;
      } else if (name.contains('MacOS') || name.contains('.dmg') || name.contains('.pkg')) {
        platformUrls['macos'] = downloadUrl;
      } else if (name.contains('Linux') || name.contains('.AppImage') || name.contains('.deb') || name.contains('.rpm')) {
        platformUrls['linux'] = downloadUrl;
      } else if (name.contains('iOS') || name.contains('.ipa')) {
        platformUrls['ios'] = downloadUrl;
      }
    }

    return RemoteVersionEntity(
      version: version,
      buildNumber: version, // 使用版本号作为构建号
      releaseTag: tagName,
      preRelease: release['prerelease'] as bool? ?? false,
      url: Constants.githubLatestReleaseUrl,
      publishedAt: publishedAt,
      flavor: Environment.prod, // 默认使用生产环境
      releaseNotes: release['body'] as String? ?? '',
      downloadUrl: Constants.githubLatestReleaseUrl,
      platformSpecificUrls: platformUrls,
    );
  }

  /// 获取特定平台的下载链接
  Future<String?> getPlatformDownloadUrl(String platform) async {
    final latestVersion = await _getLatestVersionFromGitHub();
    return latestVersion.platformSpecificUrls[platform.toLowerCase()];
  }

  /// 获取所有平台的下载链接
  Future<Map<String, String>> getAllPlatformDownloadUrls() async {
    final latestVersion = await _getLatestVersionFromGitHub();
    return latestVersion.platformSpecificUrls;
  }

  /// 检查是否有新版本
  Future<bool> hasUpdate(String currentVersion) async {
    try {
      final latestVersion = await _getLatestVersionFromGitHub();
      return _compareVersions(currentVersion, latestVersion.version) < 0;
    } catch (e) {
      return false;
    }
  }

  /// 比较版本号
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    for (int i = 0; i < maxLength; i++) {
      final v1 = i < v1Parts.length ? v1Parts[i] : 0;
      final v2 = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1 < v2) return -1;
      if (v1 > v2) return 1;
    }
    
    return 0;
  }
}

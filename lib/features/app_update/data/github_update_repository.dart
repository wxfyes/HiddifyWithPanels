import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/app_update/model/remote_version_entity.dart';
import 'package:hiddify/features/app_update/model/app_update_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_update_repository.g.dart';

@riverpod
class GitHubUpdateRepository extends _$GitHubUpdateRepository {
  @override
  Future<RemoteVersionEntity> build() async {
    return _getLatestVersion();
  }

  Future<RemoteVersionEntity> _getLatestVersion() async {
    try {
      // 获取最新Release信息
      final response = await http.get(
        Uri.parse(Constants.githubReleasesApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'HiddifyWithPanels-Update-Checker',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> releases = json.decode(response.body);
        
        if (releases.isNotEmpty) {
          final latestRelease = releases.first;
          final tagName = latestRelease['tag_name'] as String;
          final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
          
          // 获取下载链接
          final assets = latestRelease['assets'] as List<dynamic>? ?? [];
          final downloadUrls = <String, String>{};
          
          for (final asset in assets) {
            final name = asset['name'] as String;
            final downloadUrl = asset['browser_download_url'] as String;
            
            // 根据文件名判断平台
            if (name.contains('Android') || name.contains('.apk') || name.contains('.aab')) {
              downloadUrls['android'] = downloadUrl;
            } else if (name.contains('Windows') || name.contains('.exe') || name.contains('.msix')) {
              downloadUrls['windows'] = downloadUrl;
            } else if (name.contains('MacOS') || name.contains('.dmg') || name.contains('.pkg')) {
              downloadUrls['macos'] = downloadUrl;
            } else if (name.contains('Linux') || name.contains('.AppImage') || name.contains('.deb') || name.contains('.rpm')) {
              downloadUrls['linux'] = downloadUrl;
            } else if (name.contains('iOS') || name.contains('.ipa')) {
              downloadUrls['ios'] = downloadUrl;
            }
          }

          return RemoteVersionEntity(
            version: version,
            releaseNotes: latestRelease['body'] as String? ?? '',
            downloadUrl: Constants.githubLatestReleaseUrl,
            platformSpecificUrls: downloadUrls,
            publishedAt: DateTime.parse(latestRelease['published_at'] as String),
          );
        }
      }

      throw AppUpdateFailure.unexpected(
        Exception('Failed to fetch latest version: ${response.statusCode}'),
        StackTrace.current,
      );
    } catch (e, stackTrace) {
      throw AppUpdateFailure.unexpected(e, stackTrace);
    }
  }

  /// 获取特定平台的下载链接
  Future<String?> getPlatformDownloadUrl(String platform) async {
    final latestVersion = await _getLatestVersion();
    return latestVersion.platformSpecificUrls[platform.toLowerCase()];
  }

  /// 获取所有平台的下载链接
  Future<Map<String, String>> getAllPlatformDownloadUrls() async {
    final latestVersion = await _getLatestVersion();
    return latestVersion.platformSpecificUrls;
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kitchenowl/config.dart';

class AppUpdateInfo {
  final String version;
  final int buildNumber;
  final String releaseUrl;
  final String? apkUrl;

  const AppUpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseUrl,
    this.apkUrl,
  });
}

class AppUpdateService {
  static final Uri _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/t0n003c/kitchenowl/releases/latest',
  );

  static Future<AppUpdateInfo?> checkForUpdate() async {
    final currentPackage = await Config.packageInfo;
    if (currentPackage == null) return null;

    try {
      final response = await http.get(
        _latestReleaseUri,
        headers: const {
          'Accept': 'application/vnd.github+json',
        },
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final release = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = release['tag_name'] as String? ?? '';
      final match = RegExp(r'^android-v(.+)-(\d+)$').firstMatch(tagName);
      if (match == null) return null;

      final version = match.group(1)!;
      final buildNumber = int.tryParse(match.group(2)!) ?? 0;
      final currentBuildNumber = int.tryParse(currentPackage.buildNumber) ?? 0;
      if (buildNumber <= currentBuildNumber &&
          _compareVersions(version, currentPackage.version) <= 0) {
        return null;
      }

      final assets = (release['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>();
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }

      return AppUpdateInfo(
        version: version,
        buildNumber: buildNumber,
        releaseUrl: release['html_url'] as String? ??
            'https://github.com/t0n003c/kitchenowl/releases',
        apkUrl: apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map((part) => int.tryParse(part) ?? 0);
    final rightParts = right.split('.').map((part) => int.tryParse(part) ?? 0);
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    final leftValues = leftParts.toList();
    final rightValues = rightParts.toList();

    for (var i = 0; i < maxLength; i++) {
      final comparison = (i < leftValues.length ? leftValues[i] : 0)
          .compareTo(i < rightValues.length ? rightValues[i] : 0);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

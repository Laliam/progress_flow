import 'package:package_info_plus/package_info_plus.dart';

/// Holds the cached app version info loaded at startup.
class AppVersion {
  static PackageInfo? _info;

  static Future<void> init() async {
    _info = await PackageInfo.fromPlatform();
    // ignore: avoid_print
    print('🚀 ProgressFlow $versionString launched');
  }

  static String get versionString {
    if (_info == null) return '';
    return 'v${_info!.version}+${_info!.buildNumber}';
  }

  static String get appName => _info?.appName ?? 'ProgressFlow';
}

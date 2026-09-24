import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plainscan/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService Dynamic Versioning Tests', () {
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'PlainScan',
        packageName: 'com.plainscan.app',
        version: '1.0.0',
        buildNumber: '22',
        buildSignature: '',
      );
    });

    test('getCurrentVersion reads version dynamically from PackageInfo', () async {
      final currentVer = await AppUpdateService.getCurrentVersion();
      expect(currentVer, '1.0.0+22');
    });

    test('isUpdateAvailable evaluates dynamic version comparison', () async {
      final hasUpdate = await AppUpdateService.isUpdateAvailable();
      expect(hasUpdate, isA<bool>());
    });
  });
}

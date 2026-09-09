import 'package:flutter_test/flutter_test.dart';
import 'package:plainscan/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService Tests', () {
    test('isUpdateAvailable detects newer version correctly', () async {
      final hasUpdate = await AppUpdateService.isUpdateAvailable();
      expect(hasUpdate, isTrue); // 1.1.0 > 1.0.0
    });

    test('Version constants are valid', () {
      expect(AppUpdateService.currentVersion, '1.0.0');
      expect(AppUpdateService.latestVersion, '1.1.0');
      expect(AppUpdateService.currentBuildNumber, 3);
    });
  });
}

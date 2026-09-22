import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  test('Notifications are strictly isolated per user across login and logout cycles', () async {
    final notifService = Get.put(NotificationService());

    // 1. Initial guest state (starts empty)
    await notifService.loadNotifications();
    expect(notifService.notifications.length, 0);

    // 2. User A logs in
    await StorageService.saveUser(
      email: 'alice@example.com',
      name: 'Alice',
      userId: 'user_alice_123',
    );
    await notifService.reloadForCurrentUser();

    // Alice generates user-specific notifications
    await notifService.addNotification(
      title: 'Alice Contract Signed',
      message: 'PDF Sign successfully placed signature on contract.pdf',
      type: NotificationType.toolExecution,
      showToast: false,
    );
    await notifService.addNotification(
      title: 'Alice Invoice OCR Completed',
      message: 'Scan OCR extracted text from invoice_march.pdf',
      type: NotificationType.toolUpdate,
      showToast: false,
    );

    expect(notifService.notifications.any((n) => n.title == 'Alice Contract Signed'), isTrue);
    expect(notifService.notifications.any((n) => n.title == 'Alice Invoice OCR Completed'), isTrue);
    expect(notifService.notifications.length, 2); // 2 custom

    // 3. User A logs out
    await StorageService.logout();
    await notifService.onLogout();

    // Guest should NOT see Alice's notifications
    expect(notifService.notifications.any((n) => n.title == 'Alice Contract Signed'), isFalse);
    expect(notifService.notifications.any((n) => n.title == 'Alice Invoice OCR Completed'), isFalse);

    // 4. User B logs in (Newly logged in user)
    await StorageService.saveUser(
      email: 'bob@example.com',
      name: 'Bob',
      userId: 'user_bob_456',
    );
    await notifService.reloadForCurrentUser();

    // Bob should NOT see Alice's notifications
    expect(notifService.notifications.any((n) => n.title == 'Alice Contract Signed'), isFalse);
    expect(notifService.notifications.any((n) => n.title == 'Alice Invoice OCR Completed'), isFalse);

    // Bob creates their own notification
    await notifService.addNotification(
      title: 'Bob Presentation Converted',
      message: 'PPTX to PDF converted 24 slides successfully',
      type: NotificationType.toolExecution,
      showToast: false,
    );

    expect(notifService.notifications.any((n) => n.title == 'Bob Presentation Converted'), isTrue);

    // 5. User B logs out
    await StorageService.logout();
    await notifService.onLogout();

    expect(notifService.notifications.any((n) => n.title == 'Bob Presentation Converted'), isFalse);

    // 6. User A logs back in
    await StorageService.saveUser(
      email: 'alice@example.com',
      name: 'Alice',
      userId: 'user_alice_123',
    );
    await notifService.reloadForCurrentUser();

    // Alice should see her own notifications again, but NOT Bob's
    expect(notifService.notifications.any((n) => n.title == 'Alice Contract Signed'), isTrue);
    expect(notifService.notifications.any((n) => n.title == 'Alice Invoice OCR Completed'), isTrue);
    expect(notifService.notifications.any((n) => n.title == 'Bob Presentation Converted'), isFalse);
  });

  test('StorageService.getUserNotificationsKey generates distinct keys for different users', () async {
    final prefs = await SharedPreferences.getInstance();

    // Default / guest key
    expect(StorageService.getUserNotificationsKey(prefs), 'plainscan_notifications');

    // Key with email only
    await prefs.setString('user_email', 'user1@test.com');
    expect(StorageService.getUserNotificationsKey(prefs), 'user_notifications_user1@test.com');

    // Key with userId (priority)
    await prefs.setString('user_id', 'usr_999');
    expect(StorageService.getUserNotificationsKey(prefs), 'user_notifications_usr_999');

    // Different user ID
    await prefs.setString('user_id', 'usr_888');
    expect(StorageService.getUserNotificationsKey(prefs), 'user_notifications_usr_888');
  });
}

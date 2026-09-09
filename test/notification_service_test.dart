import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    service = Get.put(NotificationService());
  });

  tearDown(() {
    Get.reset();
  });

  group('NotificationService Tests', () {
    test('Initializes with default welcome notification', () async {
      await service.loadNotifications();
      expect(service.notifications.isNotEmpty, isTrue);
      expect(service.notifications.first.title, contains('PlainScan'));
    });

    test('addNotification inserts at the beginning and updates unread count', () async {
      await service.clearAll();
      expect(service.unreadCount, 0);

      await service.addNotification(
        title: 'Compress PDF Completed',
        message: 'Tax_Return_2026.pdf compressed by 50%',
        type: NotificationType.toolUpdate,
        toolName: 'Compress PDF',
        fileName: 'Tax_Return_2026_compressed.pdf',
        showToast: false,
      );

      expect(service.notifications.length, 1);
      expect(service.notifications.first.title, 'Compress PDF Completed');
      expect(service.notifications.first.isRead, isFalse);
      expect(service.unreadCount, 1);
    });

    test('markAsRead updates specific notification', () async {
      await service.clearAll();
      await service.addNotification(
        title: 'Rotate PDF',
        message: 'Rotated 90 degrees',
        type: NotificationType.toolExecution,
        showToast: false,
      );

      final id = service.notifications.first.id;
      expect(service.unreadCount, 1);

      await service.markAsRead(id);
      expect(service.unreadCount, 0);
      expect(service.notifications.first.isRead, isTrue);
    });

    test('markAllAsRead sets all notifications as read', () async {
      await service.clearAll();
      await service.addNotification(
        title: 'Tool 1',
        message: 'Message 1',
        type: NotificationType.toolUpdate,
        showToast: false,
      );
      await service.addNotification(
        title: 'Tool 2',
        message: 'Message 2',
        type: NotificationType.toolUpdate,
        showToast: false,
      );

      expect(service.unreadCount, 2);
      await service.markAllAsRead();
      expect(service.unreadCount, 0);
      expect(service.notifications.every((n) => n.isRead), isTrue);
    });

    test('removeNotification removes specific notification', () async {
      await service.clearAll();
      await service.addNotification(
        title: 'To Delete',
        message: 'Delete me',
        type: NotificationType.system,
        showToast: false,
      );

      final id = service.notifications.first.id;
      expect(service.notifications.length, 1);

      await service.removeNotification(id);
      expect(service.notifications.length, 0);
    });

    test('clearAll removes all notifications', () async {
      await service.addNotification(
        title: 'Note',
        message: 'Msg',
        type: NotificationType.system,
        showToast: false,
      );
      expect(service.notifications.isNotEmpty, isTrue);

      await service.clearAll();
      expect(service.notifications.isEmpty, isTrue);
      expect(service.unreadCount, 0);
    });

    test('AppNotification JSON serialization and deserialization', () {
      final notif = AppNotification(
        id: '123',
        title: 'Update Title',
        message: 'Update Message',
        timestamp: DateTime(2026, 9, 9, 10, 0),
        type: NotificationType.toolUpdate,
        isRead: false,
        toolName: 'Watermark PDF',
        fileName: 'doc_watermarked.pdf',
        filePath: '/tmp/doc_watermarked.pdf',
      );

      final json = notif.toJson();
      final fromJson = AppNotification.fromJson(json);

      expect(fromJson.id, notif.id);
      expect(fromJson.title, notif.title);
      expect(fromJson.message, notif.message);
      expect(fromJson.type, NotificationType.toolUpdate);
      expect(fromJson.toolName, 'Watermark PDF');
      expect(fromJson.fileName, 'doc_watermarked.pdf');
      expect(fromJson.filePath, '/tmp/doc_watermarked.pdf');
    });

    test('ToolExecutionStep enum values exist', () {
      expect(ToolExecutionStep.values, contains(ToolExecutionStep.uploading));
      expect(ToolExecutionStep.values, contains(ToolExecutionStep.createJob));
      expect(ToolExecutionStep.values, contains(ToolExecutionStep.polling));
      expect(ToolExecutionStep.values, contains(ToolExecutionStep.completed));
      expect(ToolExecutionStep.values, contains(ToolExecutionStep.failed));
    });

    test('updateToolProgressNotification executes without unhandled error', () async {
      await service.updateToolProgressNotification(
        id: 7001,
        toolName: 'PDF to Word',
        step: ToolExecutionStep.uploading,
        detail: 'sample.pdf',
      );

      await service.updateToolProgressNotification(
        id: 7001,
        toolName: 'PDF to Word',
        step: ToolExecutionStep.createJob,
        detail: 'Submitting job details...',
      );

      await service.updateToolProgressNotification(
        id: 7001,
        toolName: 'PDF to Word',
        step: ToolExecutionStep.polling,
        detail: 'Attempt 1',
      );

      await service.updateToolProgressNotification(
        id: 7001,
        toolName: 'PDF to Word',
        step: ToolExecutionStep.completed,
        detail: 'sample_converted.docx',
      );

      await service.updateToolProgressNotification(
        id: 7001,
        toolName: 'PDF to Word',
        step: ToolExecutionStep.failed,
        detail: 'Conversion error',
      );

      await service.cancelToolProgressNotification(7001);
    });
  });
}


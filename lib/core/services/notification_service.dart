import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ToolExecutionStep {
  uploading,
  createJob,
  polling,
  completed,
  failed,
}

enum NotificationType {
  toolUpdate,    // File updated using a tool
  toolExecution, // Tool finished processing
  appUpdate,     // App/Tool version update available
  system,        // System alert
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? toolName;
  final String? fileName;
  final String? filePath;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.toolName,
    this.fileName,
    this.filePath,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? toolName,
    String? fileName,
    String? filePath,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      toolName: toolName ?? this.toolName,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'isRead': isRead,
        'toolName': toolName,
        'fileName': fileName,
        'filePath': filePath,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType nType = NotificationType.system;
    final typeStr = json['type'] as String?;
    if (typeStr != null) {
      for (final val in NotificationType.values) {
        if (val.name == typeStr) {
          nType = val;
          break;
        }
      }
    }

    return AppNotification(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      type: nType,
      isRead: json['isRead'] as bool? ?? false,
      toolName: json['toolName'] as String?,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

class NotificationService extends GetxController {
  static NotificationService get to => Get.find<NotificationService>();
  static const String _storageKey = 'plainscan_notifications';
  static const String toolProgressChannelId = 'plainscan_tool_progress';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    loadNotifications();
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            toolProgressChannelId,
            'Tool Execution Progress',
            description:
                'Persistent notifications displaying step-by-step progress of running tools',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
            showBadge: false,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        notifications.value = decoded
            .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Initial welcome notification
        notifications.value = [
          AppNotification(
            id: 'welcome_1',
            title: 'PlainScan Tools Ready',
            message: 'All 52 PDF, OCR, and AI conversion tools are active and ready to use.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            type: NotificationType.system,
            isRead: true,
          ),
        ];
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? toolName,
    String? fileName,
    String? filePath,
    bool showToast = true,
  }) async {
    final newNotification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      toolName: toolName,
      fileName: fileName,
      filePath: filePath,
    );

    notifications.insert(0, newNotification);
    await _save();

    if (showToast) {
      Get.rawSnackbar(
        titleText: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        messageText: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: type == NotificationType.appUpdate
            ? const Color(0xFF1E224F)
            : AppColors.primary,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
        icon: Icon(
          type == NotificationType.toolUpdate
              ? Icons.check_circle_outline
              : (type == NotificationType.appUpdate
                  ? Icons.system_update_alt_rounded
                  : Icons.notifications_active_outlined),
          color: Colors.white,
        ),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _save();
    }
  }

  Future<void> markAllAsRead() async {
    notifications.value = notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _save();
  }

  Future<void> removeNotification(String id) async {
    notifications.removeWhere((n) => n.id == id);
    await _save();
  }

  Future<void> clearAll() async {
    notifications.clear();
    await _save();
  }

  Future<void> updateToolProgressNotification({
    required int id,
    required String toolName,
    required ToolExecutionStep step,
    String? detail,
  }) async {
    try {
      String stepTitle;
      String stepBody;
      String subText;
      int currentProgress;
      const int maxProgress = 4;
      bool isOngoing;
      bool isAutoCancel;
      bool showProgress;
      bool isIndeterminate = false;

      switch (step) {
        case ToolExecutionStep.uploading:
          stepTitle = toolName;
          stepBody = '1. Uploading input${detail != null && detail.isNotEmpty ? ': $detail' : '...'}';
          subText = 'Step 1 of 4';
          currentProgress = 1;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          break;
        case ToolExecutionStep.createJob:
          stepTitle = toolName;
          stepBody = '2. Create job${detail != null && detail.isNotEmpty ? ': $detail' : '...'}';
          subText = 'Step 2 of 4';
          currentProgress = 2;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          break;
        case ToolExecutionStep.polling:
          stepTitle = toolName;
          stepBody = '3. Poll job status${detail != null && detail.isNotEmpty ? ' ($detail)' : '...'}';
          subText = 'Step 3 of 4';
          currentProgress = 3;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          isIndeterminate = true;
          break;
        case ToolExecutionStep.completed:
          stepTitle = '$toolName • Completed';
          stepBody = '4. Completed${detail != null && detail.isNotEmpty ? ': $detail' : ' successfully!'}';
          subText = 'Finished';
          currentProgress = 4;
          isOngoing = false;
          isAutoCancel = true;
          showProgress = false;
          break;
        case ToolExecutionStep.failed:
          stepTitle = '$toolName • Failed';
          stepBody = '4. Failed${detail != null && detail.isNotEmpty ? ': $detail' : ''}';
          subText = 'Error';
          currentProgress = 4;
          isOngoing = false;
          isAutoCancel = true;
          showProgress = false;
          break;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        toolProgressChannelId,
        'Tool Execution Progress',
        channelDescription:
            'Persistent notifications displaying step-by-step progress of running tools',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: isOngoing,
        autoCancel: isAutoCancel,
        onlyAlertOnce: true,
        showProgress: showProgress,
        maxProgress: maxProgress,
        progress: currentProgress,
        indeterminate: isIndeterminate,
        icon: '@mipmap/ic_launcher',
        subText: subText,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        id: id,
        title: stepTitle,
        body: stepBody,
        notificationDetails: notificationDetails,
        payload: 'tool_execution_$id',
      );
    } catch (e) {
      debugPrint('Error updating tool progress notification: $e');
    }
  }

  Future<void> cancelToolProgressNotification(int id) async {
    try {
      await _localNotifications.cancel(id: id);
    } catch (e) {
      debugPrint('Error canceling tool progress notification: $e');
    }
  }
}

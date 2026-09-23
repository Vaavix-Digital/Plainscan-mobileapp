import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:plainscan/app/routes.dart';
import 'package:plainscan/core/constants/api_constants.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('FCM background message received: ${message.messageId}');
  } catch (e) {
    debugPrint('Error in FCM background handler: $e');
  }
}

enum ToolExecutionStep { uploading, createJob, polling, completed, failed }

enum NotificationType {
  toolUpdate, // File updated using a tool
  toolExecution, // Tool finished processing
  appUpdate, // App/Tool version update available
  system, // System alert
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
      id:
          json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
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
  static const String toolProgressChannelId = 'plainscan_tool_progress';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  final RxnString fcmToken = RxnString();

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    _initFirebaseMessaging();
    loadNotifications();
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              _handleNotificationPayloadData(data);
            } catch (_) {}
          }
        },
      );

      // Cancel any legacy daily reminder notification schedule if present
      await _localNotifications.cancel(id: 940);

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'fcm_notifications',
            'FCM Push Notifications',
            description: 'PlainScan Push Notifications',
            importance: Importance.high,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = StorageService.getUserNotificationsKey(prefs);
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final loaded = decoded
            .map(
              (item) => AppNotification.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        // Strip the legacy "PlainScan Tools Ready" welcome notification
        // that was previously seeded automatically — no longer needed.
        final cleaned = loaded
            .where(
              (n) =>
                  !n.id.startsWith('welcome_') &&
                  n.title != 'PlainScan Tools Ready',
            )
            .toList();

        notifications.value = cleaned;

        // Persist the cleaned list so it doesn't reappear
        if (cleaned.length != loaded.length) {
          await _save();
        }
      } else {
        // No saved notifications — start with an empty list
        notifications.value = [];
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = StorageService.getUserNotificationsKey(prefs);
      final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  /// Reloads notifications for the active user on login or session switch
  Future<void> reloadForCurrentUser({bool isLogout = false}) async {
    if (isLogout) {
      await onLogout();
    } else {
      await loadNotifications();
      await registerFCMTokenOnBackend();
    }
  }

  /// Clears in-memory notifications on logout and removes token on backend
  Future<void> onLogout() async {
    await removeFCMTokenFromBackend();
    notifications.clear();
    await loadNotifications();
  }

  /// Clears in-memory notification list
  void clearUserNotifications() {
    notifications.clear();
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
    notifications.value = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
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
          stepBody =
              '1. Uploading input${detail != null && detail.isNotEmpty ? ': $detail' : '...'}';
          subText = 'Step 1 of 4';
          currentProgress = 1;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          break;
        case ToolExecutionStep.createJob:
          stepTitle = toolName;
          stepBody =
              '2. Create job${detail != null && detail.isNotEmpty ? ': $detail' : '...'}';
          subText = 'Step 2 of 4';
          currentProgress = 2;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          break;
        case ToolExecutionStep.polling:
          stepTitle = toolName;
          stepBody =
              '3. Poll job status${detail != null && detail.isNotEmpty ? ' ($detail)' : '...'}';
          subText = 'Step 3 of 4';
          currentProgress = 3;
          isOngoing = true;
          isAutoCancel = false;
          showProgress = true;
          isIndeterminate = true;
          break;
        case ToolExecutionStep.completed:
          stepTitle = '$toolName • Completed';
          stepBody =
              '4. Completed${detail != null && detail.isNotEmpty ? ': $detail' : ' successfully!'}';
          subText = 'Finished';
          currentProgress = 4;
          isOngoing = false;
          isAutoCancel = true;
          showProgress = false;
          break;
        case ToolExecutionStep.failed:
          stepTitle = '$toolName • Failed';
          stepBody =
              '4. Failed${detail != null && detail.isNotEmpty ? ': $detail' : ''}';
          subText = 'Error';
          currentProgress = 4;
          isOngoing = false;
          isAutoCancel = true;
          showProgress = false;
          break;
      }

      final AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
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

  Future<void> _initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions for FCM (iOS / Android 13+)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM permission status: ${settings.authorizationStatus}');

      // Subscribe to all users topic
      await messaging.subscribeToTopic('plainscan_all_users');

      // Set background messaging handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle FCM messages when app is in Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM foreground message received: ${message.messageId}');
        final notification = message.notification;
        if (notification != null) {
          _showFCMCustomNotification(
            title: notification.title ?? 'PlainScan',
            body: notification.body ?? '',
            payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
          );
        }
      });

      // Handle when notification opened app from background state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM notification opened app: ${message.data}');
        _handleNotificationPayloadData(message.data);
      });

      // Handle when app was launched from terminated state via notification tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM initial message tap detected: ${initialMessage.data}');
        _handleNotificationPayloadData(initialMessage.data);
      }

      // Get & log FCM Token on app start
      final token = await messaging.getToken();
      fcmToken.value = token;
      // ignore: avoid_print
      print(
        '\n=================== FCM DEVICE TOKEN ===================\n$token\n========================================================\n',
      );
      if (token != null && token.isNotEmpty) {
        await registerFCMTokenOnBackend(token: token);
      }

      messaging.onTokenRefresh.listen((newToken) {
        fcmToken.value = newToken;
        // ignore: avoid_print
        print(
          '\n=================== REFRESHED FCM TOKEN ===================\n$newToken\n===========================================================\n',
        );
        registerFCMTokenOnBackend(token: newToken);
      });
    } catch (e) {
      debugPrint('Error initializing Firebase Cloud Messaging: $e');
    }
  }

  /// Handles FCM notification payload data and performs deep link navigation
  void _handleNotificationPayloadData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    debugPrint('Processing notification payload data: $data');
    final screen = data['screen'] as String?;
    if (screen == null || screen.isEmpty) return;

    switch (screen.toLowerCase()) {
      case 'home':
        Get.toNamed(AppRoutes.home);
        break;
      case 'upgrade':
        Get.toNamed(AppRoutes.payment);
        break;
      case 'editor':
        Get.toNamed(AppRoutes.tools);
        break;
      default:
        if (screen.startsWith('/')) {
          Get.toNamed(screen);
        }
        break;
    }
  }

  /// 1. Register FCM Token on Backend: POST /api/push/register
  Future<bool> registerFCMTokenOnBackend({String? token}) async {
    try {
      final targetToken = token ?? fcmToken.value;
      if (targetToken == null || targetToken.isEmpty) {
        debugPrint('FCM register skipped: No FCM token available');
        return false;
      }
      final jwtToken = await StorageService.getToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM register skipped: User not logged in');
        return false;
      }

      final deviceType = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerPushToken}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': targetToken,
          'device': deviceType,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('FCM token registered on backend successfully ($deviceType)');
        return true;
      } else {
        debugPrint('Failed to register FCM token on backend: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error registering FCM token on backend: $e');
      return false;
    }
  }

  /// 2. Remove FCM Token from Backend: DELETE /api/push/token
  Future<bool> removeFCMTokenFromBackend({String? token}) async {
    try {
      final targetToken = token ?? fcmToken.value;
      if (targetToken == null || targetToken.isEmpty) {
        debugPrint('FCM remove skipped: No FCM token available');
        return false;
      }
      final jwtToken = await StorageService.getToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM remove skipped: User not logged in');
        return false;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.removePushToken}');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fcm_token': targetToken,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('FCM token removed from backend successfully');
        return true;
      } else {
        debugPrint('Failed to remove FCM token from backend: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error removing FCM token from backend: $e');
      return false;
    }
  }

  /// 3. Check Push Notification Status: GET /api/push/status
  Future<Map<String, dynamic>?> checkPushStatusOnBackend() async {
    try {
      final jwtToken = await StorageService.getToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM status check skipped: User not logged in');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pushStatus}');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('FCM push status check successful: $data');
        return data;
      } else {
        debugPrint('Failed to check push status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error checking push status on backend: $e');
      return null;
    }
  }

  /// 4. Toggle Push Notifications: PATCH /api/push/toggle
  Future<bool> togglePushNotificationsOnBackend(bool enabled) async {
    try {
      final jwtToken = await StorageService.getToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM toggle skipped: User not logged in');
        return false;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.togglePush}');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'enabled': enabled,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('FCM toggle push notifications successful (enabled: $enabled)');
        return true;
      } else {
        debugPrint('Failed to toggle push notifications on backend: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error toggling push notifications on backend: $e');
      return false;
    }
  }

  Future<void> _showFCMCustomNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_notifications',
      'FCM Push Notifications',
      channelDescription: 'PlainScan Push Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload ?? 'fcm_notification',
    );
    await addNotification(
      title: title,
      message: body,
      type: NotificationType.system,
      showToast: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/services/app_update_service.dart';
import 'package:plainscan/core/services/notification_service.dart';

void showNotificationsBottomSheet(BuildContext context) {
  final notifService = NotificationService.to;

  Get.bottomSheet(
    Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Notifications & Alerts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final count = notifService.unreadCount;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count new',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => notifService.markAllAsRead(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 20, color: AppColors.secondaryText),
                      onSelected: (val) {
                          notifService.clearAll();
                      },
                      itemBuilder: (context) => [
                        // const PopupMenuItem(
                        //   value: 'check_updates',
                        //   child: Row(
                        //     children: [
                        //       Icon(Icons.system_update_outlined, size: 18, color: AppColors.primary),
                        //       SizedBox(width: 8),
                        //       Text('Check for Updates'),
                        //     ],
                        //   ),
                        // ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.coral),
                              SizedBox(width: 8),
                              Text('Clear all notifications'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          const Divider(height: 1, color: AppColors.border),

          // Notification List
          Expanded(
            child: Obx(() {
              final list = notifService.notifications;
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'When you update documents with PlainScan tools or new tool updates arrive, alerts will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 68,
                ),
                itemBuilder: (context, index) {
                  final notif = list[index];
                  return _buildNotificationTile(notif, notifService);
                },
              );
            }),
          ),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}

Widget _buildNotificationTile(AppNotification notif, NotificationService service) {
  Color iconBg;
  Color iconColor;
  IconData iconData;

  switch (notif.type) {
    case NotificationType.toolUpdate:
    case NotificationType.toolExecution:
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_outline;
      break;
    case NotificationType.appUpdate:
      iconBg = const Color(0xFFEEF2FF);
      iconColor = const Color(0xFF4F46E5);
      iconData = Icons.system_update_alt_rounded;
      break;
    case NotificationType.system:
      iconBg = const Color(0xFFF8FAFC);
      iconColor = const Color(0xFF64748B);
      iconData = Icons.notifications_active_outlined;
      break;
  }

  return Dismissible(
    key: Key(notif.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: AppColors.coral.withValues(alpha: 0.1),
      child: const Icon(Icons.delete_outline, color: AppColors.coral),
    ),
    onDismissed: (_) => service.removeNotification(notif.id),
    child: InkWell(
      onTap: () {
        service.markAsRead(notif.id);
        if (notif.type == NotificationType.appUpdate) {
          Get.back();
          AppUpdateService.showUpdateDialog(isManualCheck: true);
        }
      },
      child: Container(
        color: notif.isRead ? Colors.transparent : const Color(0xFFF8FAFC),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 13.5,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(notif.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                  if (notif.fileName != null && notif.fileName!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              notif.fileName!,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!notif.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

String _formatRelativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${dt.day}/${dt.month}';
}

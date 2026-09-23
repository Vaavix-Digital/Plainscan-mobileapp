import 'package:flutter/material.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';

Widget buildDashboardUpdateBanner({bool forceDisplay = false}) {
  return DashboardUpdateBanner(forceDisplay: forceDisplay);
}

class DashboardUpdateBanner extends UpgradeCard {
  DashboardUpdateBanner({
    super.key,
    Upgrader? upgrader,
    super.margin,
    super.maxLines = 4,
    super.onIgnore,
    super.onLater,
    super.onUpdate,
    super.overflow = TextOverflow.ellipsis,
    super.showPrompt = false,
    super.showIgnore = false,
    super.showLater = false,
    super.showReleaseNotes = false,
    bool forceDisplay = false,
  }) : super(
          upgrader: upgrader ??
              Upgrader(
                debugDisplayAlways: forceDisplay,
                durationUntilAlertAgain: Duration.zero,
                countryCode: 'US',
                languageCode: 'en',
              ),
        );

  @override
  DashboardUpdateBannerState createState() => DashboardUpdateBannerState();
}

class DashboardUpdateBannerState extends UpgradeCardState {
  @override
  Widget buildUpgradeCard(BuildContext context, Key? key) {
    final appMessages = widget.upgrader.determineMessages(context);
    const title = 'Update Available';
    final storeVersion = widget.upgrader.currentAppStoreVersion ?? '';
    final rawMessage = widget.upgrader.body(appMessages);
    final displayMessage = rawMessage.contains('{{')
        ? 'A new version of PlainScan is available on Google Play Store with latest features and improvements.'
        : rawMessage;
    final updateText =
        appMessages.message(UpgraderMessage.buttonTitleUpdate) ?? 'Update';
    final laterText =
        appMessages.message(UpgraderMessage.buttonTitleLater) ?? 'Later';

    return Container(
      color: Colors.black.withOpacity(0.5),
      alignment: Alignment.center,
      child: Container(
        key: key,
        margin: widget.margin ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (storeVersion.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFDBEAFE),
                              ),
                            ),
                            child: Text(
                              'v$storeVersion',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayMessage,
                      maxLines: widget.maxLines,
                      overflow: widget.overflow,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.showLater)
                TextButton(
                  onPressed: onUserLater,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    foregroundColor: AppColors.secondaryText,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(laterText),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onUserUpdated,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(updateText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }

  @override
  void onUserUpdated() async {
    widget.upgrader.saveLastAlerted();
    final doProcess = widget.onUpdate?.call() ?? true;
    if (doProcess) {
      final storeUrl = widget.upgrader.versionInfo?.appStoreListingURL;
      if (storeUrl != null && storeUrl.isNotEmpty) {
        await widget.upgrader.sendUserToAppStore();
      } else {
        const playStoreUrl = 'market://details?id=com.plainscan.app';
        const webPlayStoreUrl =
            'https://play.google.com/store/apps/details?id=com.plainscan.app';
        final uri = Uri.parse(playStoreUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(
            Uri.parse(webPlayStoreUrl),
            mode: LaunchMode.externalApplication,
          );
        }
      }
    }
    forceRebuild();
  }
}

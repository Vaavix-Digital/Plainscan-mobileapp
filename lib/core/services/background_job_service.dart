import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/services/jobflow_services.dart';
import 'package:plainscan/core/services/notification_service.dart';
import 'package:plainscan/core/services/storage_service.dart';

class BackgroundJobState {
  final String jobId;
  final String toolSlug;
  final String toolName;
  final String step; // 'idle', 'uploading', 'creating', 'polling', 'downloading', 'completed', 'failed'
  final String stepMessage;
  final int pollingCount;
  final String? outputFilePath;
  final String? outputFileName;
  final String? errorMessage;
  final List<String> inputFiles;
  final DateTime startTime;
  final String? generatedText;
  final Map<String, dynamic> options;
  final int notificationId;

  BackgroundJobState({
    required this.jobId,
    required this.toolSlug,
    required this.toolName,
    required this.step,
    required this.stepMessage,
    this.pollingCount = 0,
    this.outputFilePath,
    this.outputFileName,
    this.errorMessage,
    this.inputFiles = const [],
    required this.startTime,
    this.generatedText,
    this.options = const {},
    required this.notificationId,
  });

  bool get isRunning =>
      step == 'uploading' ||
      step == 'creating' ||
      step == 'polling' ||
      step == 'downloading';

  bool get isCompleted => step == 'completed';
  bool get isFailed => step == 'failed';

  BackgroundJobState copyWith({
    String? jobId,
    String? toolSlug,
    String? toolName,
    String? step,
    String? stepMessage,
    int? pollingCount,
    String? outputFilePath,
    String? outputFileName,
    String? errorMessage,
    List<String>? inputFiles,
    DateTime? startTime,
    String? generatedText,
    Map<String, dynamic>? options,
    int? notificationId,
  }) {
    return BackgroundJobState(
      jobId: jobId ?? this.jobId,
      toolSlug: toolSlug ?? this.toolSlug,
      toolName: toolName ?? this.toolName,
      step: step ?? this.step,
      stepMessage: stepMessage ?? this.stepMessage,
      pollingCount: pollingCount ?? this.pollingCount,
      outputFilePath: outputFilePath ?? this.outputFilePath,
      outputFileName: outputFileName ?? this.outputFileName,
      errorMessage: errorMessage ?? this.errorMessage,
      inputFiles: inputFiles ?? this.inputFiles,
      startTime: startTime ?? this.startTime,
      generatedText: generatedText ?? this.generatedText,
      options: options ?? this.options,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'toolSlug': toolSlug,
        'toolName': toolName,
        'step': step,
        'stepMessage': stepMessage,
        'pollingCount': pollingCount,
        'outputFilePath': outputFilePath,
        'outputFileName': outputFileName,
        'errorMessage': errorMessage,
        'inputFiles': inputFiles,
        'startTime': startTime.toIso8601String(),
        'generatedText': generatedText,
        'options': options,
        'notificationId': notificationId,
      };

  factory BackgroundJobState.fromJson(Map<String, dynamic> json) {
    return BackgroundJobState(
      jobId: json['jobId'] as String? ?? '',
      toolSlug: json['toolSlug'] as String? ?? '',
      toolName: json['toolName'] as String? ?? '',
      step: json['step'] as String? ?? 'idle',
      stepMessage: json['stepMessage'] as String? ?? '',
      pollingCount: json['pollingCount'] as int? ?? 0,
      outputFilePath: json['outputFilePath'] as String?,
      outputFileName: json['outputFileName'] as String?,
      errorMessage: json['errorMessage'] as String?,
      inputFiles: (json['inputFiles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      generatedText: json['generatedText'] as String?,
      options: json['options'] is Map ? Map<String, dynamic>.from(json['options']) : {},
      notificationId: json['notificationId'] as int? ?? 1000,
    );
  }
}

class BackgroundJobService extends GetxService with WidgetsBindingObserver {
  static BackgroundJobService get to => Get.find<BackgroundJobService>();

  final RxMap<String, BackgroundJobState> _activeJobs = <String, BackgroundJobState>{}.obs;
  final Set<String> _inFlightJobIds = <String>{};

  Map<String, BackgroundJobState> get activeJobs => _activeJobs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    restorePendingJobs();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[BackgroundJobService] App resumed. Syncing active background jobs...');
      // Resume polling or check status for any active jobs
      _resumeActiveJobs();
    }
  }

  BackgroundJobState? getActiveJobForTool(String toolSlug) {
    final normalized = toolSlug.replaceAll('_', '-');
    for (final job in _activeJobs.values) {
      if (job.toolSlug == normalized || job.toolSlug == toolSlug) {
        return job;
      }
    }
    return null;
  }

  bool isToolProcessing(String toolSlug) {
    final job = getActiveJobForTool(toolSlug);
    return job != null && job.isRunning;
  }

  void registerJob(BackgroundJobState job) {
    _activeJobs[job.jobId.isNotEmpty ? job.jobId : job.toolSlug] = job;
    _persistJob(job);
  }

  void updateJobState(BackgroundJobState job) {
    _activeJobs[job.jobId.isNotEmpty ? job.jobId : job.toolSlug] = job;
    _persistJob(job);
  }

  void removeJob(String identifier) {
    _activeJobs.remove(identifier);
    final normalized = identifier.replaceAll('_', '-');
    _activeJobs.remove(normalized);
    _activeJobs.removeWhere((key, value) =>
        key == identifier ||
        key == normalized ||
        value.jobId == identifier ||
        value.toolSlug == identifier ||
        value.toolSlug == normalized);
    StorageService.removeActiveJob(identifier);
    StorageService.removeActiveJob(normalized);
  }

  Future<void> _persistJob(BackgroundJobState job) async {
    try {
      await StorageService.saveActiveJob(job.toJson());
    } catch (e) {
      debugPrint('[BackgroundJobService] Error persisting job: $e');
    }
  }

  Future<void> restorePendingJobs() async {
    try {
      final savedJobs = await StorageService.getActiveJobs();
      final now = DateTime.now();

      for (final map in savedJobs) {
        final job = BackgroundJobState.fromJson(map);
        // If job was created within the last 2 hours and was still running
        if (job.isRunning && now.difference(job.startTime).inHours < 2) {
          _activeJobs[job.jobId.isNotEmpty ? job.jobId : job.toolSlug] = job;
          if (job.jobId.isNotEmpty && !_inFlightJobIds.contains(job.jobId)) {
            _resumePollingForJob(job);
          }
        }
      }
    } catch (e) {
      debugPrint('[BackgroundJobService] Error restoring pending jobs: $e');
    }
  }

  Future<void> _resumeActiveJobs() async {
    for (final job in _activeJobs.values) {
      if (job.isRunning && job.jobId.isNotEmpty && !_inFlightJobIds.contains(job.jobId)) {
        _resumePollingForJob(job);
      }
    }
  }

  Future<void> _resumePollingForJob(BackgroundJobState job) async {
    _inFlightJobIds.add(job.jobId);
    try {
      final savedToken = await StorageService.getToken();
      final token = (savedToken != null && savedToken.isNotEmpty) ? savedToken : 'anonymous';

      final services = JobflowApiServices(accessToken: token);
      int pollingAttempt = job.pollingCount;

      while (true) {
        if (!_activeJobs.values.any((j) => j.jobId == job.jobId || j.toolSlug == job.toolSlug)) {
          debugPrint('[BackgroundJobService] Job was removed. Halting polling for ${job.toolSlug}');
          break;
        }
        pollingAttempt++;
        final updatedState = job.copyWith(
          step: 'polling',
          pollingCount: pollingAttempt,
          stepMessage: 'Waiting for job completion (Attempt $pollingAttempt)...',
        );
        updateJobState(updatedState);

        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.updateToolProgressNotification(
            id: job.notificationId,
            toolName: job.toolName,
            step: ToolExecutionStep.polling,
            detail: 'Polling attempt $pollingAttempt',
          );
        }

        try {
          final statusResponse = await services.getJobStatus(job.jobId);
          final status = statusResponse['status'];

          if (status == 'completed') {
            await _handleJobCompleted(updatedState, statusResponse, services);
            break;
          } else if (status == 'failed') {
            final errMsg = statusResponse['error'] ?? 'Plainscan API job failed during processing.';
            _handleJobFailed(updatedState, errMsg);
            break;
          }
        } catch (pollError) {
          debugPrint('[BackgroundJobService] Polling transient notice: $pollError');
        }

        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('[BackgroundJobService] Resume polling error: $e');
    } finally {
      _inFlightJobIds.remove(job.jobId);
    }
  }

  Future<void> _handleJobCompleted(
    BackgroundJobState job,
    Map<String, dynamic> statusResponse,
    JobflowApiServices services,
  ) async {
    try {
      final outputList = statusResponse['output_file_ids'] as List?;
      if (outputList == null || outputList.isEmpty) {
        _handleJobFailed(job, 'Completed job did not return any output file IDs.');
        return;
      }
      final outputFileId = outputList.first.toString();

      final outName = job.outputFileName ?? 'PlainScan_${job.toolSlug}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/$outName';

      final downloadingState = job.copyWith(
        step: 'downloading',
        stepMessage: 'Downloading completed output...',
      );
      updateJobState(downloadingState);

      await services.downloadFile(fileId: outputFileId, savePath: outPath);

      // Add to ScanController if registered
      if (Get.isRegistered<ScanController>()) {
        final scanController = Get.find<ScanController>();
        final ext = outName.split('.').last.toUpperCase();
        scanController.addScan(
          outPath,
          customName: outName,
          fileType: ext.isNotEmpty ? ext : 'PDF',
        );
      }

      final completedState = job.copyWith(
        step: 'completed',
        stepMessage: 'Success! File processed with ${job.toolName}.',
        outputFilePath: outPath,
        outputFileName: outName,
      );
      updateJobState(completedState);

      if (Get.isRegistered<NotificationService>()) {
        NotificationService.to.updateToolProgressNotification(
          id: job.notificationId,
          toolName: job.toolName,
          step: ToolExecutionStep.completed,
          detail: outName,
        );
        NotificationService.to.addNotification(
          title: '${job.toolName} Completed',
          message: 'Processed "$outName" with ${job.toolName}.',
          type: NotificationType.toolUpdate,
          toolName: job.toolName,
          fileName: outName,
          filePath: outPath,
          showToast: false,
        );
      }
    } catch (e) {
      _handleJobFailed(job, 'Failed to download processed file: $e');
    }
  }

  void _handleJobFailed(BackgroundJobState job, String errorMessage) {
    final failedState = job.copyWith(
      step: 'failed',
      stepMessage: errorMessage,
      errorMessage: errorMessage,
    );
    updateJobState(failedState);

    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.updateToolProgressNotification(
        id: job.notificationId,
        toolName: job.toolName,
        step: ToolExecutionStep.failed,
        detail: errorMessage,
      );
    }
  }
}

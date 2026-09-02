import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/features/home/widgets/dashboard_ad_banner.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ToolExecutorPage extends StatelessWidget {
  final ToolModel tool;

  const ToolExecutorPage({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    Get.put(ToolExecutorController(tool: tool));

    return GetBuilder<ToolExecutorController>(
      builder: (controller) {
        final isMulti = controller.isMultiFileTool();
        final slug = controller.getSlug();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              tool.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.key_outlined),
                tooltip: 'API Token Settings',
                onPressed: () => _showTokenSettingsDialog(context, controller),
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildAdBanner(),
                  // File / Input Selection
                  _buildInputSelectionCard(context, controller, isMulti),
                  const SizedBox(height: 10),
                  buildAdBanner(),
                  // Dynamic Options Card
                  _buildOptionsCard(controller, slug),
                  const SizedBox(height: 24),

                  // Execute Button / Running state
                  if (controller.isRunning) ...[
                    _buildProgressCard(controller),
                  ] else ...[
                    if (controller.currentStep == 'success') ...[
                      _buildSuccessCard(controller),
                      const SizedBox(height: 16),
                    ] else if (controller.currentStep == 'error') ...[
                      _buildErrorCard(controller),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: controller.executeJobFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tool.icon, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            'Run ${tool.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.currentStep == 'success' &&
                        controller.convertedFile != null) ...[
                      const SizedBox(height: 20),
                      _buildConvertedFileCard(context, controller),
                    ],
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSelectionCard(
    BuildContext context,
    ToolExecutorController controller,
    bool isMulti,
  ) {
    final supportsText = controller.isTextOptionSupported();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Source',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            if (supportsText) ...[
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: controller.useRawText,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      controller.toggleUseRawText(val!);
                    },
                  ),
                  const Text('Raw Text', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 20),
                  Radio<bool>(
                    value: false,
                    groupValue: controller.useRawText,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      controller.toggleUseRawText(val!);
                    },
                  ),
                  const Text('Document File', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (controller.useRawText && supportsText) ...[
              TextField(
                controller: controller.rawTextController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter text to process...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ] else ...[
              if (isMulti)
                _buildMultiFileSelectedCard(context, controller)
              else
                _buildSingleFileSelectedCard(context, controller),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleFileSelectedCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    if (controller.selectedFile == null) {
      return _buildEmptyInputState(context, controller, false);
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (controller.selectedFile!.fileType == 'PDF'
                          ? AppColors.coral
                          : AppColors.blue)
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              controller.selectedFile!.fileType == 'PDF'
                  ? Icons.picture_as_pdf
                  : Icons.image,
              color: controller.selectedFile!.fileType == 'PDF'
                  ? AppColors.coral
                  : AppColors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.selectedFile!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.selectedFile!.fileType} • ${(controller.selectedFile!.sizeKb / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.coral, size: 20),
            onPressed: () {
              controller.clearSingleSelectedFile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFileSelectedCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    if (controller.selectedFiles.isEmpty) {
      return _buildEmptyInputState(context, controller, true);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...controller.selectedFiles.map(
          (file) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  file.fileType == 'PDF'
                      ? Icons.picture_as_pdf
                      : Icons.image,
                  color: file.fileType == 'PDF'
                      ? AppColors.coral
                      : AppColors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.coral,
                    size: 16,
                  ),
                  onPressed: () {
                    controller.removeSelectedFile(file);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => controller.pickFileFromDevice(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.phone_android, size: 14),
                label: const Text(
                  'Add from Device',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showScansSelectorBottomSheet(context, controller, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.folder_open, size: 14),
                label: const Text(
                  'Add from Scans',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyInputState(
    BuildContext context,
    ToolExecutorController controller,
    bool isMulti,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No file selected',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Please upload a file from your device to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.pickFileFromDevice(isMulti),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.phone_android, size: 16),
              label: const Text(
                'Device Upload',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScansSelectorBottomSheet(
    BuildContext context,
    ToolExecutorController controller,
    bool isMulti,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select from Scans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: controller.scanController.scannedFiles.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('No scanned files found.'),
                      ),
                    )
                  : Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        itemCount:
                            controller.scanController.scannedFiles.length,
                        itemBuilder: (context, index) {
                          final file =
                              controller.scanController.scannedFiles[index];
                          if (isMulti) {
                            final isSelected = controller.selectedFiles.any(
                              (f) => f.id == file.id,
                            );
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(
                                file.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${file.fileType} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
                                style: const TextStyle(fontSize: 11),
                              ),
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                controller.toggleSelectedFileFromScans(
                                  file,
                                  val,
                                );
                              },
                            );
                          } else {
                            return ListTile(
                              leading: Icon(
                                file.fileType == 'PDF'
                                    ? Icons.picture_as_pdf
                                    : Icons.image,
                                color: file.fileType == 'PDF'
                                    ? AppColors.coral
                                    : AppColors.blue,
                              ),
                              title: Text(
                                file.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${file.fileType} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onTap: () {
                                controller.selectSingleFileFromScans(file);
                              },
                            );
                          }
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOptionsCard(ToolExecutorController controller, String slug) {
    Widget child = Container();

    switch (slug) {
      case 'pdf-compress':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compression Quality',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            DropdownButton<String>(
              value: controller.compressQuality,
              items: const [
                DropdownMenuItem(
                  value: 'low',
                  child: Text('Low (Maximum Compression)'),
                ),
                DropdownMenuItem(
                  value: 'balanced',
                  child: Text('Balanced (Recommended)'),
                ),
                DropdownMenuItem(
                  value: 'high',
                  child: Text('High Quality (Low Compression)'),
                ),
              ],
              onChanged: (val) => controller.setCompressQuality(val!),
            ),
          ],
        );
        break;

      case 'pdf-to-jpg':
      case 'pdf-to-png':
      case 'pdf-to-webp':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maximum Pages to Convert',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Slider(
              value: controller.pdfToJpgMaxPages.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              label: '${controller.pdfToJpgMaxPages}',
              activeColor: AppColors.primary,
              onChanged: (val) => controller.setPdfToJpgMaxPages(val.toInt()),
            ),
          ],
        );
        break;

      case 'jpg-to-pdf':
      case 'png-to-pdf':
      case 'webp-to-pdf':
      case 'image-to-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page Size Layout',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            DropdownButton<String>(
              value: controller.jpgToPdfPageSize,
              items: const [
                DropdownMenuItem(
                  value: 'letter',
                  child: Text('Letter (US standard)'),
                ),
                DropdownMenuItem(
                  value: 'A4',
                  child: Text('A4 (International standard)'),
                ),
              ],
              onChanged: (val) => controller.setJpgToPdfPageSize(val!),
            ),
          ],
        );
        break;

      case 'pdf-split':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages Per Split File',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: controller.pagesPerSplit > 1
                      ? () => controller.decrementPagesPerSplit()
                      : null,
                ),
                Text(
                  '${controller.pagesPerSplit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => controller.incrementPagesPerSplit(),
                ),
              ],
            ),
          ],
        );
        break;

      case 'pdf-rotate':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rotation Degrees',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            DropdownButton<int>(
              value: controller.rotation,
              items: const [
                DropdownMenuItem(value: 90, child: Text('90° Clockwise')),
                DropdownMenuItem(value: 180, child: Text('180° Flip')),
                DropdownMenuItem(
                  value: 270,
                  child: Text('270° Counter-Clockwise'),
                ),
              ],
              onChanged: (val) => controller.setRotation(val!),
            ),
          ],
        );
        break;

      case 'pdf-reorder':
      case 'pdf-rearrange':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Page Order (1-indexed)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.pageOrderController,
              decoration: const InputDecoration(
                hintText: 'e.g. 3, 1, 2, 4',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-watermark':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Watermark Properties',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.watermarkTextController,
              decoration: const InputDecoration(
                labelText: 'Watermark Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Font Size: ${controller.watermarkFontSize.toInt()}',
                      ),
                      Slider(
                        value: controller.watermarkFontSize,
                        min: 12,
                        max: 96,
                        onChanged: (v) => controller.setWatermarkFontSize(v),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Opacity: ${controller.watermarkOpacity.toInt()}%'),
                      Slider(
                        value: controller.watermarkOpacity,
                        min: 5,
                        max: 100,
                        onChanged: (v) => controller.setWatermarkOpacity(v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
        break;

      case 'pdf-lock':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.passwordController,
              decoration: const InputDecoration(
                labelText: 'User Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.ownerPasswordController,
              decoration: const InputDecoration(
                labelText: 'Owner/Admin Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text(
                'Allow Printing',
                style: TextStyle(fontSize: 13),
              ),
              value: controller.allowPrinting,
              onChanged: (v) => controller.toggleAllowPrinting(v!),
            ),
            CheckboxListTile(
              title: const Text(
                'Allow Copying',
                style: TextStyle(fontSize: 13),
              ),
              value: controller.allowCopying,
              onChanged: (v) => controller.toggleAllowCopying(v!),
            ),
          ],
        );
        break;

      case 'pdf-unlock':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Decrypt Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-sign':
      case 'pdf-esign':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digital Signature Text',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.signatureTextController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
        break;

      case 'scan-ocr':
      case 'ocr-to-text':
      case 'ocr-to-pdf':
      case 'ocr-to-word':
      case 'ocr-to-excel':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OCR Language Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.ocrLanguage,
              items: const [
                DropdownMenuItem(value: 'eng', child: Text('English (eng)')),
                DropdownMenuItem(value: 'hin', child: Text('Hindi (hin)')),
                DropdownMenuItem(value: 'ara', child: Text('Arabic (ara)')),
                DropdownMenuItem(value: 'fre', child: Text('French (fre)')),
                DropdownMenuItem(value: 'spa', child: Text('Spanish (spa)')),
              ],
              onChanged: (val) => controller.setOcrLanguage(val!),
            ),
          ],
        );
        break;

      case 'ai-summarize':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary Detail Length',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            DropdownButton<String>(
              value: controller.aiLength,
              items: const [
                DropdownMenuItem(value: 'short', child: Text('Short')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'long', child: Text('Long')),
                DropdownMenuItem(value: 'detailed', child: Text('Detailed')),
              ],
              onChanged: (val) => controller.setAiLength(val!),
            ),
          ],
        );
        break;

      case 'ai-rewrite':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Writing Style',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            DropdownButton<String>(
              value: controller.aiStyle,
              items: const [
                DropdownMenuItem(
                  value: 'professional',
                  child: Text('Professional'),
                ),
                DropdownMenuItem(value: 'casual', child: Text('Casual')),
                DropdownMenuItem(value: 'formal', child: Text('Formal')),
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
              ],
              onChanged: (val) => controller.setAiStyle(val!),
            ),
          ],
        );
        break;

      case 'ai-translate':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Translation Language',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.aiTranslateLanguageController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
        break;

      case 'ai-extract-data':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comma Separated Fields to Extract',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.aiExtractFieldsController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
        break;

      case 'ai-cover-letter':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cover Letter Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.coverLetterJobTitleController,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.coverLetterCompanyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.coverLetterJdController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-redact':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PII Patterns to Auto-Redact',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.redactPatternsController,
              decoration: const InputDecoration(
                hintText: 'email, phone, ssn, credit_card',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Redaction Bar Color',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.redactColorController,
              decoration: const InputDecoration(
                hintText: '#000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-header-footer':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Header & Footer Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.headerController,
              decoration: const InputDecoration(
                labelText: 'Header Text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.footerController,
              decoration: const InputDecoration(
                labelText: 'Footer Text (use {page} and {total})',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-page-numbers':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Page Numbers Position',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.pageNumberPosition,
              items: const [
                DropdownMenuItem(value: 'bottom-center', child: Text('Bottom Center')),
                DropdownMenuItem(value: 'bottom-left', child: Text('Bottom Left')),
                DropdownMenuItem(value: 'bottom-right', child: Text('Bottom Right')),
                DropdownMenuItem(value: 'top-center', child: Text('Top Center')),
                DropdownMenuItem(value: 'top-left', child: Text('Top Left')),
                DropdownMenuItem(value: 'top-right', child: Text('Top Right')),
              ],
              onChanged: (val) {
                controller.pageNumberPosition = val!;
                controller.update();
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Number Format',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.pageNumberFormat,
              items: const [
                DropdownMenuItem(value: 'full', child: Text('Page 1 of 10 (full)')),
                DropdownMenuItem(value: 'page_only', child: Text('1 (page_only)')),
                DropdownMenuItem(value: 'of_total', child: Text('1 / 10 (of_total)')),
              ],
              onChanged: (val) {
                controller.pageNumberFormat = val!;
                controller.update();
              },
            ),
          ],
        );
        break;

      case 'pdf-compare':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diff Comparison Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.compareMode,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Text Diff Mode')),
              ],
              onChanged: (val) => controller.setCompareMode(val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.compareAddsColorController,
              decoration: const InputDecoration(
                labelText: 'Added Text Highlight (#006600)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.compareRemovesColorController,
              decoration: const InputDecoration(
                labelText: 'Removed Text Highlight (#cc0000)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'form-filling':
      case 'fill-pdf':
      case 'pdf-fill-form':
      case 'pdf-form-filler':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form Field Data (JSON)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.formFillingDataController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{\n  "First Name": "John",\n  "Date": "2026-08-27"\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;

      case 'pdf-to-fillable-form':
      case 'pdf-to-fillable':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Auto-detect Form Fields',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Automatically scan and convert blank lines/boxes to interactive fields.',
                style: TextStyle(fontSize: 11),
              ),
              value: controller.pdfToFillableAutoDetect,
              onChanged: (v) => controller.setPdfToFillableAutoDetect(v ?? true),
            ),
          ],
        );
        break;

      case 'humanize-ai-content':
      case 'humanize-ai':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Humanize Writing Style',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.aiHumanizeStyle,
              items: const [
                DropdownMenuItem(value: 'casual', child: Text('Casual (Recommended)')),
                DropdownMenuItem(value: 'professional', child: Text('Professional')),
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
              ],
              onChanged: (val) => controller.setAiHumanizeStyle(val!),
            ),
          ],
        );
        break;

      case 'batch-pdf-converter':
      case 'batch-converter':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Conversion Format',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.batchTargetFormat,
              items: const [
                DropdownMenuItem(value: 'word', child: Text('Word (.docx)')),
                DropdownMenuItem(value: 'pdf', child: Text('PDF (.pdf)')),
                DropdownMenuItem(value: 'txt', child: Text('Text (.txt)')),
                DropdownMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
              ],
              onChanged: (val) => controller.setBatchTargetFormat(val!),
            ),
          ],
        );
        break;

      case 'batch-rename':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Batch Rename Pattern',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.renamePrefixController,
              decoration: const InputDecoration(
                labelText: 'Prefix (e.g. Invoice_)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.renameSuffixController,
              decoration: const InputDecoration(
                labelText: 'Suffix (e.g. _2026)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.renameReplaceFromController,
                    decoration: const InputDecoration(
                      labelText: 'Replace From',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.renameReplaceToController,
                    decoration: const InputDecoration(
                      labelText: 'Replace To',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        break;

      case 'file-to-zip':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ZIP Archive Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.zipArchiveNameController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        );
        break;

      default:
        // Render simple placeholder
        return const SizedBox.shrink();
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tool Options',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ToolExecutorController controller) {
    Widget stepIndicator(
      String step,
      String label,
      bool isFinished,
      bool isActive,
    ) {
      Color c = AppColors.secondaryText;
      Widget leading = const Icon(
        Icons.radio_button_unchecked,
        size: 20,
        color: AppColors.secondaryText,
      );

      if (isFinished) {
        c = Colors.green;
        leading = const Icon(Icons.check_circle, size: 20, color: Colors.green);
      } else if (isActive) {
        c = AppColors.primary;
        leading = const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: c,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final stepOrder = ['uploading', 'creating', 'polling', 'downloading'];
    final activeIndex = stepOrder.indexOf(controller.currentStep);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Executing Job Flow',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            if (controller.jobId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Job ID: ${controller.jobId}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            stepIndicator(
              'uploading',
              'Step 1: Uploading Input Document(s)',
              activeIndex > 0,
              controller.currentStep == 'uploading',
            ),
            stepIndicator(
              'creating',
              'Step 2: Submitting Request / Creating Job',
              activeIndex > 1,
              controller.currentStep == 'creating',
            ),
            stepIndicator(
              'polling',
              'Step 3: Polling Job Progress (every 2s)',
              activeIndex > 2,
              controller.currentStep == 'polling',
            ),
            stepIndicator(
              'downloading',
              'Step 4: Downloading Output Stream',
              controller.currentStep == 'success',
              controller.currentStep == 'downloading',
            ),
            const SizedBox(height: 12),
            Text(
              controller.errorMessage,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(ToolExecutorController controller) {
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text(
                  'Execution Successful!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The tool finished processing. Output file "${controller.outputFileName}" has been generated and successfully registered in the Files Manager.',
              style: TextStyle(color: Colors.green.shade900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ToolExecutorController controller) {
    return Card(
      color: Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 24),
                SizedBox(width: 10),
                Text(
                  'Execution Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage,
              style: TextStyle(color: Colors.red.shade900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showTokenSettingsDialog(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final tokenInputController = TextEditingController();
    StorageService.getToken().then((token) {
      if (token != null) {
        tokenInputController.text = token;
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Access Token Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Plainscan API/Access Token to authorize requests.',
                style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tokenInputController,
                decoration: const InputDecoration(
                  labelText: 'Access Token',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final token = tokenInputController.text.trim();
                await controller.saveToken(token);
                Get.back();
                Get.rawSnackbar(
                  messageText: const Text(
                    'Access Token updated successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConvertedFileCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    if (controller.convertedFile == null) return const SizedBox.shrink();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Converted File',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (controller.convertedFile!.fileType == 'PDF'
                                  ? AppColors.coral
                                  : AppColors.blue)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      controller.convertedFile!.fileType == 'PDF'
                          ? Icons.picture_as_pdf
                          : Icons.image,
                      color: controller.convertedFile!.fileType == 'PDF'
                          ? AppColors.coral
                          : AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.convertedFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.convertedFile!.fileType} • ${(controller.convertedFile!.sizeKb / 1024).toStringAsFixed(1)} MB',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final path = controller.convertedFile!.path;
                        if (path == null) {
                          throw Exception('File path is missing.');
                        }
                        final fileBytes = await File(path).readAsBytes();
                        final savePath = await FilePicker.saveFile(
                          dialogTitle: 'Save converted file...',
                          fileName: controller.convertedFile!.name,
                          bytes: fileBytes,
                        );

                        if (savePath != null) {
                          Get.rawSnackbar(
                            messageText: const Text(
                              'File saved successfully!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      } catch (e) {
                        Get.rawSnackbar(
                          messageText: Text(
                            'Failed to save file: $e',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.coral,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showFileRenameDialog(
                        context,
                        controller,
                        controller.convertedFile!,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text(
                      'Rename',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFileRenameDialog(
    BuildContext context,
    ToolExecutorController controller,
    FileModel file,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = file.name;
        return AlertDialog(
          title: const Text('Rename Converted File'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'New file name',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            controller: TextEditingController(text: file.name),
            onChanged: (value) {
              newName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.trim().isNotEmpty) {
                  controller.renameConvertedFile(file.id, newName.trim());
                  Get.back();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Rename',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

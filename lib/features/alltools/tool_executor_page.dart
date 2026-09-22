import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_ad_banner.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:share_plus/share_plus.dart';

class ToolExecutorPage extends StatefulWidget {
  final ToolModel tool;
  final List<FileModel>? initialFiles;
  final bool autoExecute;

  const ToolExecutorPage({
    super.key,
    required this.tool,
    this.initialFiles,
    this.autoExecute = false,
  });

  @override
  State<ToolExecutorPage> createState() => _ToolExecutorPageState();
}

class _ToolExecutorPageState extends State<ToolExecutorPage> {
  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ToolExecutorController>()) {
      Get.delete<ToolExecutorController>();
    }
    Get.put(ToolExecutorController(
      tool: widget.tool,
      initialFiles: widget.initialFiles,
      autoExecute: widget.autoExecute,
    ));
  }

  @override
  void dispose() {
    if (Get.isRegistered<ToolExecutorController>()) {
      Get.delete<ToolExecutorController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;

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
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.key_outlined),
            //     tooltip: 'API Token Settings',
            //     onPressed: () => _showTokenSettingsDialog(context, controller),
            //   ),
            // ],
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: slug == 'ai-email-writer'
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAiEmailWriterView(context, controller),
                        const SizedBox(height: 24),
                        buildAdBanner(),
                      ],
                    )
                  : slug == 'ai-proofread'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAiProofreadView(context, controller),
                            const SizedBox(height: 24),
                            buildAdBanner(),
                          ],
                        )
                      : slug == 'ai-citation'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAiCitationView(context, controller),
                                const SizedBox(height: 24),
                                buildAdBanner(),
                              ],
                            )
                          : slug == 'ai-flashcards'
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildAiFlashcardsView(context, controller),
                                    const SizedBox(height: 24),
                                    buildAdBanner(),
                                  ],
                                )
                              : slug == 'ai-quiz'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildAiQuizView(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : slug == 'chat-with-pdf'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildChatWithPdfView(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : slug == 'ats-scanner'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildAtsScannerView(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : (slug == 'word-counter' || slug == 'character-counter')
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTextCounterView(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : slug == 'image-to-base64'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildImageToBase64View(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : slug == 'base64-to-image'
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildBase64ToImageView(context, controller),
                                        const SizedBox(height: 24),
                                        buildAdBanner(),
                                      ],
                                    )
                              : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File / Input Selection
                        AbsorbPointer(
                          absorbing: controller.isRunning,
                          child: Opacity(
                            opacity: controller.isRunning ? 0.65 : 1.0,
                            child: _buildInputSelectionCard(context, controller, isMulti),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // Dynamic Options Card
                        AbsorbPointer(
                          absorbing: controller.isRunning,
                          child: Opacity(
                            opacity: controller.isRunning ? 0.65 : 1.0,
                            child: _buildOptionsCard(controller, slug),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Execute Button / Running state
                        if (controller.isRunning) ...[
                          _buildProgressCard(controller),
                        ] else ...[
                          if (controller.currentStep == 'success') ...[
                            if (controller.extractedMetadataMap != null &&
                                (slug == 'read-metadata' ||
                                    (slug == 'metadata-editor' &&
                                        (controller.metadataAction == 'view' ||
                                            controller.metadataAction == 'read')))) ...[
                              _buildMetadataResultCard(context, controller),
                              const SizedBox(height: 16),
                            ] else ...[
                              _buildSuccessCard(controller),
                              const SizedBox(height: 16),
                            ],
                          ] else if (controller.currentStep == 'error') ...[
                            _buildErrorCard(controller),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton(
                            onPressed: controller.isExecutionDisabled
                                ? null
                                : controller.executeJobFlow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade500,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tool.icon,
                                  color: controller.isExecutionDisabled
                                      ? Colors.grey.shade500
                                      : Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    controller.isExecutionDisabled
                                        ? 'Document Already Unlocked'
                                        : 'Run ${tool.name}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: controller.isExecutionDisabled
                                          ? Colors.grey.shade500
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                        buildAdBanner(),   
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  IconData _getFileIcon(String fileType) {
    final upper = fileType.toUpperCase();
    if (upper == 'PDF') return Icons.picture_as_pdf;
    if (upper == 'XLS' || upper == 'XLSX' || upper.contains('EXCEL')) return Icons.table_chart_outlined;
    if (upper == 'CSV') return Icons.table_view_outlined;
    if (upper == 'DOC' || upper == 'DOCX' || upper.contains('WORD')) return Icons.description_outlined;
    if (upper == 'PPT' || upper == 'PPTX') return Icons.slideshow_outlined;
    if (upper == 'ZIP') return Icons.folder_zip_outlined;
    if (upper == 'TXT' || upper == 'MD') return Icons.text_snippet_outlined;
    return Icons.image_outlined;
  }

  Color _getFileColor(String fileType) {
    final upper = fileType.toUpperCase();
    if (upper == 'PDF') return AppColors.coral;
    if (upper == 'XLS' || upper == 'XLSX' || upper.contains('EXCEL') || upper == 'CSV') return const Color(0xFF10B981);
    if (upper == 'DOC' || upper == 'DOCX' || upper.contains('WORD')) return AppColors.blue;
    if (upper == 'PPT' || upper == 'PPTX') return AppColors.coral;
    if (upper == 'ZIP') return const Color(0xFFD97706);
    return AppColors.purple;
  }

  Widget _buildHtmlToPdfInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final isUrlMode = controller.htmlToPdfMode == 'url';

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE44D26).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.html_outlined,
                    color: Color(0xFFE44D26),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HTML to PDF Input',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No file upload needed. Pass URL or raw HTML.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setHtmlToPdfMode('url'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isUrlMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isUrlMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 16,
                              color: isUrlMode ? AppColors.primary : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Webpage URL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isUrlMode ? FontWeight.bold : FontWeight.w500,
                                color: isUrlMode ? AppColors.primary : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.setHtmlToPdfMode('html'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isUrlMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !isUrlMode
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.code_rounded,
                              size: 16,
                              color: !isUrlMode ? AppColors.primary : AppColors.secondaryText,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HTML Code',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: !isUrlMode ? FontWeight.bold : FontWeight.w500,
                                color: !isUrlMode ? AppColors.primary : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (isUrlMode) ...[
              TextField(
                controller: controller.htmlToPdfUrlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Target Webpage URL',
                  hintText: 'https://example.com',
                  prefixIcon: const Icon(Icons.language_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ] else ...[
              TextField(
                controller: controller.htmlToPdfHtmlController,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Raw HTML Content',
                  hintText: '<h1>Hello World</h1>\n<p>Your HTML content here...</p>',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdTemplatesInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID Card Details & Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Upload logo/photo and fill in organization & employee details.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Company & Employee Photos (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: controller.idLogoFile != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.idLogoFile!.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => controller.clearIdLogo(),
                                child: const Icon(Icons.close, size: 16, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => controller.pickIdLogo(),
                          icon: const Icon(Icons.image_outlined, size: 16),
                          label: const Text('Company Logo', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: controller.idPhotoFile != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  controller.idPhotoFile!.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => controller.clearIdPhoto(),
                                child: const Icon(Icons.close, size: 16, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => controller.pickIdPhoto(),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('Employee Photo', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Organization Info',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.idCompanyNameController,
              decoration: InputDecoration(
                labelText: 'Company / Organization Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.idCompanyAddressController,
              decoration: InputDecoration(
                labelText: 'Company Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.idCompanyPhoneController,
              decoration: InputDecoration(
                labelText: 'Company Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Employee Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.idEmployeeNameController,
              decoration: InputDecoration(
                labelText: 'Employee Full Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.idEmployeeRoleController,
              decoration: InputDecoration(
                labelText: 'Role / Job Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller.idEmployeeIdController,
              decoration: InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceGeneratorInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice Details & Items',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Generate a PDF invoice directly from your billing details.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.invoiceNumberController,
              decoration: InputDecoration(
                labelText: 'Invoice Number *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'From (Issuer / Business)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.invoiceFromNameController,
              decoration: InputDecoration(
                labelText: 'Business / Issuer Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.invoiceFromEmailController,
                    decoration: InputDecoration(
                      labelText: 'Issuer Email',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.invoiceFromPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Issuer Phone',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.invoiceFromAddressController,
              decoration: InputDecoration(
                labelText: 'Issuer Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bill To (Client / Customer)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.invoiceToNameController,
              decoration: InputDecoration(
                labelText: 'Client Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.invoiceToEmailController,
              decoration: InputDecoration(
                labelText: 'Client Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.invoiceToAddressController,
              decoration: InputDecoration(
                labelText: 'Client Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Currency',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<String>(
                        value: controller.invoiceCurrency,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                          DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
                          DropdownMenuItem(value: 'CAD', child: Text('CAD (\$)')),
                          DropdownMenuItem(value: 'AUD', child: Text('AUD (\$)')),
                        ],
                        onChanged: (val) {
                          if (val != null) controller.setInvoiceCurrency(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '5.0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) controller.setInvoiceDiscount(parsed);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipping',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '15.0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) controller.setInvoiceShipping(parsed);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showAddInvoiceItemDialog(context, controller);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...controller.invoiceItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final qty = item['quantity'] ?? 1;
              final price = item['unit_price'] ?? 0.0;
              final total = (qty as num) * (price as num);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['description']?.toString() ?? 'Item',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Qty: $qty × ${controller.invoiceCurrency} $price = ${controller.invoiceCurrency} ${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coral),
                      onPressed: () => controller.removeInvoiceItem(idx),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddInvoiceItemDialog(BuildContext context, ToolExecutorController controller) {
    final descCtrl = TextEditingController(text: 'Consulting Service');
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '150.00');
    final taxCtrl = TextEditingController(text: '0');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Invoice Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit Price', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: taxCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tax Rate (%)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final desc = descCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
              final tax = double.tryParse(taxCtrl.text.trim()) ?? 0.0;
              if (desc.isNotEmpty) {
                controller.addInvoiceItem(desc, qty, price, tax);
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.secondaryText),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiEmailWriterView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAiEmailWriterHeader(),
        if (controller.isRunning) ...[
          _buildAiEmailWriterProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAiEmailWriterResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildAiEmailWriterInputCard(context, controller),
        ],
      ],
    );
  }

  Widget _buildAiEmailWriterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI Tool',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Free AI Email Writer — Generate Professional Business Emails Instantly',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmailWriterInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return _buildAiEmailWriterInputCard(context, controller);
  }

  Widget _buildAiEmailWriterInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildAiEmailFieldLabel('Recipient'),
          const SizedBox(height: 6),
          _buildAiEmailTextField(
            controller: controller.emailRecipientController,
            hintText: 'HR Manager',
          ),
          const SizedBox(height: 16),
          _buildAiEmailFieldLabel('Purpose'),
          const SizedBox(height: 6),
          _buildAiEmailTextField(
            controller: controller.emailPurposeController,
            hintText: 'Follow up on interview',
          ),
          const SizedBox(height: 16),
          _buildAiEmailFieldLabel('Key Points'),
          const SizedBox(height: 6),
          _buildAiEmailTextField(
            controller: controller.emailKeyPointsController,
            hintText: 'Thank them, ask about next steps',
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAiEmailFieldLabel('Tone'),
                          const SizedBox(height: 6),
                          _buildAiEmailToneDropdown(controller),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAiEmailFieldLabel('Sender Name'),
                          const SizedBox(height: 6),
                          _buildAiEmailTextField(
                            controller: controller.emailSenderNameController,
                            hintText: 'Your Name',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAiEmailFieldLabel('Tone'),
                    const SizedBox(height: 6),
                    _buildAiEmailToneDropdown(controller),
                    const SizedBox(height: 16),
                    _buildAiEmailFieldLabel('Sender Name'),
                    const SizedBox(height: 6),
                    _buildAiEmailTextField(
                      controller: controller.emailSenderNameController,
                      hintText: 'Your Name',
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ready to process',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (controller.emailPurposeController.text.trim().isNotEmpty) {
                      controller.emailSubjectController.text = controller.emailPurposeController.text.trim();
                    }
                    if (controller.emailKeyPointsController.text.trim().isNotEmpty) {
                      controller.emailContextController.text = controller.emailKeyPointsController.text.trim();
                    }
                    controller.executeJobFlow();
                  },
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  label: const Text(
                    'Process with AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiEmailWriterProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiEmailTrustFooter(),
        const SizedBox(height: 24),
        _buildAiEmailInfoCards(),
      ],
    );
  }

  Widget _buildAiEmailWriterResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedEmailContent.isNotEmpty
        ? controller.generatedEmailContent
        : 'Subject: ${controller.emailPurposeController.text.isNotEmpty ? controller.emailPurposeController.text : "Follow-Up on Your Support"}\n\nDear ${controller.emailRecipientController.text.isNotEmpty ? controller.emailRecipientController.text : "Hr"},\n\n${controller.emailKeyPointsController.text.isNotEmpty ? controller.emailKeyPointsController.text : "Thank you for your assistance. I wanted to express my gratitude once again."}\n\nBest regards,\n${controller.emailSenderNameController.text.isNotEmpty ? controller.emailSenderNameController.text : "Abhinav"}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light green banner header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              // Email body
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3 Action buttons: "Process another item", "Download TXT", "Copy Text"
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.resetEmailWriter,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Process another item',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: controller.downloadEmailTxt,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Download TXT',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.copyEmailText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Copy Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.resetEmailWriter,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.downloadEmailTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.copyEmailText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Copy Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        _buildAiEmailTrustFooter(),
      ],
    );
  }

  Widget _buildAiEmailTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAiEmailInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What AI Email Writer does',
          content:
              'Generates a well-structured email subject and body based on a few bullet points of context, tailored to your chosen tone and audience.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use AI Email Writer',
          content:
              '1  Enter the purpose and key points of your email\n2  Select your desired tone and sender details\n3  Click "Process with AI" to generate your email',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about AI Email Writer',
          content:
              'Your files and prompts are processed securely and never stored permanently. You can copy the text or download it as a TXT file immediately.',
        ),
      ],
    );
  }

  Widget _buildAiEmailInfoCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiEmailFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildAiEmailTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAiEmailToneDropdown(ToolExecutorController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: controller.selectedEmailTone,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w500,
          ),
          items: ToolExecutorController.emailToneOptions.map((tone) {
            return DropdownMenuItem<String>(
              value: tone,
              child: Text(tone),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              controller.setEmailTone(val);
            }
          },
        ),
      ),
    );
  }

  // ==========================================
  // AI Proofreader Dedicated UI Suite
  // ==========================================

  Widget _buildAiProofreadView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAiProofreadHeader(),
        if (controller.isRunning) ...[
          _buildAiProofreadProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAiProofreadResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildAiProofreadInputCard(context, controller),
        ],
      ],
    );
  }

  Widget _buildAiProofreadHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Free AI Proofreader — Fix Grammar,\nSpelling, and Style Instantly',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAiProofreadInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Big text input area with dynamic character counter
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller.proofreadTextController,
                  minLines: 8,
                  maxLines: 12,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Paste or type your text here to proofread...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (text) {
                    controller.update();
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${controller.proofreadTextController.text.length} characters',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Focus Area dropdown
          const Text(
            'Focus Area',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedProofreadFocusArea,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
                items: ToolExecutorController.proofreadFocusAreaOptions.map((area) {
                  return DropdownMenuItem<String>(
                    value: area,
                    child: Text(area),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.setProofreadFocusArea(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ready to process',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (controller.proofreadTextController.text.trim().isNotEmpty) {
                      controller.rawTextController.text = controller.proofreadTextController.text.trim();
                      controller.useRawText = true;
                    }
                    controller.executeJobFlow();
                  },
                  icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  label: const Text(
                    'Process with AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiProofreadProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiEmailTrustFooter(),
        const SizedBox(height: 24),
        _buildAiProofreadInfoCards(),
      ],
    );
  }

  Widget _buildAiProofreadResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedProofreadContent.isNotEmpty
        ? controller.generatedProofreadContent
        : (controller.proofreadTextController.text.isNotEmpty
            ? controller.proofreadTextController.text
            : 'Text proofread and corrected.');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Light green banner header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              // Corrected text body
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action buttons: "Process another item", "Download TXT", "Copy Text"
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.resetProofreader,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Process another item',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: controller.downloadProofreadTxt,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Download TXT',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.copyProofreadText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Copy Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.resetProofreader,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.downloadProofreadTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.copyProofreadText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Copy Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        _buildAiEmailTrustFooter(),
      ],
    );
  }

  Widget _buildAiProofreadInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What AI Proofreader does',
          content:
              'Analyzes and refines your text for grammatical accuracy, spelling corrections, stylistic improvements, and overall readability.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use AI Proofreader',
          content:
              '1  Paste or type your text in the input area\n2  Select your desired focus area\n3  Click "Process with AI" to instantly polish your writing',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about AI Proofreader',
          content:
              'Your text is processed securely and never stored permanently. You can copy the corrected text or download it right away.',
        ),
      ],
    );
  }

  // ==========================================
  // AI Citation Generator Dedicated UI Suite
  // ==========================================

  Widget _buildAiCitationView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAiCitationHeader(),
        if (controller.isRunning) ...[
          _buildAiCitationProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAiCitationResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildAiCitationInputCard(context, controller),
        ],
      ],
    );
  }

  Widget _buildAiCitationHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI Tool',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI Citation Generator — Create APA,\nMLA & Chicago Citations Instantly',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAiCitationInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 480;

                  Widget buildRow(Widget left, Widget right) {
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 16),
                          Expanded(child: right),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          left,
                          const SizedBox(height: 14),
                          right,
                        ],
                      );
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Style | Title
                      buildRow(
                        _buildAiCitationStyleField(controller),
                        _buildAiCitationField(
                          label: 'Title',
                          hintText: 'Title of the work',
                          controller: controller.citationTitleController,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Authors | Year
                      buildRow(
                        _buildAiCitationField(
                          label: 'Authors',
                          hintText: 'Last, First; Last2, First2',
                          controller: controller.citationAuthorsController,
                        ),
                        _buildAiCitationField(
                          label: 'Year',
                          hintText: 'e.g. 2024',
                          controller: controller.citationYearController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 3: URL | DOI
                      buildRow(
                        _buildAiCitationField(
                          label: 'URL',
                          hintText: 'https://...',
                          controller: controller.citationUrlController,
                          keyboardType: TextInputType.url,
                        ),
                        _buildAiCitationField(
                          label: 'DOI',
                          hintText: '10.1000/xyz123',
                          controller: controller.citationDoiController,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 4: Publisher | Journal
                      buildRow(
                        _buildAiCitationField(
                          label: 'Publisher',
                          hintText: 'Publisher Name',
                          controller: controller.citationPublisherController,
                        ),
                        _buildAiCitationField(
                          label: 'Journal',
                          hintText: 'Journal Name',
                          controller: controller.citationJournalController,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Row 5: Volume | Pages
                      buildRow(
                        _buildAiCitationField(
                          label: 'Volume',
                          hintText: 'e.g. 12',
                          controller: controller.citationVolumeController,
                        ),
                        _buildAiCitationField(
                          label: 'Pages',
                          hintText: 'e.g. 45-67',
                          controller: controller.citationPagesController,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ready to process',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        controller.executeJobFlow();
                      },
                      icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      label: const Text(
                        'Process with AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiCitationTrustFooter(),
        const SizedBox(height: 24),
        _buildAiCitationInfoCards(),
      ],
    );
  }

  Widget _buildAiCitationField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiCitationStyleField(ToolExecutorController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Style',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedCitationStyle,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              items: ToolExecutorController.citationStyleOptions.map((style) {
                return DropdownMenuItem<String>(
                  value: style,
                  child: Text(style),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.setCitationStyle(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiCitationProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiCitationTrustFooter(),
        const SizedBox(height: 24),
        _buildAiCitationInfoCards(),
      ],
    );
  }

  Widget _buildAiCitationResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedCitationContent.isNotEmpty
        ? controller.generatedCitationContent
        : 'Smith, J. (2005). Artificial Intelligence in Education. Journal of Technology, 7(2), 25-40. [Online]. Available: https://...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Processed in ${controller.citationExecutionDuration}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CITATION (${controller.selectedCitationStyle.toUpperCase()})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      displayText,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  if (isWide) {
                    return Row(
                      children: [
                        OutlinedButton(
                          onPressed: controller.resetCitationGenerator,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another file',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: controller.downloadCitationTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: controller.copyCitationText,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Copy Citation',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.resetCitationGenerator,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Process another file',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: controller.downloadCitationTxt,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Download TXT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.copyCitationText,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Copy Citation',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiCitationTrustFooter(),
        const SizedBox(height: 24),
        _buildAiCitationInfoCards(),
      ],
    );
  }

  Widget _buildAiCitationTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAiCitationInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What AI Citation Generator does',
          content:
              'Generates accurately formatted academic citations in APA, MLA, Chicago, Harvard, IEEE, and BibTeX styles from your source details.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use AI Citation Generator',
          content:
              '1  Select your preferred citation style (e.g. APA, MLA)\n2  Enter the title, author(s), year, and other source details\n3  Click "Process with AI" to generate the complete citation',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about AI Citation Generator',
          content:
              'Your citations are created securely and ready to copy or download as TXT instantly for research papers, essays, and bibliographies.',
        ),
      ],
    );
  }

  // ==========================================
  // AI Flashcards Dedicated UI Suite
  // ==========================================

  Widget _buildAiFlashcardsView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAiFlashcardsHeader(),
        if (controller.isRunning) ...[
          _buildAiFlashcardsProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAiFlashcardsResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildAiFlashcardsInputCard(context, controller),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildAiFlashcardsSettingsCard(context, controller),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAiFlashcardsInputCard(context, controller),
                    const SizedBox(height: 16),
                    _buildAiFlashcardsSettingsCard(context, controller),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildAiFlashcardsTrustFooter(),
          const SizedBox(height: 24),
          _buildAiFlashcardsInfoCards(),
        ],
      ],
    );
  }

  Widget _buildAiFlashcardsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI Tool',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI Flashcard Generator — Create Study Cards From Any PDF or Document',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAiFlashcardsInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Tabs: File Upload | Link | Paste Text
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildFlashcardTabItem(
                  title: 'File Upload',
                  isSelected: controller.flashcardInputMode == 'file',
                  onTap: () => controller.setFlashcardInputMode('file'),
                ),
                _buildFlashcardTabItem(
                  title: 'Link',
                  isSelected: controller.flashcardInputMode == 'link',
                  onTap: () => controller.setFlashcardInputMode('link'),
                ),
                _buildFlashcardTabItem(
                  title: 'Paste Text',
                  isSelected: controller.flashcardInputMode == 'text',
                  onTap: () => controller.setFlashcardInputMode('text'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tab content
          if (controller.flashcardInputMode == 'file') ...[
            if (controller.selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF2563EB),
                        size: 24,
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${controller.selectedFile!.sizeKb.toStringAsFixed(2)} KB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: controller.clearSingleSelectedFile,
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => controller.pickFileFromDevice(false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF6366F1)),
                      SizedBox(height: 12),
                      Text(
                        'Click to browse or drop file here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supports PDF, DOCX, TXT, PPTX',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else if (controller.flashcardInputMode == 'link') ...[
            TextField(
              controller: controller.flashcardUrlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
                hintText: 'https://example.com/article-or-document',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
              onChanged: (_) => controller.update(),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.flashcardTextController,
                    minLines: 6,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Paste your study text, notes, or article content here...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => controller.update(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${controller.flashcardTextController.text.length} characters',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiFlashcardsSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    String readyDetail = 'No document selected';
    if (controller.flashcardInputMode == 'file') {
      readyDetail = controller.selectedFile?.name ?? 'No document selected';
    } else if (controller.flashcardInputMode == 'link') {
      readyDetail = controller.flashcardUrlController.text.trim().isNotEmpty
          ? controller.flashcardUrlController.text.trim()
          : 'Enter URL';
    } else {
      final text = controller.flashcardTextController.text.trim();
      readyDetail = text.isNotEmpty
          ? '${text.split(RegExp(r"\s+")).length} words'
          : 'Enter text';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Number of Flashcards: ${controller.flashcardsCount}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value: controller.flashcardsCount.toDouble().clamp(1.0, 30.0),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (val) {
                controller.setFlashcardsCount(val.round());
              },
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readyDetail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.executeJobFlow,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    label: const Text(
                      'Process with AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFlashcardsProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiFlashcardsTrustFooter(),
        const SizedBox(height: 24),
        _buildAiFlashcardsInfoCards(),
      ],
    );
  }

  Widget _buildAiFlashcardsResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedFlashcardsContent.isNotEmpty
        ? controller.generatedFlashcardsContent
        : 'Card 1:\nQ: What is the first step in setting up a WhatsApp Business Account?\nA: Create a Facebook Account\n\nCard 2:\nQ: After logging into Meta Business Suite, what should you do next?\nA: Select or create your Business Portfolio and complete business information.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.resetFlashcardGenerator,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Process another item',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: controller.downloadFlashcardsTxt,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Download TXT',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.copyFlashcardsText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Copy Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.resetFlashcardGenerator,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.downloadFlashcardsTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.copyFlashcardsText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Copy Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        _buildAiFlashcardsTrustFooter(),
        const SizedBox(height: 24),
        _buildAiFlashcardsInfoCards(),
      ],
    );
  }

  Widget _buildAiFlashcardsTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAiFlashcardsInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What AI Flashcard Generator does',
          content:
              'Transforms any document, presentation, notes, or article link into structured, question-and-answer study flashcards instantly.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use AI Flashcard Generator',
          content:
              '1  Upload your document, paste a link, or enter study text\n2  Choose your desired number of flashcards using the slider\n3  Click "Process with AI" to generate your study cards',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about AI Flashcard Generator',
          content:
              'Flashcards are generated for active recall and spaced repetition learning. You can copy the cards or download them as a TXT file anytime.',
        ),
      ],
    );
  }

  Widget _buildAiQuizView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAiQuizHeader(),
        if (controller.isRunning) ...[
          _buildAiQuizProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAiQuizResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildAiQuizInputCard(context, controller),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildAiQuizSettingsCard(context, controller),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAiQuizInputCard(context, controller),
                    const SizedBox(height: 16),
                    _buildAiQuizSettingsCard(context, controller),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildAiQuizTrustFooter(),
          const SizedBox(height: 24),
          _buildAiQuizInfoCards(),
        ],
      ],
    );
  }

  Widget _buildAiQuizHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI Tool',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI Quiz Generator — Create Quizzes from Any PDF, Document, or Text',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAiQuizInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Tabs: File Upload | Link | Paste Text
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildQuizTabItem(
                  title: 'File Upload',
                  isSelected: controller.quizInputMode == 'file',
                  onTap: () => controller.setQuizInputMode('file'),
                ),
                _buildQuizTabItem(
                  title: 'Link',
                  isSelected: controller.quizInputMode == 'link',
                  onTap: () => controller.setQuizInputMode('link'),
                ),
                _buildQuizTabItem(
                  title: 'Paste Text',
                  isSelected: controller.quizInputMode == 'text',
                  onTap: () => controller.setQuizInputMode('text'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Tab content
          if (controller.quizInputMode == 'file') ...[
            if (controller.selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFFEF4444),
                        size: 24,
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.selectedFile!.sizeKb > 1024
                                ? '${(controller.selectedFile!.sizeKb / 1024).toStringAsFixed(2)} MB'
                                : '${controller.selectedFile!.sizeKb.toStringAsFixed(2)} KB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: controller.clearSingleSelectedFile,
                      tooltip: 'Remove file',
                    ),
                  ],
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: () => controller.pickFileFromDevice(false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF6366F1)),
                      SizedBox(height: 12),
                      Text(
                        'Click to browse or drop file here',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supports PDF, DOCX, TXT, PPTX',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else if (controller.quizInputMode == 'link') ...[
            TextField(
              controller: controller.quizUrlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF64748B)),
                hintText: 'https://example.com/article-or-document',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                ),
              ),
              onChanged: (_) => controller.update(),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.quizTextController,
                    minLines: 6,
                    maxLines: 10,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Paste your quiz source material, notes, or document content here...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => controller.update(),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${controller.quizTextController.text.length} characters',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiQuizSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    String readyDetail = 'No document selected';
    if (controller.quizInputMode == 'file') {
      readyDetail = controller.selectedFile?.name ?? 'No document selected';
    } else if (controller.quizInputMode == 'link') {
      readyDetail = controller.quizUrlController.text.trim().isNotEmpty
          ? controller.quizUrlController.text.trim()
          : 'Enter URL';
    } else {
      final text = controller.quizTextController.text.trim();
      readyDetail = text.isNotEmpty
          ? '${text.split(RegExp(r"\s+")).length} words'
          : 'Enter text';
    }

    final difficultyItems = [
      {'value': 'easy', 'label': 'Easy'},
      {'value': 'medium', 'label': 'Medium'},
      {'value': 'hard', 'label': 'Hard'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Number of Questions: ${controller.quizCount}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6366F1),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 4,
            ),
            child: Slider(
              value: controller.quizCount.toDouble().clamp(1.0, 30.0),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (val) {
                controller.setQuizCount(val.round());
              },
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Difficulty',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: difficultyItems.any((item) => item['value'] == controller.quizDifficulty.toLowerCase())
                    ? controller.quizDifficulty.toLowerCase()
                    : 'medium',
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: difficultyItems.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label']!),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.setQuizDifficulty(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readyDetail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.executeJobFlow,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    label: const Text(
                      'Process with AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiQuizProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAiQuizTrustFooter(),
        const SizedBox(height: 24),
        _buildAiQuizInfoCards(),
      ],
    );
  }

  Widget _buildAiQuizResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedQuizContent.isNotEmpty
        ? controller.generatedQuizContent
        : "Question 1: In which year did the first episode of 'FOMBIEN B0)' air?\n\nOptions:\nA) 2018\nB) 2006\nC) 2009\nD) 2015\n\nCorrect Answer: B\nExplanation: The text mentions that the first episode of 'FOMBIEN B0)' aired in 2006.\n\n----------------------------\n\nQuestion 2: Which character is described as 'the best' by 'FOMBIEN B0)'?\n\nOptions:\nA) Agent Blue\nB) Captain Nova\nC) Dr. Sterling\nD) Commander Jax\n\nCorrect Answer: A\nExplanation: Agent Blue is highlighted throughout the text as the premier protagonist.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.resetQuizGenerator,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Process another item',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: controller.downloadQuizTxt,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Download TXT',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.copyQuizText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Copy Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.resetQuizGenerator,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.downloadQuizTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.copyQuizText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Copy Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        _buildAiQuizTrustFooter(),
        const SizedBox(height: 24),
        _buildAiQuizInfoCards(),
      ],
    );
  }

  Widget _buildAiQuizTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAiQuizInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What AI Quiz Generator does',
          content:
              'Transforms any document, presentation, notes, or article link into comprehensive multiple-choice quizzes and test preparation questions.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use AI Quiz Generator',
          content:
              '1  Upload your document, paste a link, or enter text\n2  Choose your desired number of questions and difficulty level\n3  Click "Process with AI" to generate your customized quiz',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about AI Quiz Generator',
          content:
              'Generated quizzes include full multiple-choice options (A-D), verified correct answers, and thorough explanations. You can copy the quiz or download it as a TXT file anytime.',
        ),
      ],
    );
  }

  Widget _buildChatWithPdfView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildChatWithPdfHeader(),
        if (controller.isRunning) ...[
          _buildChatWithPdfProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildChatWithPdfChatCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildChatWithPdfInputCard(context, controller),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildChatWithPdfSettingsCard(context, controller),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildChatWithPdfInputCard(context, controller),
                    const SizedBox(height: 16),
                    _buildChatWithPdfSettingsCard(context, controller),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildChatWithPdfTrustFooter(),
          const SizedBox(height: 24),
          _buildChatWithPdfInfoCards(),
        ],
      ],
    );
  }

  Widget _buildChatWithPdfHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'AI Tool',
            style: TextStyle(
              color: Color(0xFF4F46E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Free Chat with PDF Online — Ask Document Questions Now',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChatWithPdfInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: controller.selectedFile != null
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFEF4444),
                      size: 24,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.selectedFile!.sizeKb > 1024
                              ? '${(controller.selectedFile!.sizeKb / 1024).toStringAsFixed(2)} MB'
                              : '${controller.selectedFile!.sizeKb.toStringAsFixed(2)} KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    onPressed: controller.clearSingleSelectedFile,
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () => controller.pickFileFromDevice(false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF6366F1)),
                    SizedBox(height: 12),
                    Text(
                      'Click to browse or drop file here',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Supports PDF documents',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChatWithPdfSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final readyDetail = controller.selectedFile?.name ?? 'No document selected';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Your Question',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.chatPdfQuestionController,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'What is the main topic?',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
            ),
            onChanged: (_) => controller.update(),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readyDetail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.executeJobFlow,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    label: const Text(
                      'Process with AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatWithPdfProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildChatWithPdfTrustFooter(),
        const SizedBox(height: 24),
        _buildChatWithPdfInfoCards(),
      ],
    );
  }

  Widget _buildChatWithPdfChatCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final messages = controller.chatPdfMessages.isNotEmpty
        ? controller.chatPdfMessages
        : [
            {'role': 'user', 'text': 'what is the main topic ?'},
            {'role': 'assistant', 'text': 'The main topic of the given text is "Voter Information".'},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chat Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Chat with Document',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),

              // Messages list
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    for (var msg in messages) ...[
                      if (msg['role'] == 'user') ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4F46E5),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 520),
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: SelectableText(
                              msg['text'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                    if (controller.isChatPdfFollowUpLoading) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Analyzing document...',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Follow-up Input Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.chatPdfFollowUpController,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Ask a follow up question...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                              ),
                            ),
                            onSubmitted: (_) => controller.sendChatPdfFollowUp(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: controller.isChatPdfFollowUpLoading
                              ? null
                              : controller.sendChatPdfFollowUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF818CF8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Centered "Upload New Document" button
        Center(
          child: OutlinedButton(
            onPressed: controller.resetChatPdf,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Upload New Document',
              style: TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildChatWithPdfTrustFooter(),
        const SizedBox(height: 24),
        _buildChatWithPdfInfoCards(),
      ],
    );
  }

  Widget _buildChatWithPdfTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildChatWithPdfInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What Chat with PDF does',
          content:
              'Allows you to interactively converse with your PDF documents, query facts, extract citations, and find instant answers to specific questions.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use Chat with PDF',
          content:
              '1  Upload your PDF document\n2  Type your question or use the suggested query\n3  Click "Process with AI" to analyze and chat with your document',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about Chat with PDF',
          content:
              'You can ask multiple follow-up questions to explore deeper context or click "Upload New Document" to analyze another file anytime.',
        ),
      ],
    );
  }

  Widget _buildAtsScannerView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAtsScannerHeader(),
        if (controller.isRunning) ...[
          _buildAtsScannerProcessingCard(controller),
        ] else if (controller.currentStep == 'success') ...[
          _buildAtsScannerResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildAtsScannerInputCard(context, controller),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _buildAtsScannerSettingsCard(context, controller),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildAtsScannerInputCard(context, controller),
                    const SizedBox(height: 16),
                    _buildAtsScannerSettingsCard(context, controller),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildAtsScannerTrustFooter(),
          const SizedBox(height: 24),
          _buildAtsScannerInfoCards(),
        ],
      ],
    );
  }

  Widget _buildAtsScannerHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Free ATS Resume Scanner — Check Your Resume Score',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7A00),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              SizedBox(width: 5),
              Text(
                'Pro Feature',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAtsScannerInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: controller.selectedFile != null
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFEF4444),
                      size: 24,
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.selectedFile!.sizeKb > 1024
                              ? '${(controller.selectedFile!.sizeKb / 1024).toStringAsFixed(2)} MB'
                              : '${controller.selectedFile!.sizeKb.toStringAsFixed(2)} KB',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                    onPressed: controller.clearSingleSelectedFile,
                    tooltip: 'Remove file',
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () => controller.pickFileFromDevice(false),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF6366F1)),
                    SizedBox(height: 12),
                    Text(
                      'Click to browse or drop file here',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Supports PDF, DOCX',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAtsModeTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAtsScannerSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final readyDetail = controller.selectedFile?.name ?? 'No document selected';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mode Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildAtsModeTabItem(
                  title: 'Scan My Resume',
                  isSelected: controller.atsScanMode == 'scan',
                  onTap: () => controller.setAtsScanMode('scan'),
                ),
                _buildAtsModeTabItem(
                  title: 'Match to a Job',
                  isSelected: controller.atsScanMode == 'match',
                  onTap: () => controller.setAtsScanMode('match'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mode-specific content
          if (controller.atsScanMode == 'scan') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'Upload your resume to get a general analysis, including section checks, keyword extraction, and formatting feedback.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: controller.atsJobDescriptionController,
                    minLines: 4,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Paste target job description or requirements here...',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => controller.update(),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),

          // Ready Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readyDetail,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: controller.executeJobFlow,
                    icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    label: const Text(
                      'Process with AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtsScannerProcessingCard(ToolExecutorController controller) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            children: [
              const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Processing',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We're working on your file...",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: const Color(0xFFE2E8F0),
                  child: const LinearProgressIndicator(
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
              ),
              _buildProcessingWarningBanner(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildAtsScannerTrustFooter(),
        const SizedBox(height: 24),
        _buildAtsScannerInfoCards(),
      ],
    );
  }

  Widget _buildAtsScannerResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final displayText = controller.generatedAtsContent.isNotEmpty
        ? controller.generatedAtsContent
        : "ATS Score: 100/100\nAnalysis Mode: General Resume Scan\n\nSections Found:\nSummary, Experience, Education, Skills, Certifications, Contact, Languages, References\n\nMatched Keywords:\nSales Executive, Sales & Marketing Executive, Business Executive, Sales Promoter\n\nMissing Keywords:\nLogistics, Transportation, Supply Chain Management, Customer Relationship Management, Project Management, Accounting\n\nIssues Identified:\n- No quantified achievements found — add numbers/metrics (e.g. 'Increased sales by 30%')\n\nSuggestions & Recommendations:\n- Include specific achievements with numbers and metrics in the sales roles, such as 'Increased sales by 30%'\n- Highlight any relevant certifications or training related to logistics or transportation\n- Add a section on references if not already included";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            if (isWide) {
              return Row(
                children: [
                  OutlinedButton(
                    onPressed: controller.resetAtsScanner,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Process another item',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: controller.downloadAtsTxt,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Download TXT',
                      style: TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: controller.copyAtsText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Copy Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.resetAtsScanner,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Process another item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.downloadAtsTxt,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Download TXT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.copyAtsText,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Copy Text',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        _buildAtsScannerTrustFooter(),
        const SizedBox(height: 24),
        _buildAtsScannerInfoCards(),
      ],
    );
  }

  Widget _buildAtsScannerTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        SizedBox(width: 20),
        Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 15),
        SizedBox(width: 5),
        Text(
          'Secure server processing',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAtsScannerInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What ATS Resume Scanner does',
          content:
              'Evaluates your resume against modern Applicant Tracking System (ATS) parsing algorithms, checking structural sections, industry keywords, and formatting compliance.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use ATS Resume Scanner',
          content:
              '1  Upload your resume in PDF or DOCX format\n2  Select "Scan My Resume" for general audit or "Match to a Job" to compare against a specific job description\n3  Click "Process with AI" to view your ATS score and optimization tips',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about ATS Resume Scanner',
          content:
              'A score above 80 indicates high ATS pass rates. Adding concrete metrics and targeted keywords from the job description significantly improves interview callback rates.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Word & Character Counter Redesign Widgets
  // ---------------------------------------------------------------------------

  Widget _buildTextCounterView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildTextCounterHeader(controller),
        if (controller.isRunning) ...[
          _buildTextCounterProcessingCard(controller),
        ] else if (controller.currentStep == 'success' &&
            controller.generatedCounterContent.isNotEmpty) ...[
          _buildTextCounterResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildTextCounterSettingsCard(context, controller),
          const SizedBox(height: 16),
          _buildTextCounterTrustFooter(),
          const SizedBox(height: 20),
          _buildTextCounterInfoCards(controller),
        ],
      ],
    );
  }

  Widget _buildTextCounterHeader(ToolExecutorController controller) {
    return const SizedBox(height: 8);
  }

  Widget _buildTextCounterSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              // Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              // Text(
              //   'Settings',
              //   style: TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.w700,
              //     color: Color(0xFF0F172A),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Text to Analyze',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
            ),
            child: TextField(
              controller: controller.counterTextController,
              maxLines: 9,
              minLines: 6,
              onChanged: (_) => controller.update(),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText:
                    'The citation you shared appears to be a general or placeholder reference, but you can read actual open-access studies like the CIDDL Report on AI in Education to learn about this topic.',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text(
                  'Ready to process',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (controller.counterTextController.text.trim().isEmpty) {
                      Get.rawSnackbar(
                        messageText: const Text(
                          'Please enter or paste text to analyze.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Colors.orange,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 8,
                      );
                      return;
                    }
                    controller.executeJobFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      // Icon(Icons.auto_awesome, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Process',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCounterProcessingCard(ToolExecutorController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6366F1),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Processing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We're analyzing your text...",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              color: Color(0xFF6366F1),
              backgroundColor: Color(0xFFF1F5F9),
              minHeight: 6,
            ),
          ),
          _buildProcessingWarningBanner(),
        ],
      ),
    );
  }

  Widget _buildTextCounterResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Corrected Text',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  controller.generatedCounterContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => controller.resetCounter(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Process another item',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => controller.downloadCounterTxt(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Download TXT',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => controller.copyCounterText(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Copy Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTextCounterTrustFooter(),
        const SizedBox(height: 20),
        _buildTextCounterInfoCards(controller),
      ],
    );
  }

  Widget _buildTextCounterTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 24),
        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Secure server processing',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTextCounterInfoCards(ToolExecutorController controller) {
    final isChar = controller.getSlug() == 'character-counter';
    final toolName = isChar ? 'Character Counter' : 'Word Counter';

    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What $toolName does',
          content:
              'Counts words, characters (with and without spaces), sentences, paragraphs, and estimates reading time in real-time.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use $toolName',
          content:
              '1  Paste or type your text into the Text to Analyze box\n2  Click "Process" to evaluate\n3  View, copy, or download the comprehensive text statistics instantly',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about $toolName',
          content:
              'Standard reading speed is calculated at 200 words per minute. Character counts help ensure your copy stays within platform limits for social posts, SMS, meta descriptions, and essays.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Image to Base64 Redesign Widgets
  // ---------------------------------------------------------------------------

  Widget _buildImageToBase64View(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final isDone = controller.currentStep == 'success' &&
        controller.imageBase64String.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.isRunning) ...[
          _buildImageToBase64ProcessingCard(controller),
        ] else if (isDone) ...[
          _buildImageToBase64ResultView(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildImageToBase64InputCard(context, controller),
          const SizedBox(height: 16),
          _buildImageToBase64TrustFooter(),
          const SizedBox(height: 20),
          _buildImageToBase64InfoCards(),
        ],
      ],
    );
  }

  

  Widget _buildImageToBase64InputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Image',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          _buildImageToBase64Dropzone(context, controller),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.selectedFile != null
                        ? 'Ready: ${controller.selectedFile!.name}'
                        : 'Ready to process',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (controller.selectedFile == null) {
                      Get.rawSnackbar(
                        messageText: const Text(
                          'Please select an image file first.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Colors.orange,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 8,
                      );
                      return;
                    }
                    controller.executeJobFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                     
                      Text(
                        'Process',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageToBase64Dropzone(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    if (controller.selectedFile != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image_outlined,
                color: Color(0xFF4F46E5),
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.selectedFile!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${controller.selectedFile!.sizeKb.toStringAsFixed(2)} KB',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                controller.clearSingleSelectedFile();
              },
              icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 20),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => controller.pickFileFromDevice(false),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.cloud_upload_outlined,
              size: 38,
              color: Color(0xFF6366F1),
            ),
            SizedBox(height: 12),
            Text(
              'Tap to browse or choose image',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Supports PNG, JPG, WEBP, GIF, SVG',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageToBase64ProcessingCard(ToolExecutorController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6366F1),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Processing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Converting image to Base64...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              color: Color(0xFF6366F1),
              backgroundColor: Color(0xFFF1F5F9),
              minHeight: 6,
            ),
          ),
          _buildProcessingWarningBanner(),
        ],
      ),
    );
  }

  Widget _buildImageToBase64ResultView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Base64SnippetCardWidget(
          title: 'Base64 String',
          content: controller.imageBase64String,
          onCopy: () => controller.copyBase64Snippet(
            'Base64 String',
            controller.imageBase64String,
          ),
          onShare: () => controller.shareBase64Snippet(
            'Base64 String',
            controller.imageBase64String,
          ),
        ),
        const SizedBox(height: 16),
        _Base64SnippetCardWidget(
          title: 'HTML Usage',
          content: controller.getHtmlUsageSnippet(),
          onCopy: () => controller.copyBase64Snippet(
            'HTML Usage',
            controller.getHtmlUsageSnippet(),
          ),
          onShare: () => controller.shareBase64Snippet(
            'HTML Usage',
            controller.getHtmlUsageSnippet(),
          ),
        ),
        const SizedBox(height: 16),
        _Base64SnippetCardWidget(
          title: 'CSS Usage',
          content: controller.getCssUsageSnippet(),
          onCopy: () => controller.copyBase64Snippet(
            'CSS Usage',
            controller.getCssUsageSnippet(),
          ),
          onShare: () => controller.shareBase64Snippet(
            'CSS Usage',
            controller.getCssUsageSnippet(),
          ),
        ),
        const SizedBox(height: 16),
        _Base64SnippetCardWidget(
          title: 'Markdown Usage',
          content: controller.getMarkdownUsageSnippet(),
          onCopy: () => controller.copyBase64Snippet(
            'Markdown Usage',
            controller.getMarkdownUsageSnippet(),
          ),
          onShare: () => controller.shareBase64Snippet(
            'Markdown Usage',
            controller.getMarkdownUsageSnippet(),
          ),
        ),
        const SizedBox(height: 16),
        _Base64SnippetCardWidget(
          title: 'JSON Usage',
          content: controller.getJsonUsageSnippet(),
          onCopy: () => controller.copyBase64Snippet(
            'JSON Usage',
            controller.getJsonUsageSnippet(),
          ),
          onShare: () => controller.shareBase64Snippet(
            'JSON Usage',
            controller.getJsonUsageSnippet(),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => controller.resetImageToBase64(),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Process another item',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.downloadBase64Txt(),
                  icon: const Icon(Icons.download_outlined, size: 16, color: Color(0xFF334155)),
                  label: const Text(
                    'Download TXT',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => controller.shareBase64Snippet('Base64 String', controller.imageBase64String),
                  icon: const Icon(Icons.share, size: 16, color: Colors.white),
                  label: const Text(
                    'Share Base64',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageToBase64TrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 24),
        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Secure server processing',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImageToBase64InfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What Image to Base64 does',
          content:
              'Converts any uploaded image into a standard Base64 data string and provides copy-ready integration code for HTML, CSS, Markdown, and JSON.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use Image to Base64',
          content:
              '1  Upload an image in PNG, JPG, WEBP, GIF, or SVG format\n2  Click "Process"\n3  Copy the Base64 string or the specific code snippet for your project',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about Image to Base64',
          content:
              'Base64 strings allow you to embed images directly into code without hosting them as separate external files. Ideal for small icons, offline assets, and email templates.',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Base64 to Image Redesign Widgets
  // ---------------------------------------------------------------------------

  Widget _buildBase64ToImageView(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final isDone = controller.currentStep == 'success';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildBase64ToImageHeader(),
        const SizedBox(height: 20),
        if (controller.isRunning) ...[
          _buildBase64ToImageProcessingCard(controller),
        ] else if (isDone) ...[
          _buildBase64ToImageResultCard(context, controller),
        ] else ...[
          if (controller.currentStep == 'error') ...[
            _buildErrorCard(controller),
            const SizedBox(height: 16),
          ],
          _buildBase64ToImageSettingsCard(context, controller),
          const SizedBox(height: 16),
          _buildBase64ToImageTrustFooter(),
          const SizedBox(height: 20),
          _buildBase64ToImageInfoCards(),
        ],
      ],
    );
  }

  Widget _buildBase64ToImageHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Utility Tool',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Free Base64 to Image — Convert Base64 Strings Instantly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64ToImageSettingsCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final previewBytes = controller.getDecodedImageBytes();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 18),
              SizedBox(width: 8),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Base64 String',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
            ),
            child: TextField(
              controller: controller.base64InputController,
              maxLines: 6,
              minLines: 4,
              onChanged: (_) => controller.update(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: 'Paste data:image/...;base64,... or raw Base64 string here',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Image Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            alignment: Alignment.center,
            child: previewBytes != null && previewBytes.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      previewBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPreviewPlaceholder(),
                    ),
                  )
                : _buildPreviewPlaceholder(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text(
                  'Ready to process',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    final raw = controller.base64InputController.text.trim();
                    if (raw.isEmpty) {
                      Get.rawSnackbar(
                        messageText: const Text(
                          'Please enter or paste a Base64 string.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Colors.orange,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 8,
                      );
                      return;
                    }
                    if (controller.getDecodedImageBytes() == null) {
                      Get.rawSnackbar(
                        messageText: const Text(
                          'Invalid Base64 string format.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: Colors.red,
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(16),
                        borderRadius: 8,
                      );
                      return;
                    }
                    controller.executeJobFlow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Process',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFF94A3B8),
        ),
        SizedBox(height: 8),
        Text(
          'Paste a valid Base64 string above to see image preview',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBase64ToImageProcessingCard(ToolExecutorController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6366F1),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          const Text(
            'Processing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Converting Base64 string to image...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              color: Color(0xFF6366F1),
              backgroundColor: Color(0xFFF1F5F9),
              minHeight: 6,
            ),
          ),
          _buildProcessingWarningBanner(),
        ],
      ),
    );
  }

  Widget _buildBase64ToImageResultCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 52,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(height: 14),
              const Text(
                'Complete!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Processed in ${controller.base64ProcessingTime}s',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.downloadBase64Image(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.file_download_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Download',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => controller.resetBase64ToImage(),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Process another file',
            style: TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildBase64ToImageTrustFooter(),
        const SizedBox(height: 20),
        _buildBase64ToImageInfoCards(),
      ],
    );
  }

  Widget _buildBase64ToImageTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Auto-delete in 24 hours',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 24),
        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF64748B)),
        SizedBox(width: 6),
        Text(
          'Secure server processing',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBase64ToImageInfoCards() {
    return Column(
      children: [
        _buildAiEmailInfoCard(
          title: 'What Base64 to Image does',
          content:
              'Decodes Base64 data strings (with or without data URI prefix) into high-resolution image files (PNG/JPG) with real-time visual preview.',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'How to use Base64 to Image',
          content:
              '1  Paste your Base64 encoded string into the input box\n2  Verify the visual rendering in the Image Preview area\n3  Click "Process" and download the decoded image file',
        ),
        const SizedBox(height: 12),
        _buildAiEmailInfoCard(
          title: 'Good to know about Base64 to Image',
          content:
              'Supports PNG, JPG, GIF, WEBP, and SVG formats. Leading data URI headers such as "data:image/png;base64," are automatically handled and stripped during conversion.',
        ),
      ],
    );
  }

  Widget _buildCitationInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.format_quote_outlined,
                    color: Color(0xFF7C3AED),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Citation Generator',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Format bibliography citations from source information.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.citationSourceController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Source Information *',
                hintText: 'Author, title, publication year, publisher, DOI or URL...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Citation Style',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip(
                  label: 'APA',
                  isSelected: controller.citationStyle == 'APA',
                  onTap: () => controller.setCitationStyle('APA'),
                ),
                const SizedBox(width: 8),
                _buildChoiceChip(
                  label: 'MLA',
                  isSelected: controller.citationStyle == 'MLA',
                  onTap: () => controller.setCitationStyle('MLA'),
                ),
                const SizedBox(width: 8),
                _buildChoiceChip(
                  label: 'Chicago',
                  isSelected: controller.citationStyle == 'Chicago',
                  onTap: () => controller.setCitationStyle('Chicago'),
                ),
                const SizedBox(width: 8),
                _buildChoiceChip(
                  label: 'Harvard',
                  isSelected: controller.citationStyle == 'Harvard',
                  onTap: () => controller.setCitationStyle('Harvard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextCounterInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
    final text = controller.counterTextController.text;
    final words = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    final characters = text.length;
    final charactersNoSpaces = text.replaceAll(RegExp(r'\s+'), '').length;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pin_outlined,
                    color: Color(0xFF475569),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.getSlug() == 'character-counter' ? 'Character Counter' : 'Word Counter',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Count words, characters, and sentences in your text.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.counterTextController,
              maxLines: 5,
              onChanged: (_) => controller.update(),
              decoration: InputDecoration(
                labelText: 'Input Text *',
                hintText: 'Type or paste your text here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('$words', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        const Text('Words', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('$characters', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        const Text('Characters', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('$charactersNoSpaces', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        const Text('No Spaces', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                      ],
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

  Widget _buildBase64ToImageInputCard(
    BuildContext context,
    ToolExecutorController controller,
  ) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Base64 to Image',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Convert a Base64 encoded string into a downloadable image.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.base64InputController,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: InputDecoration(
                labelText: 'Base64 Encoded String *',
                hintText: 'Paste data:image/png;base64,... or raw Base64...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSelectionCard(
    BuildContext context,
    ToolExecutorController controller,
    bool isMulti,
  ) {
    if (controller.isNoUploadTool()) {
      final slug = controller.getSlug();
      if (slug == 'id-templates' || slug == 'id-certificate-templates' || slug == 'id-generator') {
        return _buildIdTemplatesInputCard(context, controller);
      } else if (slug == 'invoice-generator') {
        return _buildInvoiceGeneratorInputCard(context, controller);
      } else if (slug == 'ai-email-writer') {
        return _buildEmailWriterInputCard(context, controller);
      } else if (slug == 'ai-citation') {
        return _buildCitationInputCard(context, controller);
      } else if (slug == 'word-counter' || slug == 'character-counter') {
        return _buildTextCounterInputCard(context, controller);
      } else if (slug == 'base64-to-image') {
        return _buildBase64ToImageInputCard(context, controller);
      } else {
        return _buildHtmlToPdfInputCard(context, controller);
      }
    }
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
              color: _getFileColor(controller.selectedFile!.fileType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(controller.selectedFile!.fileType),
              color: _getFileColor(controller.selectedFile!.fileType),
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
                Row(
                  children: [
                    Text(
                      '${controller.selectedFile!.fileType} • ${(controller.selectedFile!.sizeKb / 1024).toStringAsFixed(1)} MB',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    if (controller.isPdfLocked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 10, color: Color(0xFFEF4444)),
                            SizedBox(width: 3),
                            Text(
                              'Locked PDF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
                  _getFileIcon(file.fileType),
                  color: _getFileColor(file.fileType),
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
        SizedBox(
          width: double.infinity,
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
            'Upload a file from your device.',
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
              icon: const Icon(Icons.phone_android, size: 15),
              label: const Text(
                'Device Upload',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showScansSelectorBottomSheet(
  //   BuildContext context,
  //   ToolExecutorController controller,
  //   bool isMulti,
  // ) {
  //   Get.bottomSheet(
  //     Container(
  //       padding: const EdgeInsets.all(20),
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               const Text(
  //                 'Select from Scans',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                   color: AppColors.text,
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () => Get.back(),
  //                 child: const Text(
  //                   'Done',
  //                   style: TextStyle(fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //           ConstrainedBox(
  //             constraints: BoxConstraints(
  //               maxHeight: MediaQuery.of(context).size.height * 0.45,
  //             ),
  //             child: controller.scanController.scannedFiles.isEmpty
  //                 ? const Center(
  //                     child: Padding(
  //                       padding: EdgeInsets.symmetric(vertical: 24.0),
  //                       child: Text('No scanned files found.'),
  //                     ),
  //                   )
  //                 : Obx(
  //                     () => ListView.builder(
  //                       shrinkWrap: true,
  //                       itemCount:
  //                           controller.scanController.scannedFiles.length,
  //                       itemBuilder: (context, index) {
  //                         final file =
  //                             controller.scanController.scannedFiles[index];
  //                         if (isMulti) {
  //                           final isSelected = controller.selectedFiles.any(
  //                             (f) => f.id == file.id,
  //                           );
  //                           return CheckboxListTile(
  //                             value: isSelected,
  //                             title: Text(
  //                               file.name,
  //                               style: const TextStyle(
  //                                 fontSize: 13,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                             subtitle: Text(
  //                               '${file.fileType} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
  //                               style: const TextStyle(fontSize: 11),
  //                             ),
  //                             activeColor: AppColors.primary,
  //                             onChanged: (val) {
  //                               controller.toggleSelectedFileFromScans(
  //                                 file,
  //                                 val,
  //                               );
  //                             },
  //                           );
  //                         } else {
  //                           return ListTile(
  //                             leading: Icon(
  //                               file.fileType == 'PDF'
  //                                   ? Icons.picture_as_pdf
  //                                   : Icons.image,
  //                               color: file.fileType == 'PDF'
  //                                   ? AppColors.coral
  //                                   : AppColors.blue,
  //                             ),
  //                             title: Text(
  //                               file.name,
  //                               style: const TextStyle(
  //                                 fontSize: 13,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //                             subtitle: Text(
  //                               '${file.fileType} • ${(file.sizeKb / 1024).toStringAsFixed(1)} MB',
  //                               style: const TextStyle(fontSize: 11),
  //                             ),
  //                             onTap: () {
  //                               controller.selectSingleFileFromScans(file);
  //                             },
  //                           );
  //                         }
  //                       },
  //                     ),
  //                   ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     isScrollControlled: true,
  //   );
  // }

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
              obscureText: !controller.isLockPasswordVisible,
              decoration: InputDecoration(
                labelText: 'User Password',
                hintText: 'Enter password to encrypt PDF',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isLockPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: controller.toggleLockPasswordVisibility,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.ownerPasswordController,
              obscureText: !controller.isOwnerPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Owner/Admin Password (Optional)',
                hintText: 'Enter admin permissions password',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isOwnerPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: controller.toggleOwnerPasswordVisibility,
                ),
                border: const OutlineInputBorder(),
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
        final hasFile = controller.selectedFile != null;
        final isLocked = controller.isPdfLocked;

        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                    : hasFile
                        ? const Color(0xFF10B981).withValues(alpha: 0.08)
                        : const Color(0xFF6366F1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                      : hasFile
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFF6366F1).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLocked
                        ? Icons.lock
                        : hasFile
                            ? Icons.check_circle_outline
                            : Icons.lock_open_outlined,
                    color: isLocked
                        ? const Color(0xFFEF4444)
                        : hasFile
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6366F1),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLocked
                              ? 'Password-Protected PDF Recognized'
                              : hasFile
                                  ? 'PDF is Not Locked (No Password Required)'
                                  : 'PDF Unlock & Decryption',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isLocked
                                ? const Color(0xFFB91C1C)
                                : hasFile
                                    ? const Color(0xFF047857)
                                    : const Color(0xFF4338CA),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isLocked
                              ? 'This document is encrypted. Enter the correct password below to unlock and remove security restrictions.'
                              : hasFile
                                  ? 'This file is already unlocked and does not require password removal. You can open and edit it freely without unlocking.'
                                  : 'Upload a password-protected PDF file to check its security status and remove encryption.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isLocked
                                ? const Color(0xFF7F1D1D)
                                : hasFile
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF3730A3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLocked && hasFile) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: This document has no password protection. Unlocking is not needed.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (hasFile && isLocked) ...[
              const SizedBox(height: 14),
              const Text(
                'Enter Document Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.passwordController,
                obscureText: !controller.isUnlockPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password to unlock',
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isUnlockPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: controller.toggleUnlockPasswordVisibility,
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
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
              enabled: !controller.isRunning,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'John Doe — Signed via Plainscan',
              ),
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
                DropdownMenuItem(value: 'jpg', child: Text('JPG Image (.jpg)')),
                DropdownMenuItem(value: 'png', child: Text('PNG Image (.png)')),
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

      case 'images-to-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Images Compilation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'Selected ${controller.selectedFiles.length} image(s) will be converted and combined into a single formatted PDF document in the sequence shown above.',
              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'convert-image':
      case 'tiff-conversion':
      case 'heic-to-jpg':
      case 'heic-to-png':
        final isFixedJpg = slug == 'heic-to-jpg';
        final isFixedPng = slug == 'heic-to-png';
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFixedJpg && !isFixedPng) ...[
              const Text(
                'Target Image Format',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: controller.convertImageTargetFormat,
                items: const [
                  DropdownMenuItem(value: 'jpg', child: Text('JPG (.jpg)')),
                  DropdownMenuItem(value: 'png', child: Text('PNG (.png)')),
                ],
                onChanged: (val) {
                  if (val != null) controller.setConvertImageTargetFormat(val);
                },
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Output Quality',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${controller.convertImageQuality}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: controller.convertImageQuality.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              label: '${controller.convertImageQuality}%',
              activeColor: AppColors.primary,
              onChanged: (val) => controller.setConvertImageQuality(val.toInt()),
            ),
          ],
        );
        break;

      case 'bank-statement-to-excel':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Financial Table Parser',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'AI automatically identifies transactions, transaction dates, descriptions, credits, debits, and balance records from your bank statement PDF and exports them into clean Microsoft Excel (.xlsx) columns.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'receipt-to-excel':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
                SizedBox(width: 8),
                Text(
                  'AI Receipt & Invoice Parser',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Extracts vendor name, transaction date, invoice numbers, tax lines, itemized totals, and payment methods from receipt scans or PDFs into an organized Excel spreadsheet.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'csv-to-excel':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV Delimiter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.csvDelimiter,
              items: const [
                DropdownMenuItem(value: ',', child: Text('Comma (,) — Standard')),
                DropdownMenuItem(value: ';', child: Text('Semicolon (;) — European')),
                DropdownMenuItem(value: '\t', child: Text('Tab (\\t) — TSV')),
                DropdownMenuItem(value: '|', child: Text('Pipe (|)')),
              ],
              onChanged: (val) {
                if (val != null) controller.setCsvDelimiter(val);
              },
            ),
          ],
        );
        break;

      case 'excel-to-csv':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Excel Sheet Selection',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: controller.excelSheetIndex > 0
                      ? () => controller.decrementExcelSheetIndex()
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sheet ${controller.excelSheetIndex + 1} (Index ${controller.excelSheetIndex})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => controller.incrementExcelSheetIndex(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Index 0 extracts the first sheet in your Excel workbook.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
          ],
        );
        break;

      case 'flatten-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.layers_clear_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Flatten Form Fields & Annotations',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Flattens all interactive form fields, checkboxes, and annotations into static PDF layers. The resulting document is read-only and cannot be altered or filled again.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'n-up-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages Per Sheet (N-Up)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: controller.nUpPages,
              items: const [
                DropdownMenuItem(value: 2, child: Text('2 Pages per sheet')),
                DropdownMenuItem(value: 4, child: Text('4 Pages per sheet')),
                DropdownMenuItem(value: 6, child: Text('6 Pages per sheet')),
                DropdownMenuItem(value: 9, child: Text('9 Pages per sheet')),
              ],
              onChanged: (val) {
                if (val != null) controller.setNUpPages(val);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Sheet Orientation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.nUpOrientation,
              items: const [
                DropdownMenuItem(value: 'portrait', child: Text('Portrait')),
                DropdownMenuItem(value: 'landscape', child: Text('Landscape')),
              ],
              onChanged: (val) {
                if (val != null) controller.setNUpOrientation(val);
              },
            ),
          ],
        );
        break;

      case 'pdf-to-grayscale':
      case 'grayscale-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.filter_b_and_w_outlined, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Black & White / Grayscale Conversion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Converts all colored text, vector artwork, and embedded images in the PDF into monochromatic grayscale to save color printer ink and reduce file size.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'print-optimize-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optimization Preset',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: controller.printOptType,
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Standard Print (Recommended)')),
                DropdownMenuItem(value: 'screen', child: Text('Screen (Low Resolution)')),
                DropdownMenuItem(value: 'printer', child: Text('Office Printer (Medium Resolution)')),
                DropdownMenuItem(value: 'prepress', child: Text('Prepress (High Resolution Commercial)')),
              ],
              onChanged: (val) {
                if (val != null) controller.setPrintOptType(val);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resolution (DPI)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${controller.printOptDpi} DPI',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: controller.printOptDpi.toDouble(),
              min: 72,
              max: 600,
              divisions: 22,
              label: '${controller.printOptDpi} DPI',
              activeColor: AppColors.primary,
              onChanged: (val) => controller.setPrintOptDpi(val.toInt()),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Image Compression Quality',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${controller.printOptQuality}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: controller.printOptQuality.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              label: '${controller.printOptQuality}%',
              activeColor: AppColors.primary,
              onChanged: (val) => controller.setPrintOptQuality(val.toInt()),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Convert to Grayscale for Print',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Save color ink during printing.',
                style: TextStyle(fontSize: 11),
              ),
              value: controller.printOptGrayscale,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => controller.togglePrintOptGrayscale(val),
            ),
          ],
        );
        break;

      case 'repair-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.build_circle_outlined, color: Color(0xFF0284C7), size: 18),
                SizedBox(width: 8),
                Text(
                  'PDF Structure Recovery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Analyzes damaged or unreadable PDF files, repairs damaged headers, rebuilds corrupted cross-reference (xref) tables, and recovers valid page contents.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'crop-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Margins (in points)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Top', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${controller.cropTop} pt', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: controller.cropTop.toDouble(),
                        min: 0,
                        max: 200,
                        divisions: 40,
                        activeColor: AppColors.primary,
                        onChanged: (v) => controller.setCropTop(v.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bottom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${controller.cropBottom} pt', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: controller.cropBottom.toDouble(),
                        min: 0,
                        max: 200,
                        divisions: 40,
                        activeColor: AppColors.primary,
                        onChanged: (v) => controller.setCropBottom(v.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Left', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${controller.cropLeft} pt', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: controller.cropLeft.toDouble(),
                        min: 0,
                        max: 200,
                        divisions: 40,
                        activeColor: AppColors.primary,
                        onChanged: (v) => controller.setCropLeft(v.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Right', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${controller.cropRight} pt', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: controller.cropRight.toDouble(),
                        min: 0,
                        max: 200,
                        divisions: 40,
                        activeColor: AppColors.primary,
                        onChanged: (v) => controller.setCropRight(v.toInt()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
        break;

      case 'id-templates':
      case 'id-certificate-templates':
      case 'id-generator':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Identity Document Ready',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              'All employee and company details entered above will be rendered into an official printable ID card format.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'invoice-generator':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Invoice Layout & Template',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              'Line items, taxes, discounts, and billing addresses entered above will be rendered into a clean, professional invoice PDF.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'ai-flashcards':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of Flashcards',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${controller.flashcardsCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: controller.flashcardsCount.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: '${controller.flashcardsCount}',
              activeColor: AppColors.primary,
              onChanged: (v) => controller.setFlashcardsCount(v.toInt()),
            ),
          ],
        );
        break;

      case 'ai-quiz':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of Questions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '${controller.quizCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            Slider(
              value: controller.quizCount.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: '${controller.quizCount}',
              activeColor: AppColors.primary,
              onChanged: (v) => controller.setQuizCount(v.toInt()),
            ),
            const SizedBox(height: 12),
            const Text(
              'Difficulty Level',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.quizDifficulty,
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Easy')),
                DropdownMenuItem(value: 'medium', child: Text('Medium (Recommended)')),
                DropdownMenuItem(value: 'hard', child: Text('Hard')),
              ],
              onChanged: (v) {
                if (v != null) controller.setQuizDifficulty(v);
              },
            ),
          ],
        );
        break;

      case 'chat-with-pdf':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question for PDF *',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.chatPdfQuestionController,
              decoration: InputDecoration(
                hintText: 'e.g. What is the main summary of this document?',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Prompts:',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Summarize Document', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.chatPdfQuestionController.text = 'Summarize this document in 3 paragraphs.';
                    controller.update();
                  },
                ),
                ActionChip(
                  label: const Text('Key Action Items', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.chatPdfQuestionController.text = 'Extract all key action items, deadlines, and dates.';
                    controller.update();
                  },
                ),
                ActionChip(
                  label: const Text('Main Takeaways', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    controller.chatPdfQuestionController.text = 'List the top 5 most important takeaways.';
                    controller.update();
                  },
                ),
              ],
            ),
          ],
        );
        break;

      case 'ats-scanner':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Description (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Paste a target job posting to compute keyword match score and skill gaps.',
              style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.atsJobDescriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Paste job requirements, required skills, and qualifications here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        );
        break;

      case 'metadata-editor':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Strip All Metadata (Privacy Mode)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Remove all EXIF tags including GPS and camera info.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: controller.metadataStripAll,
                    activeColor: AppColors.primary,
                    onChanged: (v) => controller.setMetadataStripAll(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or Edit Specific Fields:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            AbsorbPointer(
              absorbing: controller.metadataStripAll,
              child: Opacity(
                opacity: controller.metadataStripAll ? 0.45 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Title',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: controller.metadataTitleController,
                                enabled: !controller.metadataStripAll,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Vacation Photo',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Author',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: controller.metadataAuthorController,
                                enabled: !controller.metadataStripAll,
                                decoration: InputDecoration(
                                  hintText: 'e.g. John Doe',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.metadataDescriptionController,
                      enabled: !controller.metadataStripAll,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'A detailed description...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Copyright',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: controller.metadataCopyrightController,
                                enabled: !controller.metadataStripAll,
                                decoration: InputDecoration(
                                  hintText: 'e.g. © 2025 John Doe',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Software',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: controller.metadataSoftwareController,
                                enabled: !controller.metadataStripAll,
                                decoration: InputDecoration(
                                  hintText: 'e.g. Plainscan',
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Comment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: controller.metadataCommentController,
                      enabled: !controller.metadataStripAll,
                      decoration: InputDecoration(
                        hintText: 'Any custom comments...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
        break;

      case 'remove-metadata':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.phonelink_erase_outlined, color: AppColors.coral, size: 18),
                SizedBox(width: 8),
                Text(
                  'Permanent Metadata Stripping',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Removes author names, location coordinates (GPS), camera make & model, editing software history, and hidden tags from your document or photo for maximum privacy.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'read-metadata':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Metadata Inspection',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Reads and extracts all embedded metadata properties, EXIF tags, creation timestamps, DPI resolution, color profiles, and document structure into structured JSON.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'favicon-generator':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.web_outlined, color: Color(0xFFD97706), size: 18),
                SizedBox(width: 8),
                Text(
                  'Multi-Size Favicon Generation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Converts your square PNG or JPG logo into optimized web favicon assets (16x16, 32x32, 48x48) in standard .ico format ready for websites and web apps.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
            ),
          ],
        );
        break;

      case 'image-to-base64':
        child = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.data_object_outlined, color: Color(0xFF059669), size: 18),
                SizedBox(width: 8),
                Text(
                  'Base64 Data URI Conversion',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Encodes your image file directly into a clean Base64 data string suitable for embedding into HTML, CSS, or JSON payloads.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText, height: 1.4),
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

  Widget _buildProcessingWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: 'Warning: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'Please do not close the app or switch to another app until processing is complete, as doing so may cause the process to fail.',
                  ),
                ],
              ),
            ),
          ),
        ],
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
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: c,
                  fontSize: 13,
                ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Executing Job Flow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline, size: 12, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Text(
                        'Options locked during processing',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            if (controller.errorMessage.isNotEmpty) ...[
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
            _buildProcessingWarningBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataResultCard(BuildContext context, ToolExecutorController controller) {
    final metaMap = controller.extractedMetadataMap ?? {};
    final metaDict = (metaMap['metadata'] as Map<String, dynamic>?) ?? {};
    final isPdf = metaMap['format'] == 'PDF Document';

    Widget buildMetaRow(String label, dynamic value, {IconData? icon}) {
      if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: const Color(0xFF64748B)),
              const SizedBox(width: 8),
            ],
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              child: SelectableText(
                value.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Document Metadata Extracted',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${metaMap['file_name'] ?? 'Document'} • ${metaMap['format'] ?? 'PDF'}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF0284C7)),
                  tooltip: 'Copy Text Metadata',
                  onPressed: controller.copyMetadataText,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Size: ${metaMap['file_size_kb'] ?? 0} KB',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
                if (isPdf && metaMap['pdf_version'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      '${metaMap['pdf_version']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ),
                if (isPdf && metaMap['page_count'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Pages: ${metaMap['page_count']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF)),
                    ),
                  ),
                if (isPdf && metaMap['is_encrypted'] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Text(
                      'Encrypted / Protected',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            const Text(
              'Document Attributes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            buildMetaRow('Title', metaDict['Title'], icon: Icons.title),
            buildMetaRow('Author', metaDict['Author'], icon: Icons.person_outline),
            buildMetaRow('Subject', metaDict['Subject'], icon: Icons.subject),
            buildMetaRow('Keywords', metaDict['Keywords'], icon: Icons.tag),
            buildMetaRow('Creator Tool', metaDict['Creator'], icon: Icons.precision_manufacturing_outlined),
            buildMetaRow('PDF Producer', metaDict['Producer'], icon: Icons.settings_suggest_outlined),
            buildMetaRow('Creation Date', metaDict['CreationDate'], icon: Icons.calendar_today_outlined),
            buildMetaRow('Modified Date', metaDict['ModDate'], icon: Icons.edit_calendar_outlined),
            if (!isPdf) ...[
              buildMetaRow('Color Space', metaDict['ColorSpace'], icon: Icons.palette_outlined),
              buildMetaRow('X Resolution', metaDict['XResolution'], icon: Icons.aspect_ratio),
              buildMetaRow('Y Resolution', metaDict['YResolution'], icon: Icons.aspect_ratio),
              buildMetaRow('Exif Version', metaDict['ExifVersion'], icon: Icons.camera_alt_outlined),
              buildMetaRow('Software', metaDict['Software'], icon: Icons.computer_outlined),
            ],
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Metadata Report (TXT)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      InkWell(
                        onTap: controller.copyMetadataText,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Copy Text',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    controller.generatedMetadataText.isNotEmpty
                        ? controller.generatedMetadataText
                        : controller.generatedMetadataJson,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
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
    final isPasswordErr = controller.isPasswordError;
    final lowerErr = controller.errorMessage.toLowerCase();
    final isFileErr = lowerErr.contains('select') ||
        lowerErr.contains('upload') ||
        lowerErr.contains('no file') ||
        lowerErr.contains('please upload');

    final headerTitle = isFileErr
        ? 'No File Selected'
        : (isPasswordErr ? 'Invalid Password' : 'Execution Failed');
    final headerIcon = isFileErr
        ? Icons.upload_file_outlined
        : (isPasswordErr ? Icons.lock_outline : Icons.error_outline);
    final themeColor = isFileErr ? AppColors.coral : Colors.red.shade700;
    final bgColor = isFileErr ? const Color(0xFFFFF7ED) : Colors.red.shade50;
    final borderColor = isFileErr ? const Color(0xFFFFEDD5) : Colors.red.shade200;

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  headerIcon,
                  color: themeColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  headerTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isFileErr ? const Color(0xFF9A3412) : Colors.red.shade900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage,
              style: TextStyle(
                color: isFileErr ? const Color(0xFF7C2D12) : Colors.red.shade900,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (isFileErr) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => controller.pickFileFromDevice(controller.isMultiFileTool()),
                icon: const Icon(Icons.phone_android, size: 16, color: Colors.white),
                label: const Text(
                  'Upload File from Device',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ] else if (isPasswordErr) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Passwords are case-sensitive. Please ensure Caps Lock is off and re-enter.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.clearError,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                label: const Text(
                  'Try Another Password',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // void _showTokenSettingsDialog(
  //   BuildContext context,
  //   ToolExecutorController controller,
  // ) {
  //   final tokenInputController = TextEditingController();
  //   StorageService.getToken().then((token) {
  //     if (token != null) {
  //       tokenInputController.text = token;
  //     }
  //   });

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Access Token Settings'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Text(
  //               'Enter your Plainscan API/Access Token to authorize requests.',
  //               style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
  //             ),
  //             const SizedBox(height: 12),
  //             TextField(
  //               controller: tokenInputController,
  //               decoration: const InputDecoration(
  //                 labelText: 'Access Token',
  //                 border: OutlineInputBorder(),
  //                 focusedBorder: OutlineInputBorder(
  //                   borderSide: BorderSide(color: AppColors.primary),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Get.back(),
  //             child: const Text(
  //               'Cancel',
  //               style: TextStyle(color: AppColors.secondaryText),
  //             ),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final token = tokenInputController.text.trim();
  //               await controller.saveToken(token);
  //               Get.back();
  //               Get.rawSnackbar(
  //                 messageText: const Text(
  //                   'Access Token updated successfully!',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 backgroundColor: AppColors.primary,
  //                 snackPosition: SnackPosition.BOTTOM,
  //               );
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: AppColors.primary,
  //             ),
  //             child: const Text('Save', style: TextStyle(color: Colors.white)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
                              .withValues(alpha: 0.1),
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
                  child: ElevatedButton.icon(
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
                          controller.markFileDownloaded();
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final path = controller.convertedFile?.path;
                      final name = controller.convertedFile?.name ?? controller.outputFileName;
                      if (path != null && File(path).existsSync()) {
                        Share.shareXFiles(
                          [XFile(path)],
                          text: 'Sharing $name via PlainScan',
                        );
                      } else {
                        Share.share('PlainScan Document: $name');
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
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (controller.existingOriginalFile != null) ...[
              const SizedBox(height: 12),
              if (controller.isOriginalFileReplaced) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Replaced original "${controller.existingOriginalFile!.name}" in Files Manager.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Original "${controller.existingOriginalFile!.name}" preserved.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final path = controller.convertedFile?.path;
                          if (path != null) {
                            controller.replaceOriginalWithUpdated(
                              path,
                              controller.convertedFile!.name,
                              controller.convertedFile!.fileType,
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Replace Original',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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

class _Base64SnippetCardWidget extends StatefulWidget {
  final String title;
  final String content;
  final VoidCallback onCopy;
  final VoidCallback? onShare;

  const _Base64SnippetCardWidget({
    required this.title,
    required this.content,
    required this.onCopy,
    this.onShare,
  });

  @override
  State<_Base64SnippetCardWidget> createState() => _Base64SnippetCardWidgetState();
}

class _Base64SnippetCardWidgetState extends State<_Base64SnippetCardWidget> {
  late final ScrollController _scrollController;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleCopy() {
    widget.onCopy();
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  String get _displayContent {
    if (widget.content.length > 800) {
      return '${widget.content.substring(0, 800)}...\n\n[+${widget.content.length - 800} more characters — tap Copy or Share for complete data]';
    }
    return widget.content;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onShare != null) ...[
                    InkWell(
                      onTap: widget.onShare,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.share_outlined,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  InkWell(
                    onTap: _handleCopy,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _copied ? const Color(0xFFECFDF5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied ? Icons.check_circle : Icons.content_copy_outlined,
                            size: 14,
                            color: _copied ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _copied ? 'Copied!' : 'Copy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _copied ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _displayContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


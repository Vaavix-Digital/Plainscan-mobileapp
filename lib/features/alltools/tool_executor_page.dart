import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/constants/app_colors.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/features/home/widgets/dashboard_ad_banner.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';

class ToolExecutorPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (Get.isRegistered<ToolExecutorController>()) {
      Get.delete<ToolExecutorController>();
    }
    Get.put(ToolExecutorController(
      tool: tool,
      initialFiles: initialFiles,
      autoExecute: autoExecute,
    ));

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // File / Input Selection
                  _buildInputSelectionCard(context, controller, isMulti),
                  const SizedBox(height: 10),
                  
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

  Widget _buildEmailWriterInputCard(
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
                    Icons.email_outlined,
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
                        'AI Email Writer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Draft an email from subject, context, and desired tone.',
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
              controller: controller.emailSubjectController,
              decoration: InputDecoration(
                labelText: 'Email Subject *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.emailContextController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Context / Message Goal *',
                hintText: 'Brief description of what the email should say...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Writing Tone',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChoiceChip(
                  label: 'Professional',
                  icon: Icons.business_center_outlined,
                  isSelected: controller.emailTone == 'professional',
                  onTap: () => controller.setEmailTone('professional'),
                ),
                const SizedBox(width: 8),
                _buildChoiceChip(
                  label: 'Casual',
                  icon: Icons.chat_bubble_outline,
                  isSelected: controller.emailTone == 'casual',
                  onTap: () => controller.setEmailTone('casual'),
                ),
                const SizedBox(width: 8),
                _buildChoiceChip(
                  label: 'Friendly',
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  isSelected: controller.emailTone == 'friendly',
                  onTap: () => controller.setEmailTone('friendly'),
                ),
              ],
            ),
          ],
        ),
      ),
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
            // Expanded(
            //   child: OutlinedButton.icon(
            //     onPressed: () =>
            //         _showScansSelectorBottomSheet(context, controller, true),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: AppColors.primary,
            //       side: const BorderSide(color: AppColors.primary),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       padding: const EdgeInsets.symmetric(vertical: 10),
            //     ),
            //     icon: const Icon(Icons.folder_open, size: 14),
            //     label: const Text(
            //       'Add from Scans',
            //       style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            //     ),
            //   ),
            // ),
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
            const Text(
              'Metadata Operation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: controller.metadataAction,
              items: const [
                DropdownMenuItem(value: 'strip', child: Text('Strip / Remove Metadata')),
                DropdownMenuItem(value: 'view', child: Text('View / Inspect Metadata')),
              ],
              onChanged: (v) {
                if (v != null) controller.setMetadataAction(v);
              },
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

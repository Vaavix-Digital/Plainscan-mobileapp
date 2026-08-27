import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/models/tool_model.dart';

class AllToolsController extends GetxController {
  final searchController = TextEditingController();

  final searchText = ''.obs;
  final selectedFilter = 'All 49'.obs;

 final filters = [
  '▦ All 49',
  '⚡ Core',
  '☷ High-intent',
  '✎ PDF',
  '⌕ OCR',
  '✦ AI',
  '▧ Image',
];

 final tools = <ToolModel>[
  // ─────────────────────────
  // CORE DAILY DRIVERS
  // ─────────────────────────

  ToolModel(
    id: 'scan_ocr',
    name: 'Scan & OCR',
    icon: Icons.document_scanner_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'images_to_pdf',
    name: 'Images to PDF',
    icon: Icons.image_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'compress_image',
    name: 'Compress Image',
    icon: Icons.compress_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'compress_pdf',
    name: 'Compress PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'background_remover',
    name: 'Replace/Remove Background',
    icon: Icons.auto_awesome_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'passport_photo',
    name: 'Passport Photo',
    icon: Icons.badge_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'qr_generator',
    name: 'QR Code Generator',
    icon: Icons.qr_code_2_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'merge_pdf',
    name: 'Merge PDF',
    icon: Icons.merge_type_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  ToolModel(
    id: 'sign_pdf',
    name: 'Sign PDF',
    icon: Icons.draw_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'core',
    category: 'Core daily drivers',
    isFree: true,
  ),

  // ─────────────────────────
  // PDF CONVERSIONS
  // ─────────────────────────

  ToolModel(
    id: 'pdf_to_word',
    name: 'PDF to Word',
    icon: Icons.description_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'word_to_pdf',
    name: 'Word to PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'pdf_to_powerpoint',
    name: 'PDF to PowerPoint',
    icon: Icons.slideshow_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'powerpoint_to_pdf',
    name: 'PowerPoint to PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'pdf_to_excel',
    name: 'PDF to Excel',
    icon: Icons.table_chart_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'excel_to_pdf',
    name: 'Excel to PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'jpg_to_pdf',
    name: 'JPG to PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'pdf_to_jpg',
    name: 'PDF to JPG',
    icon: Icons.image_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'heic_to_jpg',
    name: 'HEIC to JPG',
    icon: Icons.image_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'png_to_jpg',
    name: 'PNG to JPG',
    icon: Icons.image_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'jpg_to_png',
    name: 'JPG to PNG',
    icon: Icons.image_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  ToolModel(
    id: 'csv_to_excel',
    name: 'CSV to Excel',
    icon: Icons.table_chart_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'High intent conversions',
    isFree: true,
  ),

  // ─────────────────────────
  // PDF TOOLS
  // ─────────────────────────

  ToolModel(
    id: 'split_pdf',
    name: 'Split PDF',
    icon: Icons.call_split_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'rotate_pdf',
    name: 'Rotate PDF',
    icon: Icons.rotate_right_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'reorder_pdf_pages',
    name: 'Reorder PDF Pages',
    icon: Icons.reorder_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'protect_pdf',
    name: 'Protect PDF',
    icon: Icons.lock_outline,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'unlock_pdf',
    name: 'Unlock PDF',
    icon: Icons.lock_open_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'add_watermark',
    name: 'Add Watermark',
    icon: Icons.water_drop_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'add_page_numbers',
    name: 'Add Page Numbers',
    icon: Icons.format_list_numbered_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'extract_text_pdf',
    name: 'Extract Text from PDF',
    icon: Icons.text_snippet_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'repair_pdf',
    name: 'Repair PDF',
    icon: Icons.build_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'annotate_pdf',
    name: 'Annotate PDF',
    icon: Icons.edit_note_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  ToolModel(
    id: 'edit_pdf',
    name: 'Edit PDF',
    icon: Icons.edit_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'pdf',
    category: 'PDF editing',
    isFree: true,
  ),

  // ─────────────────────────
  // OCR
  // ─────────────────────────

  ToolModel(
    id: 'ocr_to_text',
    name: 'OCR to Text',
    icon: Icons.text_fields_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ocr',
    category: 'OCR',
    isFree: true,
  ),

  ToolModel(
    id: 'ocr_to_word',
    name: 'OCR to Word',
    icon: Icons.description_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ocr',
    category: 'OCR',
    isFree: true,
  ),

  ToolModel(
    id: 'ocr_searchable_pdf',
    name: 'OCR to Searchable PDF',
    icon: Icons.picture_as_pdf_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ocr',
    category: 'OCR',
    isFree: false,
  ),

  // ─────────────────────────
  // AI TOOLS
  // ─────────────────────────

  ToolModel(
    id: 'ai_summarize',
    name: 'AI Summarize',
    icon: Icons.summarize_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: true,
  ),

  ToolModel(
    id: 'grammar_checker',
    name: 'Grammar Checker',
    icon: Icons.spellcheck_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: true,
  ),

  ToolModel(
    id: 'chat_with_pdf',
    name: 'Chat with PDF',
    icon: Icons.chat_bubble_outline,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: false,
  ),

  ToolModel(
    id: 'ai_translate',
    name: 'AI Translate',
    icon: Icons.translate_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree:false,
  ),

  ToolModel(
    id: 'humanize_ai',
    name: 'Humanize AI Content + AI Rewrite',
    icon: Icons.auto_awesome_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: false,
  ),

  ToolModel(
    id: 'flashcard_generator',
    name: 'Flashcard Generator',
    icon: Icons.style_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: false,
  ),

  ToolModel(
    id: 'quiz_generator',
    name: 'Quiz Generator',
    icon: Icons.quiz_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'ai',
    category: 'AI tools',
    isFree: false,
  ),

  // ─────────────────────────
  // IMAGE TOOLS
  // ─────────────────────────

  ToolModel(
    id: 'enhance_photo',
    name: 'Enhance Photo',
    icon: Icons.auto_fix_high_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'image',
    category: 'Image tools',
    isFree: true,
  ),

  ToolModel(
    id: 'smart_image_cropper',
    name: 'Smart Image Cropper',
    icon: Icons.crop_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'image',
    category: 'Image tools',
    isFree: true,
  ),

  ToolModel(
    id: 'barcode_generator',
    name: 'Barcode Generator',
    icon: Icons.qr_code_2,
    color: const Color(0xFF5B61E9),
    categoryId: 'image',
    category: 'Image tools',
    isFree: true,
  ),

  ToolModel(
    id: 'meme_generator',
    name: 'Meme Generator',
    icon: Icons.sentiment_satisfied_alt_outlined,
    color: const Color(0xFF5B61E9),
    categoryId: 'image',
    category: 'Image tools',
    isFree: true,
  ),
];

  List<ToolModel> get filteredTools {
    final query = searchText.value.toLowerCase().trim();

    List<ToolModel> result = tools;

    // Filter by category
    switch (selectedFilter.value) {
      case '⚡ Core':
        result = result
            .where((tool) => tool.categoryId == 'core')
            .toList();
        break;

      case '☷ High-intent':
        result = result
            .where((tool) => tool.category == 'High intent conversions')
            .toList();
        break;

      case '✎ PDF':
        result = result
            .where(
              (tool) =>
                  tool.name.toLowerCase().contains('pdf'),
            )
            .toList();
        break;
        case '⌕ OCR':
        result = result.where(
          (tool)=>tool.name.toLowerCase().contains("ocr"),
        ).toList();
        break;
        case'✦ AI' :
        result = result.where(
          (tool) =>tool.name.toLowerCase().contains('ai')
        ).toList();
        break;
        case '▧ Image' :
        result = result.where(
          (tool)=>tool.name.toLowerCase().contains('image')
        ).toList();
        break;
    }

    // Filter by search
    if (query.isNotEmpty) {
      result = result.where((tool) {
        final name = tool.name.toLowerCase();
        final category = tool.category?.toLowerCase() ?? '';

        return name.contains(query) ||
            category.contains(query);
      }).toList();
    }

    return result;
  }

  void updateSearch(String value) {
    searchText.value = value;
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }

  void clearSearch() {
    searchController.clear();
    searchText.value = '';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
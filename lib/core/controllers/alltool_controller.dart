import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/services/storage_service.dart';
import 'package:plainscan/models/tool_model.dart';

class AllToolsController extends GetxController {
  final searchController = TextEditingController();

  final searchText = ''.obs;
  final selectedFilter = '▦ All 52'.obs;
  final recentTools = <ToolModel>[].obs;

  final List<ToolModel> tools = allPlainscanTools;

  final List<String> filters = [
    '▦ All 52',
    '📄 PDF Conversion',
    '🛠️ PDF Manipulation',
    '🔍 OCR & Scan',
    '🤖 AI Tools',
    '📦 Utility',
  ];

  List<ToolModel> get filteredTools {
    final query = searchText.value.toLowerCase().trim();

    List<ToolModel> result = tools;

    // Filter by category
    switch (selectedFilter.value) {
      case '📄 PDF Conversion':
        result = result.where((tool) => tool.categoryId == 'conversion').toList();
        break;
      case '🛠️ PDF Manipulation':
        result = result.where((tool) => tool.categoryId == 'manipulation').toList();
        break;
      case '🔍 OCR & Scan':
        result = result.where((tool) => tool.categoryId == 'ocr').toList();
        break;
      case '🤖 AI Tools':
        result = result.where((tool) => tool.categoryId == 'ai').toList();
        break;
      case '📦 Utility':
        result = result.where((tool) => tool.categoryId == 'utility').toList();
        break;
      default:
        // '▦ All 52' or anything else
        break;
    }

    // Filter by search
    if (query.isNotEmpty) {
      result = result.where((tool) {
        final name = tool.name.toLowerCase();
        final category = tool.category?.toLowerCase() ?? '';
        final desc = tool.description?.toLowerCase() ?? '';
        final inputFmt = tool.inputFormat?.toLowerCase() ?? '';
        final outputFmt = tool.outputFormat?.toLowerCase() ?? '';
        final slug = tool.slug.toLowerCase();

        return name.contains(query) ||
            category.contains(query) ||
            desc.contains(query) ||
            inputFmt.contains(query) ||
            outputFmt.contains(query) ||
            slug.contains(query);
      }).toList();
    }

    return result;
  }

  List<ToolModel> get filteredRecentTools {
    final query = searchText.value.toLowerCase().trim();
    if (query.isEmpty) {
      return recentTools;
    }
    return recentTools.where((tool) {
      final name = tool.name.toLowerCase();
      final category = tool.category?.toLowerCase() ?? '';
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadRecentTools();
  }

  ToolModel? findToolByIdOrSlug(String id) {
    final cleanId = id.replaceAll('_', '-');
    return tools.firstWhereOrNull(
      (t) => t.id == id || t.slug == id || t.id == cleanId || t.slug == cleanId,
    );
  }

  Future<void> loadRecentTools() async {
    final ids = await StorageService.getRecentToolIds();
    if (ids.isEmpty) {
      const defaultIds = [
        'scan-ocr',
        'pdf-to-word',
        'pdf-merge',
        'pdf-compress',
        'pdf-sign',
        'ai-summarize',
      ];
      recentTools.value = defaultIds
          .map((id) => findToolByIdOrSlug(id))
          .whereType<ToolModel>()
          .toList();
    } else {
      recentTools.value = ids
          .map((id) => findToolByIdOrSlug(id))
          .whereType<ToolModel>()
          .toList();
    }
  }

  Future<void> recordToolUsage(String toolId) async {
    await StorageService.addRecentToolId(toolId);
    await loadRecentTools();
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
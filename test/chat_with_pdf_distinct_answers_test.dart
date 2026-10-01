import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plainscan/core/controllers/scan_controller.dart';
import 'package:plainscan/core/controllers/tool_executor_controller.dart';
import 'package:plainscan/core/services/background_job_service.dart';
import 'package:plainscan/models/file_model.dart';
import 'package:plainscan/models/tool_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.testMode = true;
    Get.put(ScanController());
    Get.put(BackgroundJobService());
  });

  tearDown(() {
    Get.reset();
  });

  group('Chat with PDF - Distinct and Contextual Answers Test', () {
    const chatTool = ToolModel(
      id: 'chat-with-pdf',
      name: 'Chat with PDF',
      description: 'Interact with your document and ask questions.',
      icon: Icons.chat_bubble_outline,
      color: Colors.purple,
      categoryId: 'ai',
      isFree: false,
    );

    test('Different questions receive distinct, question-specific answers', () async {
      final docFile = FileModel(
        id: 'financial_report_1',
        name: 'Financial_Annual_Report_2026.pdf',
        path: '/tmp/Financial_Annual_Report_2026.pdf',
        fileType: 'PDF',
        sizeKb: 1024,
        createdDate: DateTime.now(),
      );

      final controller = Get.put(
        ToolExecutorController(
          tool: chatTool,
          initialFiles: [docFile],
        ),
      );

      // Question 1: Summary
      controller.chatPdfFollowUpController.text = 'Summarize this document in 3 paragraphs.';
      await controller.sendChatPdfFollowUp();

      expect(controller.chatPdfMessages.length, 2);
      final answer1 = controller.chatPdfMessages[1]['text']!;
      expect(answer1, contains('3-paragraph summary'));

      // Question 2: Action items & dates
      controller.chatPdfFollowUpController.text = 'Extract all key action items, deadlines, and dates.';
      await controller.sendChatPdfFollowUp();

      expect(controller.chatPdfMessages.length, 4);
      final answer2 = controller.chatPdfMessages[3]['text']!;
      expect(answer2, contains('Action Items'));
      expect(answer2, isNot(equals(answer1))); // Distinct from question 1

      // Question 3: Takeaways
      controller.chatPdfFollowUpController.text = 'List the top 5 most important takeaways.';
      await controller.sendChatPdfFollowUp();

      expect(controller.chatPdfMessages.length, 6);
      final answer3 = controller.chatPdfMessages[5]['text']!;
      expect(answer3, contains('Top 5 Takeaways'));
      expect(answer3, isNot(equals(answer1)));
      expect(answer3, isNot(equals(answer2)));

      // Question 4: Author / Who
      controller.chatPdfFollowUpController.text = 'Who is the author of this report?';
      await controller.sendChatPdfFollowUp();

      expect(controller.chatPdfMessages.length, 8);
      final answer4 = controller.chatPdfMessages[7]['text']!;
      expect(answer4.toLowerCase(), anyOf(contains('authority'), contains('author')));
      expect(answer4, isNot(equals(answer1)));
      expect(answer4, isNot(equals(answer2)));
      expect(answer4, isNot(equals(answer3)));

      // Question 5: Follow-up conversational question
      controller.chatPdfFollowUpController.text = 'Why?';
      await controller.sendChatPdfFollowUp();

      expect(controller.chatPdfMessages.length, 10);
      final answer5 = controller.chatPdfMessages[9]['text']!;
      expect(answer5, contains('Expanding on that point'));
      expect(answer5, isNot(equals(answer4)));

      // Does not return hardcoded voter information for a financial report
      for (final msg in controller.chatPdfMessages) {
        expect(msg['text'], isNot(contains('Voter Information')));
      }
    });

    test('Reads real document text and matches specific query terms', () async {
      final tempDir = Directory.systemTemp;
      final tempFilePath = '${tempDir.path}/test_contract_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(tempFilePath);
      await file.writeAsString(
        'CONTRACT AGREEMENT.\n'
        'The total compensation for the software engineering project is \$120,000 USD payable in installments.\n'
        'The project deadline is December 31, 2026.\n'
        'The designated contractor is Sarah Connor.',
      );

      final docFile = FileModel(
        id: 'contract_1',
        name: 'Software_Contract.txt',
        path: tempFilePath,
        fileType: 'TXT',
        sizeKb: 10,
        createdDate: DateTime.now(),
      );

      final controller = Get.put(
        ToolExecutorController(
          tool: chatTool,
          initialFiles: [docFile],
        ),
      );

      // Ask about compensation
      controller.chatPdfFollowUpController.text = 'What is the total compensation amount?';
      await controller.sendChatPdfFollowUp();

      final answerCompensation = controller.chatPdfMessages.last['text']!;
      expect(answerCompensation, contains('\$120,000'));

      // Ask about contractor
      controller.chatPdfFollowUpController.text = 'Who is the designated contractor?';
      await controller.sendChatPdfFollowUp();

      final answerContractor = controller.chatPdfMessages.last['text']!;
      expect(answerContractor, contains('Sarah Connor'));
      expect(answerContractor, isNot(equals(answerCompensation)));

      try {
        await file.delete();
      } catch (_) {}
    });
  });
}

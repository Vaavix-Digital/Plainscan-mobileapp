import 'package:flutter/material.dart';
import 'package:plainscan/core/constants/app_colors.dart';

class MessageModel {
  final String text;
  final bool isUser;
  final DateTime time;

  MessageModel({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final List<MessageModel> _messages = [
    MessageModel(
      text: 'Hi! I am your PlainScan AI Assistant. Pick any of your scanned documents and ask me to:\n\n• Summarize key details\n• Translate paragraphs\n• Extract invoice tables or numbers',
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Summarize Tax_Return_2026.pdf',
    'Extract invoice totals',
    'Translate last scan to Spanish',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(MessageModel(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
    });

    _messageController.clear();
    _scrollToBottom();

    // Mock AI reply delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;

      String aiResponse = "I can see you're referencing your document. As this is a prototype, I can simulate this request for you! This will connect to an LLM endpoint to read and analyze your files.";
      
      if (text.contains('Tax_Return_2026.pdf')) {
        aiResponse = "Here is a mock summary of Tax_Return_2026.pdf:\n\n• **Tax Year**: 2026\n• **Adjusted Gross Income (AGI)**: \$78,500\n• **Estimated Refund**: \$1,240\n• **Filing Status**: Single\n\nWould you like me to draft an email with these details?";
      } else if (text.contains('invoice')) {
        aiResponse = "Extracted Invoice Data:\n• **Vendor**: Uber Technologies\n• **Date**: Aug 18, 2026\n• **Total Amount**: \$24.50\n• **Payment Method**: Card ending in 4321";
      }

      setState(() {
        _messages.add(MessageModel(
          text: aiResponse,
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Scan AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat history
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      padding: const EdgeInsets.all(14.0),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                          bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                        ),
                        border: msg.isUser ? null : Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.isUser ? Colors.white : AppColors.text,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Suggestions Chips
            if (_messages.length == 1)
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final sug = _suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(sug),
                        labelStyle: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.primary, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () => _sendMessage(sug),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.secondaryText),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecting document attachment...')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Ask AI assistant...',
                          hintStyle: TextStyle(color: AppColors.secondaryText, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
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
}

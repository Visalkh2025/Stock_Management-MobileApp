import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:stock_management/View/Components/app_snackbar.dart';

/// One expandable FAQ entry on the Help & Support screen.
class FaqItemData {
  const FaqItemData({required this.question, required this.answer});
  final String question;
  final String answer;
}

/// More > Help & Support — a static FAQ list plus a contact card. No
/// live chat/ticketing backend — "contact" here just copies an
/// email/phone to the clipboard (no url_launcher dependency in this app).
class HelpSupportController extends GetxController {
  // NOTE: question/answer store translation KEYS, not literal text — they're resolved with `.tr` at display time in the screen.
  final List<FaqItemData> faqs = const [
    FaqItemData(question: 'faq_approve_reject_q', answer: 'faq_approve_reject_a'),
    FaqItemData(question: 'faq_transfer_stock_q', answer: 'faq_transfer_stock_a'),
    FaqItemData(question: 'faq_adjust_stock_q', answer: 'faq_adjust_stock_a'),
    FaqItemData(question: 'faq_manage_access_q', answer: 'faq_manage_access_a'),
    FaqItemData(question: 'faq_reset_password_q', answer: 'faq_reset_password_a'),
  ];

  final expandedQuestions = <String>{}.obs;

  void toggleFaq(String question) {
    if (expandedQuestions.contains(question)) {
      expandedQuestions.remove(question);
    } else {
      expandedQuestions.add(question);
    }
  }

  void copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    AppSnackbar.info(
      'copied_title'.tr,
      'copied_to_clipboard_message'.trParams({'label': label}),
    );
  }
}

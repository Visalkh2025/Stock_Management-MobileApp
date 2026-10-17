import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
  // NOTE: question/answer store translation KEYS, not literal text —
  // they're resolved with `.tr` at display time in the screen. Kept as
  // keys (not final resolved strings) so `expandedQuestions` has a
  // stable, locale-independent identity to track, and so the FAQ text
  // itself re-resolves correctly on every rebuild after a language
  // switch (a `final` list of already-`.tr`'d strings would freeze at
  // whichever locale was active when the controller was constructed).
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
    Get.snackbar(
      'copied_title'.tr,
      'copied_to_clipboard_message'.trParams({'label': label}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}

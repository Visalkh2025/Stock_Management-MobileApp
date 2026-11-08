import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Typing filter for a price field: digits and one dot, at most 2 decimals
/// and 9 digits before the dot.
final List<TextInputFormatter> priceInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?')),
];

final RegExp _priceRe = RegExp(r'^\d+(\.\d{1,2})?$');

/// Validator for the cost / sale price fields: required, a number with up to
/// 2 decimals, and above 0.
String? validatePrice(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'price_required'.tr;
  if (!_priceRe.hasMatch(text)) return 'price_invalid'.tr;
  if ((double.tryParse(text) ?? 0) <= 0) return 'price_positive'.tr;
  return null;
}

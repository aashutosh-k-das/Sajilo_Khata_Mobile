import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Opens WhatsApp deep link sharing the text summary of a bill/receipt
  Future<bool> shareInvoice({
    required String phone,
    required String invoiceText,
  }) async {
    // Sanitize phone (ensure it has country code if needed, or format cleanly)
    String sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!sanitizedPhone.startsWith('977') && sanitizedPhone.length == 10) {
      sanitizedPhone = '977$sanitizedPhone'; // Default to Nepal country code
    }

    final encodedText = Uri.encodeComponent(invoiceText);
    
    // Direct link to chat with custom text
    final urlString = 'https://wa.me/$sanitizedPhone?text=$encodedText';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch WhatsApp url: $urlString');
      }
    } catch (e) {
      debugPrint('WhatsApp share exception: $e');
    }
    return false;
  }
}

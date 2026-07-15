import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SMSService {
  static const String _sparrowApiUrl = 'https://api.sparrowsms.com/v2/sms/';
  
  // Replace with the merchant's actual token provided by Sparrow SMS
  final String _token;
  final String _senderId; // e.g. 'InfoSMS' or client's custom SMS ID

  SMSService({
    required String token,
    String senderId = 'SajiloKhata',
  })  : _token = token,
        _senderId = senderId;

  /// Sends a SMS to a Nepalese 10-digit mobile number using Sparrow SMS API.
  /// Returns [true] if successfully dispatched.
  Future<bool> sendReminderSMS({
    required String toPhone,
    required String messageText,
  }) async {
    try {
      // Basic validation for Nepal numbers (must start with 98 or 97 and have 10 digits)
      if (toPhone.length < 10) {
        debugPrint('Invalid phone number length: $toPhone');
        return false;
      }

      final response = await http.post(
        Uri.parse(_sparrowApiUrl),
        body: {
          'token': _token,
          'from': _senderId,
          'to': toPhone,
          'text': messageText,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['status'] == 'success' || body['response_code'] == 200) {
          debugPrint('SMS Sent successfully. MessageID: ${body['message_id']}');
          return true;
        } else {
          debugPrint('Sparrow API Error response: ${response.body}');
        }
      } else {
        debugPrint('Sparrow API HTTP failure: Code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SMS dispatch exception: $e');
    }
    return false;
  }

  /// Helper to generate standard payment reminder message in Nepali (Devanagari)
  String generateNepaliReminderText({
    required String customerName,
    required double outstandingAmount,
    required String shopName,
  }) {
    return 'नमस्ते $customerName ज्यू, तपाईंको $shopName मा बाँकी भुक्तानी रु. ${outstandingAmount.toStringAsFixed(2)} बाँकी रहेको छ। कृपया चाँडै भुक्तानी गरिदिनुहोला। धन्यवाद!';
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:safeway/models/subscription_model.dart';
import 'package:safeway/services/api_config.dart';

class SubscriptionService {
  static String get baseUrl => apiBaseUrl;

  // For Student dashboard
  static Future<SubscriptionModel?> getStudentSubscription(int userId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/subscription/student/$userId'),
      );
      if (res.statusCode == 200) {
        return SubscriptionModel.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  // For Parent dashboard
  static Future<List<Map<String, dynamic>>?> getParentSubscriptions(int parentId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/subscription/parent/$parentId'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }
}
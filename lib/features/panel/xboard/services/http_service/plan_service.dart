// services/plan_service.dart
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';


class PlanService {
  final HttpService _httpService = HttpService();

  Future<List<Plan>> fetchPlanData(String accessToken) async {
    Map<String, dynamic> result;
    try {
      result = await _httpService.getRequest(
        "/api/v1/user/plan/fetch",
        headers: {'Authorization': accessToken},
      );
    } catch (_) {
      result = await _httpService.getRequest(
        "/api/v1/user/plan/fetch",
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }
    return (result["data"] as List)
        .cast<Map<String, dynamic>>()
        .map((json) => Plan.fromJson(json))
        .toList();
  }
}

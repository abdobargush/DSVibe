import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poker_models.dart';

class ApiService {
  final String baseUrl;

  ApiService({String? url}) 
      : baseUrl = url ?? _getDefaultUrl();

  static String _getDefaultUrl() {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return 'http://$host:8080';
  }

  Future<EvaluateResponse> evaluateHand(
    List<String> holeCards,
    List<String> communityCards,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/evaluate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
      }),
    );

    if (response.statusCode == 200) {
      return EvaluateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to evaluate hand: ${response.body}');
    }
  }

  Future<CompareResponse> compareHands(
    List<String> p1Hole,
    List<String> p1Community,
    List<String> p2Hole,
    List<String> p2Community,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/compare'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'player1_hole_cards': p1Hole,
        'player1_community_cards': p1Community,
        'player2_hole_cards': p2Hole,
        'player2_community_cards': p2Community,
      }),
    );

    if (response.statusCode == 200) {
      return CompareResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to compare hands: ${response.body}');
    }
  }

  Future<ProbabilityResponse> calculateProbability(
    List<String> holeCards,
    List<String> communityCards,
    int numPlayers,
    int numSimulations,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/probability'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
        'num_players': numPlayers,
        'num_simulations': numSimulations,
      }),
    );

    if (response.statusCode == 200) {
      return ProbabilityResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to calculate probability: ${response.body}');
    }
  }
}

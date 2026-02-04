class EvaluateResponse {
  final String bestHand;
  final String handValue;
  final List<String> cards;

  EvaluateResponse({
    required this.bestHand,
    required this.handValue,
    required this.cards,
  });

  factory EvaluateResponse.fromJson(Map<String, dynamic> json) {
    return EvaluateResponse(
      bestHand: json['best_hand'],
      handValue: json['hand_value'],
      cards: List<String>.from(json['cards']),
    );
  }
}

class CompareResponse {
  final EvaluateResponse player1Hand;
  final EvaluateResponse player2Hand;
  final String winner;
  final String winnerReason;

  CompareResponse({
    required this.player1Hand,
    required this.player2Hand,
    required this.winner,
    required this.winnerReason,
  });

  factory CompareResponse.fromJson(Map<String, dynamic> json) {
    return CompareResponse(
      player1Hand: EvaluateResponse.fromJson(json['player1_hand']),
      player2Hand: EvaluateResponse.fromJson(json['player2_hand']),
      winner: json['winner'],
      winnerReason: json['winner_reason'],
    );
  }
}

class ProbabilityResponse {
  final double winProbability;
  final double tieProbability;
  final double loseProbability;
  final int simulations;

  ProbabilityResponse({
    required this.winProbability,
    required this.tieProbability,
    required this.loseProbability,
    required this.simulations,
  });

  factory ProbabilityResponse.fromJson(Map<String, dynamic> json) {
    return ProbabilityResponse(
      winProbability: json['win_probability'].toDouble(),
      tieProbability: json['tie_probability'].toDouble(),
      loseProbability: json['lose_probability'].toDouble(),
      simulations: json['simulations'],
    );
  }
}

package models

type Card struct {
	Suit string `json:"suit"`
	Rank string `json:"rank"`
}

type EvaluateRequest struct {
	HoleCards      []string `json:"hole_cards"`      // 2 cards
	CommunityCards []string `json:"community_cards"` // 5 cards
}

type EvaluateResponse struct {
	BestHand  string   `json:"best_hand"`
	HandValue string   `json:"hand_value"`
	Cards     []string `json:"cards"`
}

type CompareRequest struct {
	Player1HoleCards      []string `json:"player1_hole_cards"`
	Player1CommunityCards []string `json:"player1_community_cards"`
	Player2HoleCards      []string `json:"player2_hole_cards"`
	Player2CommunityCards []string `json:"player2_community_cards"`
}

type CompareResponse struct {
	Player1Hand  EvaluateResponse `json:"player1_hand"`
	Player2Hand  EvaluateResponse `json:"player2_hand"`
	Winner       string           `json:"winner"` // "player1", "player2", or "tie"
	WinnerReason string           `json:"winner_reason"`
}

type ProbabilityRequest struct {
	HoleCards      []string `json:"hole_cards"`       // 2 cards
	CommunityCards []string `json:"community_cards"`  // 0-5 cards
	NumPlayers     int      `json:"num_players"`      // total players including you
	NumSimulations int      `json:"num_simulations"`  // Monte Carlo iterations
}

type ProbabilityResponse struct {
	WinProbability  float64 `json:"win_probability"`
	TieProbability  float64 `json:"tie_probability"`
	LoseProbability float64 `json:"lose_probability"`
	Simulations     int     `json:"simulations"`
}

package handlers

import (
	"encoding/json"
	"net/http"
	"poker-app/models"
	"poker-app/poker"
)

func CompareHandler(w http.ResponseWriter, r *http.Request) {
	var req models.CompareRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Parse Player 1 cards
	p1Hole, err := poker.ParseCards(req.Player1HoleCards)
	if err != nil {
		http.Error(w, "invalid player1 hole cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	p1Community, err := poker.ParseCards(req.Player1CommunityCards)
	if err != nil {
		http.Error(w, "invalid player1 community cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Parse Player 2 cards
	p2Hole, err := poker.ParseCards(req.Player2HoleCards)
	if err != nil {
		http.Error(w, "invalid player2 hole cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	p2Community, err := poker.ParseCards(req.Player2CommunityCards)
	if err != nil {
		http.Error(w, "invalid player2 community cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Evaluate hands
	p1Hand := poker.EvaluateBestHand(p1Hole, p1Community)
	p2Hand := poker.EvaluateBestHand(p2Hole, p2Community)

	// Compare
	comparison := poker.CompareHands(p1Hand, p2Hand)

	// Build response
	p1Cards := make([]string, len(p1Hand.Cards))
	for i, card := range p1Hand.Cards {
		p1Cards[i] = card.String()
	}

	p2Cards := make([]string, len(p2Hand.Cards))
	for i, card := range p2Hand.Cards {
		p2Cards[i] = card.String()
	}

	resp := models.CompareResponse{
		Player1Hand: models.EvaluateResponse{
			BestHand:  poker.HandNames[p1Hand.Rank],
			HandValue: poker.HandNames[p1Hand.Rank],
			Cards:     p1Cards,
		},
		Player2Hand: models.EvaluateResponse{
			BestHand:  poker.HandNames[p2Hand.Rank],
			HandValue: poker.HandNames[p2Hand.Rank],
			Cards:     p2Cards,
		},
	}

	if comparison > 0 {
		resp.Winner = "player1"
		resp.WinnerReason = "Player 1 has " + poker.HandNames[p1Hand.Rank]
	} else if comparison < 0 {
		resp.Winner = "player2"
		resp.WinnerReason = "Player 2 has " + poker.HandNames[p2Hand.Rank]
	} else {
		resp.Winner = "tie"
		resp.WinnerReason = "Both players have " + poker.HandNames[p1Hand.Rank]
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

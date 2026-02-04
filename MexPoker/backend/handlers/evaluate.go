package handlers

import (
	"encoding/json"
	"net/http"
	"poker-app/models"
	"poker-app/poker"
)

func EvaluateHandler(w http.ResponseWriter, r *http.Request) {
	var req models.EvaluateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate input
	if len(req.HoleCards) != 2 {
		http.Error(w, "must provide exactly 2 hole cards", http.StatusBadRequest)
		return
	}
	if len(req.CommunityCards) != 5 {
		http.Error(w, "must provide exactly 5 community cards", http.StatusBadRequest)
		return
	}

	// Parse cards
	holeCards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		http.Error(w, "invalid hole cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	communityCards, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		http.Error(w, "invalid community cards: "+err.Error(), http.StatusBadRequest)
		return
	}

	// Evaluate hand
	bestHand := poker.EvaluateBestHand(holeCards, communityCards)

	// Build response
	cardStrings := make([]string, len(bestHand.Cards))
	for i, card := range bestHand.Cards {
		cardStrings[i] = card.String()
	}

	resp := models.EvaluateResponse{
		BestHand:  poker.HandNames[bestHand.Rank],
		HandValue: poker.HandNames[bestHand.Rank],
		Cards:     cardStrings,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

package handlers

import (
	"encoding/json"
	"net/http"
	"poker-app/models"
	"poker-app/poker"
)

func ProbabilityHandler(w http.ResponseWriter, r *http.Request) {
	var req models.ProbabilityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Validate input
	if len(req.HoleCards) != 2 {
		http.Error(w, "must provide exactly 2 hole cards", http.StatusBadRequest)
		return
	}
	if len(req.CommunityCards) > 5 {
		http.Error(w, "cannot have more than 5 community cards", http.StatusBadRequest)
		return
	}
	if req.NumPlayers < 2 || req.NumPlayers > 10 {
		http.Error(w, "number of players must be between 2 and 10", http.StatusBadRequest)
		return
	}
	if req.NumSimulations < 100 || req.NumSimulations > 100000 {
		http.Error(w, "number of simulations must be between 100 and 100000", http.StatusBadRequest)
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

	// Run simulation
	result := poker.SimulateWinProbability(holeCards, communityCards, req.NumPlayers, req.NumSimulations)

	// Calculate probabilities
	winProb := float64(result.Wins) / float64(result.Total)
	tieProb := float64(result.Ties) / float64(result.Total)
	loseProb := float64(result.Losses) / float64(result.Total)

	resp := models.ProbabilityResponse{
		WinProbability:  winProb * 100,
		TieProbability:  tieProb * 100,
		LoseProbability: loseProb * 100,
		Simulations:     req.NumSimulations,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

# Texas Hold'em Poker Hand Evaluator & Probability Calculator

A full-stack poker hand evaluation and probability calculation application with REST API backend (Go) and Flutter web frontend, containerized with Docker and deployed on Google Kubernetes Engine (GKE).

## Overview

This application provides three core functionalities:
1. **Hand Evaluation**: Evaluates the best poker hand from 2 hole cards + 5 community cards
2. **Hand Comparison**: Compares two poker hands and determines the winner
3. **Win Probability**: Calculates win probability using Monte Carlo simulation

## References

- [Poker Rules by Peter Norvig](http://norvig.com/poker.html)
- [Texas Hold'em (Wikipedia - English)](https://en.wikipedia.org/wiki/Texas_hold_%27em)
- [Texas Hold'em (Wikipedia - German)](https://de.wikipedia.org/wiki/Texas_Hold%E2%80%99em)

## Architecture Overview

- **Backend**: Go REST API server
- **Frontend**: Flutter web application
- **Communication**: RESTful HTTP/JSON
- **Containerization**: Docker
- **Orchestration**: Kubernetes (GKE)
- **Load Testing**: k6

## Card Notation

Cards are specified as 2-character strings:
- **First character**: Suit (H=Hearts, D=Diamonds, C=Clubs, S=Spades)
- **Second character**: Rank (2-9, T=Ten, J=Jack, Q=Queen, K=King, A=Ace)

**Examples:**
- `HA` = Heart Ace
- `S7` = Spade 7
- `CT` = Club Ten
- `DK` = Diamond King

## Project Structure

```
poker-app/
├── backend/
│   ├── main.go
│   ├── handlers/
│   │   ├── evaluate.go
│   │   ├── compare.go
│   │   └── probability.go
│   ├── poker/
│   │   ├── card.go
│   │   ├── deck.go
│   │   ├── hand.go
│   │   ├── evaluator.go
│   │   └── simulator.go
│   ├── models/
│   │   └── types.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   │   └── poker_models.dart
│   │   ├── services/
│   │   │   └── api_service.dart
│   │   └── screens/
│   │       ├── evaluate_screen.dart
│   │       ├── compare_screen.dart
│   │       └── probability_screen.dart
│   ├── web/
│   │   └── index.html
│   ├── pubspec.yaml
│   └── Dockerfile
├── k8s/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   └── frontend-service.yaml
├── load-testing/
│   └── load-test.js
├── docker-compose.yaml
└── README.md
```

---

## Phase 1: Setup Development Environment

### Prerequisites

```bash
# Install Go (1.21+)
# Download from https://go.dev/dl/

# Install Flutter (3.16+)
# Download from https://flutter.dev/docs/get-started/install

# Install Docker
# Download from https://www.docker.com/products/docker-desktop

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install gcloud CLI
# Download from https://cloud.google.com/sdk/docs/install

# Install k6 (for load testing)
# Download from https://k6.io/docs/getting-started/installation/
```

---

## Phase 2: Backend Development (Go + REST API)

### Step 1: Initialize Go Module

```bash
mkdir -p poker-app/backend
cd backend
go mod init poker-app
```

### Step 2: Install Dependencies

```bash
go get github.com/gorilla/mux
go get github.com/rs/cors
```

### Step 3: Create Data Models

Create `backend/models/types.go`:

```go
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
```

### Step 4: Create Card and Deck Logic

Create `backend/poker/card.go`:

```go
package poker

import (
	"fmt"
	"strings"
)

var (
	ValidSuits = map[string]bool{"H": true, "D": true, "C": true, "S": true}
	ValidRanks = map[string]bool{"2": true, "3": true, "4": true, "5": true, "6": true, "7": true, "8": true, "9": true, "T": true, "J": true, "Q": true, "K": true, "A": true}
	RankValues = map[string]int{
		"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9,
		"T": 10, "J": 11, "Q": 12, "K": 13, "A": 14,
	}
)

type Card struct {
	Suit string
	Rank string
}

func ParseCard(s string) (*Card, error) {
	s = strings.TrimSpace(strings.ToUpper(s))
	if len(s) != 2 {
		return nil, fmt.Errorf("invalid card format: %s", s)
	}

	suit := string(s[0])
	rank := string(s[1])

	if !ValidSuits[suit] {
		return nil, fmt.Errorf("invalid suit: %s", suit)
	}
	if !ValidRanks[rank] {
		return nil, fmt.Errorf("invalid rank: %s", rank)
	}

	return &Card{Suit: suit, Rank: rank}, nil
}

func (c *Card) String() string {
	return c.Suit + c.Rank
}

func (c *Card) Value() int {
	return RankValues[c.Rank]
}

func ParseCards(cards []string) ([]*Card, error) {
	result := make([]*Card, 0, len(cards))
	for _, cardStr := range cards {
		card, err := ParseCard(cardStr)
		if err != nil {
			return nil, err
		}
		result = append(result, card)
	}
	return result, nil
}
```

Create `backend/poker/deck.go`:

```go
package poker

import (
	"math/rand"
	"time"
)

type Deck struct {
	Cards []*Card
}

func NewDeck() *Deck {
	suits := []string{"H", "D", "C", "S"}
	ranks := []string{"2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"}

	cards := make([]*Card, 0, 52)
	for _, suit := range suits {
		for _, rank := range ranks {
			cards = append(cards, &Card{Suit: suit, Rank: rank})
		}
	}

	return &Deck{Cards: cards}
}

func (d *Deck) Shuffle() {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	r.Shuffle(len(d.Cards), func(i, j int) {
		d.Cards[i], d.Cards[j] = d.Cards[j], d.Cards[i]
	})
}

func (d *Deck) RemoveCards(toRemove []*Card) {
	removeMap := make(map[string]bool)
	for _, card := range toRemove {
		removeMap[card.String()] = true
	}

	filtered := make([]*Card, 0)
	for _, card := range d.Cards {
		if !removeMap[card.String()] {
			filtered = append(filtered, card)
		}
	}
	d.Cards = filtered
}

func (d *Deck) Draw(n int) []*Card {
	if n > len(d.Cards) {
		n = len(d.Cards)
	}
	drawn := d.Cards[:n]
	d.Cards = d.Cards[n:]
	return drawn
}
```

### Step 5: Create Hand Evaluator

Create `backend/poker/evaluator.go`:

```go
package poker

import (
	"sort"
)

type HandRank int

const (
	HighCard HandRank = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

var HandNames = map[HandRank]string{
	HighCard:      "High Card",
	OnePair:       "One Pair",
	TwoPair:       "Two Pair",
	ThreeOfAKind:  "Three of a Kind",
	Straight:      "Straight",
	Flush:         "Flush",
	FullHouse:     "Full House",
	FourOfAKind:   "Four of a Kind",
	StraightFlush: "Straight Flush",
	RoyalFlush:    "Royal Flush",
}

type Hand struct {
	Cards []*Card
	Rank  HandRank
	Score int
}

func EvaluateBestHand(holeCards, communityCards []*Card) *Hand {
	allCards := append([]*Card{}, holeCards...)
	allCards = append(allCards, communityCards...)

	// Generate all 5-card combinations
	combinations := generateCombinations(allCards, 5)
	
	var bestHand *Hand
	bestScore := -1

	for _, combo := range combinations {
		hand := evaluateHand(combo)
		if hand.Score > bestScore {
			bestScore = hand.Score
			bestHand = hand
		}
	}

	return bestHand
}

func evaluateHand(cards []*Card) *Hand {
	// Sort cards by value descending
	sorted := make([]*Card, len(cards))
	copy(sorted, cards)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Value() > sorted[j].Value()
	})

	hand := &Hand{Cards: sorted}

	// Check for flush
	isFlush := checkFlush(sorted)
	
	// Check for straight
	isStraight, straightHigh := checkStraight(sorted)

	// Count ranks
	rankCounts := make(map[string]int)
	for _, card := range sorted {
		rankCounts[card.Rank]++
	}

	counts := make([]int, 0)
	for _, count := range rankCounts {
		counts = append(counts, count)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(counts)))

	// Determine hand rank
	if isStraight && isFlush {
		if straightHigh == 14 {
			hand.Rank = RoyalFlush
			hand.Score = 10000000 + calculateScore(sorted)
		} else {
			hand.Rank = StraightFlush
			hand.Score = 9000000 + straightHigh*10000
		}
	} else if len(counts) >= 1 && counts[0] == 4 {
		hand.Rank = FourOfAKind
		hand.Score = 8000000 + calculateScore(sorted)
	} else if len(counts) >= 2 && counts[0] == 3 && counts[1] == 2 {
		hand.Rank = FullHouse
		hand.Score = 7000000 + calculateScore(sorted)
	} else if isFlush {
		hand.Rank = Flush
		hand.Score = 6000000 + calculateScore(sorted)
	} else if isStraight {
		hand.Rank = Straight
		hand.Score = 5000000 + straightHigh*10000
	} else if len(counts) >= 1 && counts[0] == 3 {
		hand.Rank = ThreeOfAKind
		hand.Score = 4000000 + calculateScore(sorted)
	} else if len(counts) >= 2 && counts[0] == 2 && counts[1] == 2 {
		hand.Rank = TwoPair
		hand.Score = 3000000 + calculateScore(sorted)
	} else if len(counts) >= 1 && counts[0] == 2 {
		hand.Rank = OnePair
		hand.Score = 2000000 + calculateScore(sorted)
	} else {
		hand.Rank = HighCard
		hand.Score = 1000000 + calculateScore(sorted)
	}

	return hand
}

func checkFlush(cards []*Card) bool {
	suit := cards[0].Suit
	for _, card := range cards {
		if card.Suit != suit {
			return false
		}
	}
	return true
}

func checkStraight(cards []*Card) (bool, int) {
	values := make([]int, len(cards))
	for i, card := range cards {
		values[i] = card.Value()
	}
	sort.Sort(sort.Reverse(sort.IntSlice(values)))

	// Check regular straight
	for i := 0; i < len(values)-1; i++ {
		if values[i]-values[i+1] != 1 {
			// Check for A-2-3-4-5 (wheel)
			if i == 0 && values[0] == 14 && values[1] == 5 && values[2] == 4 && values[3] == 3 && values[4] == 2 {
				return true, 5
			}
			return false, 0
		}
	}
	return true, values[0]
}

func calculateScore(cards []*Card) int {
	score := 0
	for i, card := range cards {
		score += card.Value() * (1 << (4 - i))
	}
	return score
}

func generateCombinations(cards []*Card, k int) [][]*Card {
	var result [][]*Card
	
	var backtrack func(start int, current []*Card)
	backtrack = func(start int, current []*Card) {
		if len(current) == k {
			combo := make([]*Card, k)
			copy(combo, current)
			result = append(result, combo)
			return
		}
		
		for i := start; i < len(cards); i++ {
			backtrack(i+1, append(current, cards[i]))
		}
	}
	
	backtrack(0, []*Card{})
	return result
}

func CompareHands(hand1, hand2 *Hand) int {
	if hand1.Score > hand2.Score {
		return 1
	} else if hand1.Score < hand2.Score {
		return -1
	}
	return 0
}
```

### Step 6: Create Monte Carlo Simulator

Create `backend/poker/simulator.go`:

```go
package poker

import (
	"math/rand"
	"time"
)

type SimulationResult struct {
	Wins   int
	Ties   int
	Losses int
	Total  int
}

func SimulateWinProbability(holeCards, communityCards []*Card, numPlayers, numSimulations int) *SimulationResult {
	result := &SimulationResult{}
	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	for i := 0; i < numSimulations; i++ {
		// Create a new deck and remove known cards
		deck := NewDeck()
		allKnownCards := append([]*Card{}, holeCards...)
		allKnownCards = append(allKnownCards, communityCards...)
		deck.RemoveCards(allKnownCards)
		deck.Shuffle()

		// Deal remaining community cards if needed
		currentCommunity := make([]*Card, len(communityCards))
		copy(currentCommunity, communityCards)
		
		cardsNeeded := 5 - len(communityCards)
		if cardsNeeded > 0 {
			newCards := deck.Draw(cardsNeeded)
			currentCommunity = append(currentCommunity, newCards...)
		}

		// Evaluate our hand
		ourHand := EvaluateBestHand(holeCards, currentCommunity)

		// Deal cards for opponents and evaluate
		wins := 0
		ties := 0
		losses := 0

		for p := 1; p < numPlayers; p++ {
			opponentHole := deck.Draw(2)
			opponentHand := EvaluateBestHand(opponentHole, currentCommunity)

			cmp := CompareHands(ourHand, opponentHand)
			if cmp > 0 {
				wins++
			} else if cmp == 0 {
				ties++
			} else {
				losses++
			}
		}

		// If we beat all opponents
		if losses == 0 && wins > 0 {
			result.Wins++
		} else if losses == 0 && ties > 0 && wins == 0 {
			result.Ties++
		} else {
			result.Losses++
		}

		result.Total++
	}

	return result
}
```

### Step 7: Create HTTP Handlers

Create `backend/handlers/evaluate.go`:

```go
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
```

Create `backend/handlers/compare.go`:

```go
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
```

Create `backend/handlers/probability.go`:

```go
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
```

### Step 8: Create Main Server

Create `backend/main.go`:

```go
package main

import (
	"log"
	"net/http"
	"os"
	"poker-app/handlers"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

func main() {
	router := mux.NewRouter()

	// API routes
	router.HandleFunc("/api/evaluate", handlers.EvaluateHandler).Methods("POST")
	router.HandleFunc("/api/compare", handlers.CompareHandler).Methods("POST")
	router.HandleFunc("/api/probability", handlers.ProbabilityHandler).Methods("POST")

	// Health check
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	}).Methods("GET")

	// CORS
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatal(err)
	}
}
```

### Step 9: Create Backend Dockerfile

Create `backend/Dockerfile`:

```dockerfile
FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 8080

CMD ["./server"]
```

### Step 10: Test Backend Locally

```bash
cd backend
go mod tidy
go run main.go
```

Test with curl:

```bash
# Test evaluate endpoint
curl -X POST http://localhost:8080/api/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "HK"],
    "community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
  }'

# Test compare endpoint
curl -X POST http://localhost:8080/api/compare \
  -H "Content-Type: application/json" \
  -d '{
    "player1_hole_cards": ["HA", "HK"],
    "player1_community_cards": ["HQ", "HJ", "HT", "D2", "C3"],
    "player2_hole_cards": ["SA", "SK"],
    "player2_community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
  }'

# Test probability endpoint
curl -X POST http://localhost:8080/api/probability \
  -H "Content-Type: application/json" \
  -d '{
    "hole_cards": ["HA", "HK"],
    "community_cards": ["HQ", "HJ"],
    "num_players": 3,
    "num_simulations": 1000
  }'
```

---

## Phase 3: Frontend Development (Flutter Web)

### Step 1: Create Flutter Project

```bash
flutter create frontend
cd frontend
```

### Step 2: Add Dependencies

Edit `frontend/pubspec.yaml`:

```yaml
name: frontend
description: Poker Hand Evaluator
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
```

### Step 3: Create API Service

Create `frontend/lib/services/api_service.dart`:

```dart
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
```

### Step 4: Create Models

Create `frontend/lib/models/poker_models.dart`:

```dart
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
```

### Step 5: Create Main UI

Create `frontend/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/evaluate_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/probability_screen.dart';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Hold\'em Poker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      EvaluateScreen(apiService: _apiService),
      CompareScreen(apiService: _apiService),
      ProbabilityScreen(apiService: _apiService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Texas Hold\'em Poker'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.style),
            label: 'Evaluate',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Probability',
          ),
        ],
      ),
    );
  }
}
```

Create `frontend/lib/screens/evaluate_screen.dart`, `compare_screen.dart`, and `probability_screen.dart` with beautiful poker-themed UIs (similar to the temperature converter but with card inputs).

### Step 6: Create Frontend Dockerfile

Create `frontend/Dockerfile`:

```dockerfile
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## Phase 4: Local Testing with Docker Compose

### Create docker-compose.yaml

```yaml
version: "3.8"

services:
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - backend
```

### Run Locally

```bash
docker-compose up --build
```

Access at `http://localhost`

---

## Phase 5: Kubernetes Deployment Files

### Backend Deployment

Create `k8s/backend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: poker-backend
  labels:
    app: poker-app
    component: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: poker-app
      component: backend
  template:
    metadata:
      labels:
        app: poker-app
        component: backend
    spec:
      containers:
      - name: backend
        image: gcr.io/YOUR_PROJECT_ID/poker-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Backend Service

Create `k8s/backend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: poker-backend
  labels:
    app: poker-app
    component: backend
spec:
  type: ClusterIP
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
  selector:
    app: poker-app
    component: backend
```

### Frontend Deployment

Create `k8s/frontend-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: poker-frontend
  labels:
    app: poker-app
    component: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: poker-app
      component: frontend
  template:
    metadata:
      labels:
        app: poker-app
        component: frontend
    spec:
      containers:
      - name: frontend
        image: gcr.io/YOUR_PROJECT_ID/poker-frontend:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

### Frontend Service (LoadBalancer)

Create `k8s/frontend-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: poker-frontend
  labels:
    app: poker-app
    component: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: poker-app
    component: frontend
```

---

## Phase 6: Google Cloud Setup and Deployment

### Step 1: Create GCP Project

```bash
gcloud auth login
gcloud projects create YOUR_PROJECT_ID --name="Poker App"
gcloud config set project YOUR_PROJECT_ID

gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### Step 2: Create GKE Cluster

```bash
gcloud container clusters create poker-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-medium \
    --enable-autoscaling \
    --min-nodes=3 \
    --max-nodes=10

gcloud container clusters get-credentials poker-cluster --zone=us-central1-a
```

### Step 3: Configure Docker for GCR

```bash
gcloud auth configure-docker
```

### Step 4: Build and Push Images

```bash
# Build backend
cd backend
docker build -t gcr.io/YOUR_PROJECT_ID/poker-backend:latest .
docker push gcr.io/YOUR_PROJECT_ID/poker-backend:latest

# Build frontend
cd ../frontend
docker build -t gcr.io/YOUR_PROJECT_ID/poker-frontend:latest .
docker push gcr.io/YOUR_PROJECT_ID/poker-frontend:latest
```

### Step 5: Update Kubernetes Manifests

Replace `YOUR_PROJECT_ID` in all k8s/*.yaml files:

```bash
sed -i 's/YOUR_PROJECT_ID/your-actual-project-id/g' k8s/*.yaml
```

### Step 6: Deploy to GKE

```bash
kubectl apply -f k8s/

# Watch deployment
kubectl get pods -w

# Get external IP
kubectl get service poker-frontend --watch
```

Once `EXTERNAL-IP` is assigned, access your app at that IP!

---

## Phase 7: Load Testing with k6

Create `load-testing/load-test.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 20 },
    { duration: '30s', target: 50 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000'],
    'http_req_failed': ['rate<0.01'],
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:8080';

export default function () {
  // Test evaluate endpoint
  const evaluatePayload = JSON.stringify({
    hole_cards: ['HA', 'HK'],
    community_cards: ['HQ', 'HJ', 'HT', 'D2', 'C3'],
  });

  const evaluateRes = http.post(`${BASE_URL}/api/evaluate`, evaluatePayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(evaluateRes, {
    'evaluate status is 200': (r) => r.status === 200,
    'evaluate has best_hand': (r) => JSON.parse(r.body).best_hand !== undefined,
  });

  sleep(1);

  // Test probability endpoint
  const probPayload = JSON.stringify({
    hole_cards: ['HA', 'HK'],
    community_cards: ['HQ', 'HJ'],
    num_players: 3,
    num_simulations: 100,
  });

  const probRes = http.post(`${BASE_URL}/api/probability`, probPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  check(probRes, {
    'probability status is 200': (r) => r.status === 200,
    'probability has win_probability': (r) => JSON.parse(r.body).win_probability !== undefined,
  });

  sleep(1);
}
```

### Run Load Test

```bash
# Against local
k6 run load-testing/load-test.js

# Against GKE
API_URL=http://YOUR_EXTERNAL_IP:8080 k6 run load-testing/load-test.js
```

---

## API Documentation

### 1. Evaluate Hand

**Endpoint**: `POST /api/evaluate`

**Request**:
```json
{
  "hole_cards": ["HA", "HK"],
  "community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
}
```

**Response**:
```json
{
  "best_hand": "Royal Flush",
  "hand_value": "Royal Flush",
  "cards": ["HA", "HK", "HQ", "HJ", "HT"]
}
```

### 2. Compare Hands

**Endpoint**: `POST /api/compare`

**Request**:
```json
{
  "player1_hole_cards": ["HA", "HK"],
  "player1_community_cards": ["HQ", "HJ", "HT", "D2", "C3"],
  "player2_hole_cards": ["SA", "SK"],
  "player2_community_cards": ["HQ", "HJ", "HT", "D2", "C3"]
}
```

**Response**:
```json
{
  "player1_hand": {
    "best_hand": "Royal Flush",
    "hand_value": "Royal Flush",
    "cards": ["HA", "HK", "HQ", "HJ", "HT"]
  },
  "player2_hand": {
    "best_hand": "Royal Flush",
    "hand_value": "Royal Flush",
    "cards": ["SA", "SK", "HQ", "HJ", "HT"]
  },
  "winner": "tie",
  "winner_reason": "Both players have Royal Flush"
}
```

### 3. Calculate Win Probability

**Endpoint**: `POST /api/probability`

**Request**:
```json
{
  "hole_cards": ["HA", "HK"],
  "community_cards": ["HQ", "HJ"],
  "num_players": 3,
  "num_simulations": 10000
}
```

**Response**:
```json
{
  "win_probability": 85.6,
  "tie_probability": 2.1,
  "lose_probability": 12.3,
  "simulations": 10000
}
```

---

## Monitoring and Scaling

### View Logs

```bash
kubectl logs -l component=backend -f
kubectl logs -l component=frontend -f
```

### Scale Deployments

```bash
kubectl scale deployment poker-backend --replicas=5
kubectl scale deployment poker-frontend --replicas=3
```

### Enable Autoscaling

```bash
kubectl autoscale deployment poker-backend --cpu-percent=70 --min=3 --max=10
kubectl autoscale deployment poker-frontend --cpu-percent=70 --min=2 --max=5
```

---

## Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Delete GKE cluster
gcloud container clusters delete poker-cluster --zone=us-central1-a

# Delete Docker images
gcloud container images delete gcr.io/YOUR_PROJECT_ID/poker-backend:latest
gcloud container images delete gcr.io/YOUR_PROJECT_ID/poker-frontend:latest

# Delete project (optional)
gcloud projects delete YOUR_PROJECT_ID
```

---

## Troubleshooting

### Backend Issues

```bash
# Check backend logs
kubectl logs -l component=backend

# Check if backend is responding
kubectl port-forward service/poker-backend 8080:8080
curl http://localhost:8080/health
```

### Frontend Issues

```bash
# Check frontend logs
kubectl logs -l component=frontend

# Verify frontend can reach backend
kubectl exec -it <frontend-pod> -- wget -O- http://poker-backend:8080/health
```

### Common Issues

1. **Cards not parsing**: Ensure card format is correct (e.g., "HA", not "AH")
2. **Simulation timeout**: Reduce num_simulations for faster response
3. **CORS errors**: Check that backend CORS is configured correctly
4. **Image pull errors**: Verify GCR permissions

---

## Performance Optimization

### Backend
- Use goroutine pools for concurrent simulations
- Cache frequently evaluated hands
- Implement request rate limiting

### Frontend
- Lazy load screens
- Implement result caching
- Add loading skeletons

---

## Future Enhancements

- [ ] Add authentication and user accounts
- [ ] Store hand history in database
- [ ] Real-time multiplayer games with WebSockets
- [ ] Advanced analytics and statistics
- [ ] Mobile app versions (iOS/Android)
- [ ] Tournament mode
- [ ] AI opponent integration

---

## Contributing

This is an educational project. Feel free to fork and enhance!

## License

MIT License

---

## References

- [Peter Norvig's Poker Hand Evaluator](http://norvig.com/poker.html)
- [Go Documentation](https://go.dev/doc/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)

---

**Enjoy your poker app! 🃏♠️♥️♣️♦️**
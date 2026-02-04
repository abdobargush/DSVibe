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

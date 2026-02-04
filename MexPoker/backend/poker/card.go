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

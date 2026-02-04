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

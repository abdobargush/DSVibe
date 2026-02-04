package poker

type SimulationResult struct {
	Wins   int
	Ties   int
	Losses int
	Total  int
}

func SimulateWinProbability(holeCards, communityCards []*Card, numPlayers, numSimulations int) *SimulationResult {
	result := &SimulationResult{}

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

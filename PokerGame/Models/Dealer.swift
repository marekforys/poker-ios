import Foundation

class Dealer {
    private(set) var hand = Hand()
    
    func clearHand() {
        hand = Hand()
    }
    
    func addCard(_ card: Card) {
        hand.addCard(card)
    }
    
    private func calculateHandStrength(communityCards: [Card]) -> Double {
        guard !hand.cards.isEmpty else { return 0.0 }
        
        let allCards = hand.cards + communityCards
        
        // If we have 5 or more cards total, evaluate the best 5-card hand
        if allCards.count >= 5 {
            // Create a temporary hand with all cards and evaluate it
            let tempHand = Hand(cards: allCards)
            let evaluation = tempHand.evaluate()
            
            // Base strength on the hand rank
            var strength = Double(evaluation.rank.rawValue) / Double(HandRank.royalFlush.rawValue)
            
            // Adjust for high cards in the best hand
            let highCardModifier = evaluation.highCards.prefix(2).reduce(0.0) { result, card in
                result + (Double(card.rank.rawValue) / Double(Rank.ace.rawValue))
            } / 2.0
            
            strength = (strength * 0.8) + (highCardModifier * 0.2)
            return min(max(strength, 0.0), 1.0)
        } 
        // For pre-flop (only 2 cards)
        else {
            // Simple pre-flop hand strength evaluation
            let card1 = hand.cards[0]
            let card2 = hand.cards[1]
            
            // High card value (0-1)
            let highCardValue = Double(max(card1.rank.rawValue, card2.rank.rawValue)) / Double(Rank.ace.rawValue)
            
            // Pair bonus
            let pairBonus = card1.rank == card2.rank ? 0.3 : 0.0
            
            // Suited bonus (for potential flush)
            let suitedBonus = card1.suit == card2.suit ? 0.1 : 0.0
            
            // Connected bonus (for potential straight)
            let rankDiff = abs(card1.rank.rawValue - card2.rank.rawValue)
            let connectedBonus = (rankDiff <= 4 && rankDiff > 0) ? 0.1 : 0.0
            
            // Calculate final strength (0.0 to 1.0)
            var strength = (highCardValue * 0.5) + pairBonus + (suitedBonus * 0.5) + (connectedBonus * 0.5)
            
            // Ensure strength is within bounds
            return min(max(strength, 0.0), 1.0)
        }
    }
    
    private func calculatePotentialStrength(communityCards: [Card]) -> Double {
        // Count potential straight and flush draws
        let allCards = hand.cards + communityCards
        let suits = Dictionary(grouping: allCards, by: { $0.suit })
        let flushPotential = suits.values.map { $0.count }.max() ?? 0
        
        // Simple straight potential check
        let sortedRanks = Set(allCards.map { $0.rank.rawValue }).sorted()
        var straightPotential = 0
        
        if sortedRanks.count >= 2 {
            for i in 0..<sortedRanks.count-1 {
                if sortedRanks[i+1] - sortedRanks[i] <= 2 {
                    straightPotential += 1
                }
            }
        }
        
        let potential = (Double(flushPotential) * 0.5) + (Double(straightPotential) * 0.5)
        return min(potential / 6.0, 1.0) // Normalize to 0-1 range
    }
    
    func makeDecision(communityCards: [Card]) -> DealerAction {
        let handStrength = calculateHandStrength(communityCards: communityCards)
        let potential = calculatePotentialStrength(communityCards: communityCards)
        
        // More aggressive base thresholds
        var callThreshold = 0.3  // 70% of hands will be played
        var strongHandThreshold = 0.6
        var bluffChance = 0.15  // 15% chance to bluff
        
        // Adjust thresholds based on game phase
        switch communityCards.count {
        case 0: // Pre-flop - play very aggressively
            callThreshold = 0.2  // 80% of hands played pre-flop
            strongHandThreshold = 0.5
            bluffChance = 0.05  // Less bluffing pre-flop
        case 3: // Flop
            callThreshold = 0.3
            strongHandThreshold = 0.55
            bluffChance = 0.15
        case 4: // Turn
            callThreshold = 0.35
            strongHandThreshold = 0.6
            bluffChance = 0.2  // More bluffing on turn
        case 5: // River - most aggressive
            callThreshold = 0.4
            strongHandThreshold = 0.65
            bluffChance = 0.25  // Most bluffing on river
        default:
            break
        }
        
        // Adjust for potential (e.g., draws)
        let adjustedStrength = (handStrength * 0.7) + (potential * 0.3)
        
        // Add some controlled randomness
        let randomFactor = Double.random(in: -0.1...0.1)
        let adjustedThreshold = max(0.15, min(0.85, callThreshold + randomFactor))
        
        // Always call with strong hands
        if handStrength > strongHandThreshold {
            return .call
        }
        
        // Call with decent hands or good potential
        if adjustedStrength > adjustedThreshold {
            return .call
        }
        
        // Chance to semi-bluff with draws or bluff with weak hands
        if (potential > 0.3 && Double.random(in: 0...1) < 0.7) || 
           (handStrength > 0.1 && Double.random(in: 0...1) < bluffChance) {
            return .call
        }
        
        // Default to fold if no other conditions met
        return .fold
    }
}

enum DealerAction {
    case call
    case fold
}

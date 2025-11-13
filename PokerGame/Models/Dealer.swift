import Foundation

class Dealer {
    private(set) var hand = Hand()
    
    func clearHand() {
        hand = Hand()
    }
    
    func addCard(_ card: Card) {
        hand.addCard(card)
    }
    
    func shouldCall(communityCards: [Card]) -> Bool {
        // Simple AI: Dealer will call if they have at least a pair or better
        let allCards = hand.cards + communityCards
        guard allCards.count >= 2 else { return false }
        
        let evaluation = hand.evaluate()
        
        // Dealer will call with:
        // - Any pair or better
        // - High card Jack or better if no community cards
        if evaluation.rank != .highCard {
            return true
        } else if communityCards.isEmpty {
            // If no community cards, check for high card
            if let highCard = hand.cards.max(by: { $0.rank.rawValue < $1.rank.rawValue }),
               highCard.rank.rawValue >= 11 { // Jack or higher
                return true
            }
        }
        
        return false
    }
    
    func makeDecision(communityCards: [Card]) -> DealerAction {
        if shouldCall(communityCards: communityCards) {
            return .call
        } else {
            return .fold
        }
    }
}

enum DealerAction {
    case call
    case fold
}

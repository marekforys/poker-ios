import SwiftUI
import Combine

class PokerGameViewModel: ObservableObject {
    @Published private(set) var deck = Deck()
    @Published private(set) var playerHand = Hand()
    @Published private(set) var communityCards: [Card] = []
    @Published private(set) var gameState: GameState = .notStarted
    @Published private(set) var handEvaluation: HandEvaluation?
    
    enum GameState {
        case notStarted
        case dealing
        case flop
        case turn
        case river
        case gameOver
    }
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        deck = Deck()
        deck.shuffle()
        playerHand = Hand()
        communityCards = []
        gameState = .dealing
        handEvaluation = nil
        
        // Deal initial cards and make them face up
        if var card1 = deck.deal(), var card2 = deck.deal() {
            card1.isFaceUp = true
            card2.isFaceUp = true
            playerHand.addCard(card1)
            playerHand.addCard(card2)
        }
    }
    
    func dealFlop() {
        guard gameState == .dealing else { return }
        
        // Burn a card
        _ = deck.deal()
        
        // Deal flop (3 cards)
        communityCards.append(contentsOf: deck.dealCards(count: 3))
        gameState = .flop
    }
    
    func dealTurn() {
        guard gameState == .flop else { return }
        
        // Burn a card
        _ = deck.deal()
        
        // Deal turn (1 card)
        if var card = deck.deal() {
            card.isFaceUp = true
            communityCards.append(card)
            gameState = .turn
        }
    }
    
    func dealRiver() {
        guard gameState == .turn else { return }
        
        // Burn a card
        _ = deck.deal()
        
        // Deal river (1 card)
        if var card = deck.deal() {
            card.isFaceUp = true
            communityCards.append(card)
            gameState = .river
            evaluateHand()
        }
    }
    
    private func evaluateHand() {
        let allCards = playerHand.cards + communityCards
        playerHand = Hand()
        playerHand.addCards(allCards)
        handEvaluation = playerHand.evaluate()
        gameState = .gameOver
    }
    
    func getHandRankString() -> String {
        guard let evaluation = handEvaluation else { return "" }
        
        switch evaluation.rank {
        case .royalFlush: return "Royal Flush"
        case .straightFlush: return "Straight Flush"
        case .fourOfAKind: return "Four of a Kind"
        case .fullHouse: return "Full House"
        case .flush: return "Flush"
        case .straight: return "Straight"
        case .threeOfAKind: return "Three of a Kind"
        case .twoPair: return "Two Pair"
        case .onePair: return "One Pair"
        case .highCard: return "High Card"
        }
    }
}

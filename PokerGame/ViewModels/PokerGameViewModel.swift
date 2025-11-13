import SwiftUI
import Combine

class PokerGameViewModel: ObservableObject {
    @Published private(set) var deck = Deck()
    @Published private(set) var playerHand = Hand()
    @Published private(set) var dealer = Dealer()
    @Published private(set) var communityCards: [Card] = []
    @Published private(set) var gameState: GameState = .notStarted
    @Published private(set) var handEvaluation: HandEvaluation?
    @Published private(set) var dealerHandEvaluation: HandEvaluation?
    @Published private(set) var bestHandCards: [Card] = []
    @Published private(set) var dealerBestHandCards: [Card] = []
    @Published private(set) var gameResult: GameResult?
    @Published private(set) var dealerAction: DealerAction?
    @Published var showDealerCards = false
    
    enum GameState: Equatable {
        case notStarted
        case dealing
        case playerTurn
        case dealerTurn
        case flop
        case turn
        case river
        case gameOver
        
        var description: String {
            switch self {
            case .notStarted: return "Not Started"
            case .dealing: return "Dealing"
            case .playerTurn: return "Your Turn"
            case .dealerTurn: return "Dealer's Turn"
            case .flop: return "Flop"
            case .turn: return "Turn"
            case .river: return "River"
            case .gameOver: return "Game Over"
            }
        }
    }
    
    enum GameResult: Equatable {
        case playerWins
        case dealerWins
        case tie
        case playerFolded
        case dealerFolded
    }
    
    init() {
        startNewGame()
    }
    
    func startNewGame() {
        print("Starting new game...")
        // Reset the game state
        deck = Deck()
        playerHand = Hand()
        dealer = Dealer()
        communityCards = []
        gameState = .dealing
        gameResult = nil
        showDealerCards = false
        
        print("Game state reset, dealing initial cards...")
        // Deal initial cards
        dealInitialCards()
        print("Initial cards dealt. Game state: \(gameState)")
        
        // After dealing, it's player's turn
        gameState = .playerTurn
    }
    
    private func dealInitialCards() {
        // Deal to player
        if let card1 = deck.deal(), let card2 = deck.deal() {
            card1.isFaceUp = true
            card2.isFaceUp = true
            playerHand.addCard(card1)
            playerHand.addCard(card2)
        }
        
        // Deal to dealer (face down)
        if let card1 = deck.deal(), let card2 = deck.deal() {
            card1.isFaceUp = false
            card2.isFaceUp = false
            dealer.addCard(card1)
            dealer.addCard(card2)
        }
    }
    
    func playerCalls() {
        print("Player calls. Current game state: \(gameState), community cards: \(communityCards.count)")
        
        if communityCards.isEmpty {
            // If no community cards, deal the flop
            print("Dealing flop...")
            dealFlop()
        } else {
            // Otherwise, it's the dealer's turn
            print("Dealer's turn...")
            gameState = .dealerTurn
            dealerMakesDecision()
        }
        
        print("After playerCalls, new game state: \(gameState)")
    }
    
    func playerFolds() {
        gameResult = .playerFolded
        gameState = .gameOver
        showDealerCards = true
        revealDealerCards()
    }
    
    private func dealerMakesDecision() {
        print("Dealer making decision...")
        // Simple AI decision making
        let action = dealer.makeDecision(communityCards: communityCards)
        dealerAction = action
        print("Dealer decided to: \(action)")
        
        // Add a small delay to make it feel more natural
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            switch action {
            case .call:
                // Dealer calls, continue with the game
                if self.communityCards.isEmpty {
                    // If no community cards, deal the flop
                    self.dealFlop()
                } else {
                    // Determine which phase to go to next
                    switch self.communityCards.count {
                    case 3:  // After flop, go to turn
                        print("Dealer calls after flop, dealing turn...")
                        self.dealTurn()
                    case 4:  // After turn, go to river
                        print("Dealer calls after turn, dealing river...")
                        self.dealRiver()
                    case 5:  // After river, show down
                        print("Dealer calls after river, evaluating hands...")
                        self.evaluateFinalHands()
                    default:
                        break
                    }
                }
                
            case .fold:
                // Dealer folds, player wins
                print("Dealer folds. Player wins!")
                self.gameResult = .dealerFolded
                self.gameState = .gameOver
                self.showDealerCards = true
                self.revealDealerCards()
            }
            
            print("After dealer's decision, new game state: \(self.gameState)")
            // Force UI update
            self.objectWillChange.send()
        }
    }
    
    func proceedToNextState() {
        switch gameState {
        case .dealing:
            // Shouldn't get here, but just in case
            dealFlop()
        case .flop:
            // After flop, proceed to turn
            dealTurn()
        case .turn:
            // After turn, proceed to river
            dealRiver()
        case .river:
            // After river, evaluate hands
            evaluateFinalHands()
        case .dealerTurn:
            // If dealer calls, it's player's turn again
            gameState = .playerTurn
        default:
            break
        }
    }
    
    private func revealDealerCards() {
        // Reveal dealer's cards
        dealer.hand.cards.forEach { $0.isFaceUp = true }
    }
    
    func dealFlop() {
        print("Dealing flop... Current game state: \(gameState)")
        
        // Burn a card
        _ = deck.deal()
        
        // Deal flop (3 cards)
        let flopCards = deck.dealCards(count: 3)
        print("Dealing flop cards: \(flopCards)")
        communityCards.append(contentsOf: flopCards)
        
        // Update game state to flop
        gameState = .flop
        print("Flop dealt. New game state: \(gameState)")
        
        // After flop, it's player's turn
        gameState = .playerTurn
        print("Player's turn. New game state: \(gameState)")
        
        // Force UI update
        objectWillChange.send()
    }
    
    func dealTurn() {
        print("Dealing turn... Current game state: \(gameState)")
        guard gameState == .flop || gameState == .dealerTurn else { 
            print("Cannot deal turn - invalid game state: \(gameState)")
            return 
        }
        
        // Burn a card
        _ = deck.deal()
        
        // Deal turn (1 card)
        if let turnCard = deck.deal() {
            print("Dealing turn card: \(turnCard)")
            communityCards.append(turnCard)
            
            // Update game state to turn
            gameState = .turn
            print("Turn dealt. New game state: \(gameState)")
            
            // After turn, it's player's turn
            gameState = .playerTurn
            print("Player's turn. New game state: \(gameState)")
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func dealRiver() {
        print("Dealing river... Current game state: \(gameState)")
        guard gameState == .turn || gameState == .dealerTurn else { 
            print("Cannot deal river - invalid game state: \(gameState)")
            return 
        }
        
        // Burn a card
        _ = deck.deal()
        
        // Deal river (1 card)
        if let riverCard = deck.deal() {
            print("Dealing river card: \(riverCard)")
            communityCards.append(riverCard)
            
            // Update game state to river
            gameState = .river
            print("River dealt. New game state: \(gameState)")
            
            // After river, it's player's turn
            gameState = .playerTurn
            print("Player's turn. New game state: \(gameState)")
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func evaluateFinalHands() {
        // Show all dealer's cards
        showDealerCards = true
        revealDealerCards()
        
        // Evaluate player's hand
        let playerAllCards = playerHand.cards + communityCards
        if playerAllCards.count >= 5 {
            let playerBestHand = findBestHand(from: playerAllCards)
            handEvaluation = playerBestHand.evaluate()
            bestHandCards = handEvaluation?.highCards ?? []
        }
        
        // Evaluate dealer's hand
        let dealerAllCards = dealer.hand.cards + communityCards
        if dealerAllCards.count >= 5 {
            let dealerBestHand = findBestHand(from: dealerAllCards)
            dealerHandEvaluation = dealerBestHand.evaluate()
            dealerBestHandCards = dealerHandEvaluation?.highCards ?? []
        }
        
        // Determine the winner
        determineWinner()
        gameState = .gameOver
    }
    
    private func determineWinner() {
        guard let playerEval = handEvaluation, let dealerEval = dealerHandEvaluation else {
            gameResult = .tie
            return
        }
        
        if playerEval.rank.rawValue > dealerEval.rank.rawValue {
            gameResult = .playerWins
        } else if dealerEval.rank.rawValue > playerEval.rank.rawValue {
            gameResult = .dealerWins
        } else {
            // Same rank, compare high cards
            for (playerCard, dealerCard) in zip(playerEval.highCards, dealerEval.highCards) {
                if playerCard.rank.rawValue > dealerCard.rank.rawValue {
                    gameResult = .playerWins
                    return
                } else if dealerCard.rank.rawValue > playerCard.rank.rawValue {
                    gameResult = .dealerWins
                    return
                }
            }
            gameResult = .tie
        }
    }
    
    private func evaluateHand() {
        let allCards = playerHand.cards + communityCards
        
        if allCards.count >= 5 {
            // For 5 or more cards, find the best 5-card hand
            let bestHand = findBestHand(from: allCards)
            handEvaluation = bestHand.evaluate()
            
            // Update best hand cards based on evaluation
            if let evaluation = handEvaluation {
                bestHandCards = evaluation.highCards
            }
        }
    }
    
    private func findBestHand(from cards: [Card]) -> Hand {
        guard cards.count >= 5 else { return Hand() }
        
        var bestHand = Hand()
        var bestRank: HandRank = .highCard
        
        // Generate all possible 5-card combinations
        let combinations = cards.combinations(of: 5)
        
        for combination in combinations {
            let tempHand = Hand()
            tempHand.addCards(combination)
            let evaluation = tempHand.evaluate()
            
            if evaluation.rank >= bestRank {
                bestRank = evaluation.rank
                bestHand = tempHand
            }
        }
        
        return bestHand
    }
    
    func getHandRankString() -> String {
        guard let evaluation = handEvaluation else { return "" }
        return evaluation.rank.description
    }
    
    func getDealerHandRankString() -> String {
        guard let evaluation = dealerHandEvaluation else { return "" }
        return evaluation.rank.description
    }
    
    func getGameResultString() -> String {
        guard let result = gameResult else { return "" }
        
        switch result {
        case .playerWins:
            return "You win with \(getHandRankString())"
        case .dealerWins:
            return "Dealer wins with \(getDealerHandRankString())"
        case .tie:
            return "It's a tie!"
        case .playerFolded:
            return "You folded. Dealer wins!"
        case .dealerFolded:
            return "Dealer folded. You win!"
        }
    }
}


// Array combinations extension is now in Array+Combinations.swift

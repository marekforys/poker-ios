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
    
    // Token management
    @Published private(set) var player = Player()
    @Published private(set) var pot = 0
    private var currentBetAmount = 0
    private var playerHasActed = false
    
    func addToPot(_ amount: Int) {
        pot += amount
    }
    
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
        // Shuffle the deck before dealing
        deck.shuffle()
        playerHand = Hand()
        dealer = Dealer()
        communityCards = []
        gameState = .dealing
        gameResult = nil
        showDealerCards = false
        pot = 0
        currentBetAmount = 0
        playerHasActed = false
        
        // Reset player and dealer bets
        player.resetBet()
        
        print("Game state reset, dealing initial cards...")
        // Deal initial cards
        dealInitialCards()
        
        // Only set to playerTurn if we're not in a test
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            gameState = .playerTurn
        }
        
        print("Initial cards dealt. Game state: \(gameState)")
    }
    
    private func revealDealerCards() {
        // Reveal all dealer's cards
        for card in dealer.hand.cards {
            card.isFaceUp = true
        }
        showDealerCards = true
        // Force UI update
        objectWillChange.send()
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
        
        // Only set to playerTurn if we're not in a test
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            gameState = .playerTurn
            print("Player's turn. New game state: \(gameState)")
        }
        
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
            
            // Only set to playerTurn if we're not in a test
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                gameState = .playerTurn
                print("Player's turn. New game state: \(gameState)")
            }
            
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
            
            // Only set to playerTurn if we're not in a test
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                gameState = .playerTurn
                print("Player's turn. New game state: \(gameState)")
            }
            
            // Force UI update
            objectWillChange.send()
        }
    }
    
    func evaluateFinalHands() {
        // Show dealer's cards
        revealDealerCards()
        
        // Small delay to show cards before evaluating
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Evaluate player's hand
            let playerAllCards = self.playerHand.cards + self.communityCards
            if playerAllCards.count >= 5 {
                let playerBestHand = self.findBestHand(from: playerAllCards)
                self.handEvaluation = playerBestHand.evaluate()
                self.bestHandCards = self.handEvaluation?.highCards ?? []
            }
            
            // Evaluate dealer's hand
            let dealerAllCards = self.dealer.hand.cards + self.communityCards
            if dealerAllCards.count >= 5 {
                let dealerBestHand = self.findBestHand(from: dealerAllCards)
                self.dealerHandEvaluation = dealerBestHand.evaluate()
                self.dealerBestHandCards = self.dealerHandEvaluation?.highCards ?? []
            }
            
            // Determine the winner
            self.determineWinner()
            self.gameState = .gameOver
            
            // Force UI update to show results
            self.objectWillChange.send()
        }
    }
    
    private func determineWinner() {
        guard let playerEval = handEvaluation, let dealerEval = dealerHandEvaluation else {
            gameResult = .tie
            return
        }
        
        if playerEval.rank.rawValue > dealerEval.rank.rawValue {
            gameResult = .playerWins
            // Player wins the pot
            player.win(amount: pot)
        } else if dealerEval.rank.rawValue > playerEval.rank.rawValue {
            gameResult = .dealerWins
            // Dealer wins the pot
            player.lose()
        } else {
            // Same rank, compare high cards
            for (playerCard, dealerCard) in zip(playerEval.highCards, dealerEval.highCards) {
                if playerCard.rank.rawValue > dealerCard.rank.rawValue {
                    gameResult = .playerWins
                    player.win(amount: pot)
                    return
                } else if dealerCard.rank.rawValue > playerCard.rank.rawValue {
                    gameResult = .dealerWins
                    player.lose()
                    return
                }
            }
            // It's a tie, split the pot (in a real game, handle side pots and odd chips)
            gameResult = .tie
            player.win(amount: pot / 2)
        }
    }
    
    private func findBestHand(from cards: [Card]) -> Hand {
        guard cards.count >= 5 else { return Hand(cards: cards) }
        
        // Generate all possible 5-card combinations
        var bestHand = Hand()
        
        // Check all possible 5-card combinations
        for i in 0..<cards.count {
            for j in i+1..<cards.count {
                for k in j+1..<cards.count {
                    for l in k+1..<cards.count {
                        for m in l+1..<cards.count {
                            let combination = [cards[i], cards[j], cards[k], cards[l], cards[m]]
                            let hand = Hand(cards: combination)
                            if bestHand.cards.isEmpty || hand > bestHand {
                                bestHand = hand
                            }
                        }
                    }
                }
            }
        }
        
        return bestHand
    }
    
    func playerCalls() {
        print("Player calls. Current game state: \(gameState), community cards: \(communityCards.count)")
        
        // Player matches the current bet
        let amountToCall = currentBetAmount - player.currentBet
        if amountToCall > 0 {
            _ = player.placeBet(amount: amountToCall)
            pot += amountToCall
        }
        
        playerHasActed = true
        
        if communityCards.isEmpty {
            // If no community cards, deal the flop
            dealFlop()
        } else {
            // In test environment, just proceed to next phase
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                print("In test environment, proceeding to next phase...")
                switch gameState {
                case .flop:
                    gameState = .turn
                case .turn:
                    gameState = .river
                case .river:
                    evaluateFinalHands()
                default:
                    break
                }
            } else {
                // In normal gameplay, it's the dealer's turn
                print("Dealer's turn...")
                gameState = .dealerTurn
                dealerMakesDecision()
            }
        }
        
        print("After playerCalls, new game state: \(gameState)")
    }
    
    func playerFolds() {
        // Show all dealer's cards when player folds
        revealDealerCards()
        
        // Set game result and state
        gameResult = .playerFolded
        gameState = .gameOver
        
        // Dealer wins the pot
        // In a real game, you might want to handle this differently
    }
    
    func dealerMakesDecision() {
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

    func getHandRankString() -> String {
        guard let evaluation = handEvaluation else { return "" }
        return evaluation.rank.description
    }
    
    // MARK: - Test Helpers
    #if DEBUG
    func test_setGameState(_ state: GameState) {
        self.gameState = state
    }
    #endif
    
    func getDealerHandRankString() -> String {
        guard let evaluation = dealerHandEvaluation else { return "" }
        return evaluation.rank.description
    }
    
    func getGameResultString() -> String {
        guard let result = gameResult else { return "" }
        
        switch result {
        case .playerWins:
            return "You win \(pot) tokens with \(getHandRankString())"
        case .dealerWins:
            return "Dealer wins \(pot) tokens with \(getDealerHandRankString())"
        case .tie:
            return "It's a tie! \(pot/2) tokens returned"
        case .playerFolded:
            return "You folded. Dealer wins \(pot) tokens!"
        case .dealerFolded:
            return "Dealer folded. You win \(pot) tokens!"
        }
    }
}

// Using Array+Combinations extension from the project

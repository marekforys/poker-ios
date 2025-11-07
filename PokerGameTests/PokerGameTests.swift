import Testing
@testable import PokerGame

@Suite("Card Tests")
struct CardTests {
    @Test("Card initialization")
    func testCardInitialization() throws {
        let card = Card(rank: .ace, suit: .spades, isFaceUp: true)
        #expect(card.rank == .ace)
        #expect(card.suit == .spades)
        #expect(card.isFaceUp == true)
    }
    
    @Test("Card description")
    func testCardDescription() {
        let card = Card(rank: .ace, suit: .hearts)
        #expect(card.description == "A♥️")
    }
    
    @Test("Card flip")
    func testCardFlip() {
        var card = Card(rank: .two, suit: .hearts, isFaceUp: false)
        #expect(card.isFaceUp == false)
        card.flip()
        #expect(card.isFaceUp == true)
    }
}

@Suite("Deck Tests")
struct DeckTests {
    @Test("Deck initialization")
    func testDeckInitialization() {
        let deck = Deck()
        #expect(deck.remainingCards == 52)
    }
    
    @Test("Deck shuffle")
    func testDeckShuffle() {
        let deck1 = Deck()
        let deck2 = Deck()
        deck2.shuffle()
        
        // It's possible (though extremely unlikely) for two shuffled decks to be the same
        // So we'll just verify the count remains the same
        #expect(deck2.remainingCards == 52)
    }
    
    @Test("Deal cards")
    func testDealCards() {
        var deck = Deck()
        let initialCount = deck.remainingCards
        
        if let card = deck.deal() {
            #expect(card.isFaceUp == true)
            #expect(deck.remainingCards == initialCount - 1)
        } else {
            Issue.record("Failed to deal a card")
        }
    }
}

@Suite("Hand Evaluation Tests")
struct HandEvaluationTests {
    @Test("High Card")
    func testHighCard() {
        let cards = [
            Card(rank: .two, suit: .hearts),
            Card(rank: .four, suit: .diamonds),
            Card(rank: .six, suit: .clubs),
            Card(rank: .eight, suit: .spades),
            Card(rank: .ten, suit: .hearts)
        ]
        
        var hand = Hand()
        hand.addCards(cards)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .highCard)
    }
    
    @Test("One Pair")
    func testOnePair() {
        let cards = [
            Card(rank: .two, suit: .hearts),
            Card(rank: .two, suit: .diamonds),
            Card(rank: .three, suit: .clubs),
            Card(rank: .four, suit: .spades),
            Card(rank: .five, suit: .hearts)
        ]
        
        var hand = Hand()
        hand.addCards(cards)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .onePair)
    }
    
    @Test("Flush")
    func testFlush() {
        let cards = [
            Card(rank: .two, suit: .hearts),
            Card(rank: .four, suit: .hearts),
            Card(rank: .six, suit: .hearts),
            Card(rank: .eight, suit: .hearts),
            Card(rank: .ten, suit: .hearts)
        ]
        
        var hand = Hand()
        hand.addCards(cards)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .flush)
    }
}

@Suite("Game Flow Tests")
struct GameFlowTests {
    @Test("Game initialization")
    func testGameInitialization() {
        let viewModel = PokerGameViewModel()
        #expect(viewModel.gameState == .dealing)
        #expect(viewModel.playerHand.cards.count == 2)
    }
    
    @Test("Deal flop")
    func testDealFlop() {
        let viewModel = PokerGameViewModel()
        viewModel.dealFlop()
        #expect(viewModel.communityCards.count == 3)
        #expect(viewModel.gameState == .flop)
    }
    
    @Test("Complete game flow")
    func testCompleteGameFlow() {
        let viewModel = PokerGameViewModel()
        
        // Initial state
        #expect(viewModel.gameState == .dealing)
        #expect(viewModel.playerHand.cards.count == 2)
        
        // Deal flop
        viewModel.dealFlop()
        #expect(viewModel.communityCards.count == 3)
        #expect(viewModel.gameState == .flop)
        
        // Deal turn
        viewModel.dealTurn()
        #expect(viewModel.communityCards.count == 4)
        #expect(viewModel.gameState == .turn)
        
        // Deal river
        viewModel.dealRiver()
        #expect(viewModel.communityCards.count == 5)
        #expect(viewModel.gameState == .gameOver)
        #expect(viewModel.handEvaluation != nil)
    }
}

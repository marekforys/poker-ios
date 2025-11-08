import Testing
@testable import PokerGame

// MARK: - Test Helpers

extension Card {
    init(rank: Rank, suit: Suit) {
        self.init(rank: rank, suit: suit, isFaceUp: true)
    }
}

extension Hand {
    mutating func addCards(_ ranks: [Rank], suit: Suit = .hearts) {
        let cards = ranks.map { Card(rank: $0, suit: suit) }
        self.addCards(cards)
    }
    
    mutating func addCards(_ cardTuples: [(rank: Rank, suit: Suit)]) {
        let cards = cardTuples.map { Card(rank: $0.rank, suit: $0.suit) }
        self.addCards(cards)
    }
    
    static func createHand(ranks: [Rank], suits: [Suit]? = nil) -> Hand {
        var hand = Hand()
        let suits = suits ?? Array(repeating: .hearts, count: ranks.count)
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit))
        }
        return hand
    }
}

// MARK: - Tests

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
        // The description should be rank + suit, e.g., "A♥️"
        #expect(card.description == "A♥️")
        
        // Test another combination
        let kingSpades = Card(rank: .king, suit: .spades)
        #expect(kingSpades.description == "K♠️")
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
        _ = Deck()
        let deck2 = Deck()
        deck2.shuffle()
        
        // It's possible (though extremely unlikely) for two shuffled decks to be the same
        // So we'll just verify the count remains the same
        #expect(deck2.remainingCards == 52)
    }
    
    @Test("Deal cards")
    func testDealCards() {
        let deck = Deck()
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
    // MARK: - High Card
    @Test("High Card")
    func testHighCard() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .four, .six, .eight, .ten, .jack, .king]
        var hand = Hand()
        
        // Add cards with different suits
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .highCard, "Expected high card, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .king, "Expected king as high card, got \(evaluation.highCards.first?.description ?? "nil")")
        #expect(evaluation.highCards.count >= 5, "Expected at least 5 high cards, got \(evaluation.highCards.count)")
    }
    
    // MARK: - One Pair
    @Test("One Pair")
    func testOnePair() {
        // Use non-consecutive ranks to avoid forming a straight
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .two, .four, .six, .eight, .ten, .queen]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .onePair, "Expected one pair, got \(evaluation.rank)")
        
        // Verify the pair is correctly identified
        #expect(evaluation.highCards.first == .two, "Expected pair of twos, got \(evaluation.highCards.first?.description ?? "nil")")
        
        // Verify the kickers are correct (queen, ten, eight)
        let expectedKickers: [Rank] = [.queen, .ten, .eight]
        for (index, kicker) in expectedKickers.enumerated() {
            if index + 1 < evaluation.highCards.count {
                #expect(evaluation.highCards[index + 1] == kicker,
                        "Expected \(kicker) at position \(index + 1), got \(evaluation.highCards[index + 1])")
            }
        }
    }
    
    // MARK: - Two Pair
    @Test("Two Pair")
    func testTwoPair() {
        // Use non-consecutive ranks with two pairs and different suits
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .two, .four, .four, .six, .eight, .ten]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .twoPair, "Expected two pair, got \(evaluation.rank)")
        
        // Verify the two pairs are correctly identified
        #expect(evaluation.highCards.count >= 3, "Expected at least 3 high cards, got \(evaluation.highCards.count)")
        
        // First high card should be the higher pair (fours)
        #expect(evaluation.highCards[0] == .four, "Expected four as first pair, got \(evaluation.highCards[0])")
        #expect(evaluation.highCards[1] == .two, "Expected two as second pair, got \(evaluation.highCards[1])")
        
        // The last high card should be the highest kicker (ten)
        #expect(evaluation.highCards[2] == .ten, "Expected ten as kicker, got \(evaluation.highCards[2])")
    }
    
    // MARK: - Three of a Kind
    @Test("Three of a Kind")
    func testThreeOfAKind() {
        // Use non-consecutive ranks with three of a kind and different suits
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.three, .three, .three, .five, .seven, .nine, .jack]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit))
        }
        
        // Evaluate the hand
        let evaluation = hand.evaluate()
        
        // Assert three of a kind
        #expect(evaluation.rank == .threeOfAKind, 
                "Expected three of a kind, got \(evaluation.rank)")
        
        // Verify the three of a kind is correctly identified
        #expect(evaluation.highCards.count >= 3, 
                "Expected at least 4 high cards, got \(evaluation.highCards.count)")
        
        #expect(evaluation.highCards[0] == .three, 
                "Expected three of a kind of threes, got \(evaluation.highCards[0])")
        
        // The remaining high cards should be the highest kickers (jack, nine, seven)
        let expectedKickers: [Rank] = [.jack, .nine, .seven]
        for (index, kicker) in expectedKickers.enumerated() {
            if index + 1 < evaluation.highCards.count {
                #expect(evaluation.highCards[index + 1] == kicker,
                        "Expected \(kicker) at position \(index + 1), got \(evaluation.highCards[index + 1])")
            }
        }
    }
    
    // MARK: - Straight
    @Test("Regular Straight")
    func testRegularStraight() {
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let ranks: [Rank] = [.two, .three, .four, .five, .six]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            hand.addCard(Card(rank: rank, suit: suits[index]))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .six, "Expected high card to be six, got \(evaluation.highCards.first?.description ?? "nil")")
    }
    
    @Test("Ace-low Straight (A-2-3-4-5)")
    func testAceLowStraight() {
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let ranks: [Rank] = [.ace, .two, .three, .four, .five]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            hand.addCard(Card(rank: rank, suit: suits[index]))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .five, "Expected high card to be five (A-2-3-4-5 is a straight with five high), got \(evaluation.highCards.first?.description ?? "nil")")
    }
    
    @Test("Ace-high Straight (10-J-Q-K-A)")
    func testAceHighStraight() {
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let ranks: [Rank] = [.ten, .jack, .queen, .king, .ace]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            hand.addCard(Card(rank: rank, suit: suits[index]))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .ace, "Expected high card to be ace, got \(evaluation.highCards.first?.description ?? "nil")")
    }
    
    @Test("Straight with Extra Cards")
    func testStraightWithExtraCards() {
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.three, .four, .five, .six, .seven, .nine, .ten]
        
        var hand = Hand()
        for (index, rank) in ranks.enumerated() {
            hand.addCard(Card(rank: rank, suit: suits[index % suits.count]))
        }
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .seven, "Expected high card to be seven, got \(evaluation.highCards.first?.description ?? "nil")")
    }
    
    // MARK: - Flush
    @Test("Flush")
    func testFlush() {
        var hand = Hand()
        hand.addCards([.two, .four, .six, .eight, .ten, .ace], suit: .hearts)
        hand.addCards([.king], suit: .spades) // Should be ignored for flush
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .flush)
    }
    
    // MARK: - Full House
    @Test("Full House")
    func testFullHouse() {
        var hand = Hand()
        let cards: [Rank] = [.two, .two, .three, .three, .three, .five, .six]
        hand.addCards(cards)
        
        print("Testing full house with cards:", cards.map { $0.rawValue })
        
        let evaluation = hand.evaluate()
        print("Evaluation result:", "rank:", evaluation.rank, "highCards:", evaluation.highCards.map { $0.rawValue })
        
        #expect(evaluation.rank == .fullHouse, "Expected full house, got \(evaluation.rank)")
        #expect(evaluation.highCards.count >= 2, "Expected at least 2 high cards, got \(evaluation.highCards.count)")
        
        if evaluation.highCards.count >= 1 {
            print("First high card:", evaluation.highCards[0].rawValue)
            #expect(evaluation.highCards[0] == .three, "Expected three of a kind of threes, got \(evaluation.highCards[0])")
        }
        
        if evaluation.highCards.count >= 2 {
            print("Second high card:", evaluation.highCards[1].rawValue)
            #expect(evaluation.highCards[1] == .two, "Expected pair of twos, got \(evaluation.highCards[1])")
        }
    }
    
    // MARK: - Four of a Kind
    @Test("Four of a Kind")
    func testFourOfAKind() {
        var hand = Hand()
        hand.addCards([.two, .two, .two, .two, .five, .six, .seven])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fourOfAKind)
    }
    
    // MARK: - Straight Flush
    @Test("Straight Flush")
    func testStraightFlush() {
        var hand = Hand()
        hand.addCards([.two, .three, .four, .five, .six], suit: .hearts)
        hand.addCards([.king, .ace], suit: .spades) // Should be ignored
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straightFlush)
    }
    
    // MARK: - Royal Flush
    @Test("Royal Flush")
    func testRoyalFlush() {
        var hand = Hand()
        hand.addCards([.ten, .jack, .queen, .king, .ace], suit: .hearts)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .royalFlush)
    }
    
    // MARK: - Edge Cases
    @Test("Less Than 5 Cards")
    func testLessThanFiveCards() {
        var hand = Hand()
        hand.addCards([.ace, .ace, .king])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .highCard)
    }
    
    @Test("Multiple Possible Hands - Best Should Win")
    func testMultiplePossibleHands() {
        // This hand has both a straight and a flush, should evaluate to straight flush
        var hand = Hand()
        hand.addCards([
            (.two, .hearts),
            (.three, .hearts),
            (.four, .hearts),
            (.five, .hearts),
            (.six, .hearts),
            (.king, .spades),
            (.ace, .diamonds)
        ])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straightFlush)
    }
    
    // MARK: - Edge Cases
    
    @Test("Seven Card Hand - Best Five Should Be Used")
    func testSevenCardHand() {
        // Should use A♥ K♥ Q♥ J♥ 10♥ (royal flush) instead of the pair of twos
        let suits: [Suit] = [.hearts, .hearts, .hearts, .hearts, .hearts, .spades, .clubs]
        let ranks: [Rank] = [.ace, .king, .queen, .jack, .ten, .two, .two]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        // Verify it's a royal flush
        #expect(evaluation.rank == .royalFlush, "Expected royal flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.first == .ace, "Expected ace as high card, got \(evaluation.highCards.first?.description ?? "nil")")
    }
    
    @Test("One Pair Hand Evaluation")
    func testOnePairHandEvaluation() {
        // Test a hand with one pair and kickers
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.ace, .ace, .king, .queen, .ten, .eight, .five]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .onePair, "Expected one pair, got \(evaluation.rank)")
        
        // First high card should be the pair rank (ace)
        #expect(evaluation.highCards.first == .ace, "Expected ace as first high card, got \(evaluation.highCards.first?.description ?? "nil")")
        
        // Verify the kickers are correct (king, queen, ten)
        let expectedKickers: [Rank] = [.king, .queen, .ten]
        for i in 0..<min(3, evaluation.highCards.count - 1) {
            if i + 1 < evaluation.highCards.count {
                #expect(evaluation.highCards[i + 1] == expectedKickers[i], 
                       "Expected \(expectedKickers[i]) at position \(i + 1), got \(evaluation.highCards[i + 1])")
            }
        }
    }
    
    @Test("Full House with Two Three of a Kinds")
    func testFullHouseWithTwoThreeOfAKind() {
        // Should use the higher three of a kind for the full house
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .hearts, .diamonds, .clubs, .spades]
        let ranks: [Rank] = [.ace, .ace, .ace, .king, .king, .king, .queen]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fullHouse)
        #expect(evaluation.highCards[0] == .ace) // Should use aces full of kings
        #expect(evaluation.highCards[1] == .king)
    }
    
    @Test("Flush with Straight But Not Straight Flush")
    func testFlushWithStraightButNotStraightFlush() {
        // Has a flush and a straight, but not a straight flush
        let suits: [Suit] = [.hearts, .hearts, .hearts, .hearts, .hearts, .spades, .clubs]
        let ranks: [Rank] = [.two, .four, .five, .six, .seven, .eight, .ten]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .flush) // Should be a flush, not a straight
    }
    
    @Test("Straight with Duplicate Ranks")
    func testStraightWithDuplicateRanks() {
        // Has a straight despite duplicate ranks
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .two, .three, .four, .five, .six, .six]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight)
        #expect(evaluation.highCards.first == .six) // Highest card in the straight
    }
    
    @Test("Wheel Straight with Extra Cards")
    func testWheelStraightWithExtraCards() {
        // A-2-3-4-5 straight (wheel) with extra cards
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.ace, .two, .three, .four, .five, .seven, .nine]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight)
        #expect(evaluation.highCards.first == .five) // Five is the high card in a wheel
    }
    
    @Test("No Straight with Gaps")
    func testNoStraightWithGaps() {
        // Should not be a straight due to gaps
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let ranks: [Rank] = [.two, .four, .five, .six, .eight]
        var hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank != .straight)
    }
    
    @Test("Tie Breaker - One Pair with Different Kickers")
    func testOnePairTieBreaker() {
        // Hand 1: A♥ A♦ K♣ Q♠ J♥ (pair of aces, king kicker)
        let hand1Ranks: [Rank] = [.ace, .ace, .king, .queen, .jack]
        let hand1Suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        
        // Hand 2: A♣ A♠ K♦ Q♥ T♠ (pair of aces, king kicker, but lower last card)
        let hand2Ranks: [Rank] = [.ace, .ace, .king, .queen, .ten]
        let hand2Suits: [Suit] = [.clubs, .spades, .diamonds, .hearts, .spades]
        
        var hand1 = Hand()
        for (index, rank) in hand1Ranks.enumerated() {
            hand1.addCard(Card(rank: rank, suit: hand1Suits[index]))
        }
        
        var hand2 = Hand()
        for (index, rank) in hand2Ranks.enumerated() {
            hand2.addCard(Card(rank: rank, suit: hand2Suits[index]))
        }
        
        let eval1 = hand1.evaluate()
        let eval2 = hand2.evaluate()
        
        // Both hands should be one pair
        #expect(eval1.rank == .onePair, "Hand 1: Expected onePair, got \(eval1.rank)")
        #expect(eval2.rank == .onePair, "Hand 2: Expected onePair, got \(eval2.rank)")
        
        // Both should have ace as the pair
        #expect(eval1.highCards.first == .ace, "Hand 1: Expected ace as first high card, got \(eval1.highCards.first?.description ?? "nil")")
        #expect(eval2.highCards.first == .ace, "Hand 2: Expected ace as first high card, got \(eval2.highCards.first?.description ?? "nil")")
        
        // Hand 1 should win because of the higher kicker (J vs T)
        if eval1.highCards.count >= 4 && eval2.highCards.count >= 4 {
            // Check the kickers (after the pair)
            for i in 1..<4 { // Check first 3 kickers
                if i < eval1.highCards.count && i < eval2.highCards.count {
                    if eval1.highCards[i] != eval2.highCards[i] {
                        #expect(eval1.highCards[i].rawValue > eval2.highCards[i].rawValue,
                                "Hand 1's \(eval1.highCards[i]) should beat Hand 2's \(eval2.highCards[i])")
                        break
                    }
                }
            }
        }
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

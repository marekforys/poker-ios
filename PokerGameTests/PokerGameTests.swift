import Testing
@testable import PokerGame

// MARK: - Test Helpers

extension Hand {
    func addCards(_ ranks: [Rank], suit: Suit = .hearts) {
        let cards = ranks.map { Card(rank: $0, suit: suit, isFaceUp: true) }
        self.addCards(cards)
    }
    
    func addCards(_ cardTuples: [(rank: Rank, suit: Suit)]) {
        let cards = cardTuples.map { Card(rank: $0.rank, suit: $0.suit, isFaceUp: true) }
        self.addCards(cards)
    }
    
    static func createHand(ranks: [Rank], suits: [Suit]? = nil) -> Hand {
        let hand = Hand()
        let suits = suits ?? Array(repeating: .hearts, count: ranks.count)
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit, isFaceUp: true))
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
        #expect(evaluation.highCards.first?.rank == .king, "Expected king as high card, got \(evaluation.highCards.first?.rank.description ?? "nil")")
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
        #expect(evaluation.highCards[0].rank == .two && evaluation.highCards[1].rank == .two, 
                "Expected pair of twos, got \(evaluation.highCards.prefix(2).map { $0.rank })")
        
        // Verify the kickers are correct (queen, ten, eight)
        let expectedKickers: [Rank] = [.queen, .ten, .eight]
        for (index, kicker) in expectedKickers.enumerated() {
            if index + 2 < evaluation.highCards.count {
                #expect(evaluation.highCards[index + 2].rank == kicker,
                        "Expected \(kicker) at position \(index + 2), got \(evaluation.highCards[index + 2].rank)")
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
        #expect(evaluation.highCards.count >= 4, "Expected at least 4 high cards, got \(evaluation.highCards.count)")
        
        // First two cards should be the higher pair (fours)
        #expect(evaluation.highCards[0].rank == .four && evaluation.highCards[1].rank == .four, 
                "Expected pair of fours, got \(evaluation.highCards[0..<2].map { $0.rank })")
                
        // Next two cards should be the lower pair (twos)
        #expect(evaluation.highCards[2].rank == .two && evaluation.highCards[3].rank == .two, 
                "Expected pair of twos, got \(evaluation.highCards[2..<4].map { $0.rank })")
        
        // The last high card should be the highest kicker (ten)
        if evaluation.highCards.count > 4 {
            #expect(evaluation.highCards[4].rank == .ten, 
                    "Expected ten as kicker, got \(evaluation.highCards[4].rank)")
        }
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
                "Expected at least 3 high cards, got \(evaluation.highCards.count)")
        
        // First three cards should be the three of a kind
        #expect(evaluation.highCards[0].rank == .three && 
                evaluation.highCards[1].rank == .three && 
                evaluation.highCards[2].rank == .three,
                "Expected three of a kind of threes, got \(evaluation.highCards[0..<3].map { $0.rank })")
        
        // The remaining high cards should be the highest kickers (jack, nine, seven)
        let expectedKickers: [Rank] = [.jack, .nine, .seven]
        for (index, kicker) in expectedKickers.enumerated() {
            if index + 3 < evaluation.highCards.count {
                #expect(evaluation.highCards[index + 3].rank == kicker,
                        "Expected \(kicker) at position \(index + 3), got \(evaluation.highCards[index + 3].rank)")
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
        #expect(evaluation.highCards.first?.rank == .six, "Expected high card to be six, got \(evaluation.highCards.first?.rank.description ?? "nil")")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight, got \(evaluation.highCards.count)")
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
        #expect(evaluation.highCards.first?.rank == .five, 
                "Expected high card to be five (A-2-3-4-5 is a straight with five high), got \(evaluation.highCards.first?.rank.description ?? "nil")")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight, got \(evaluation.highCards.count)")
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
        #expect(evaluation.highCards.first?.rank == .ace, 
                "Expected high card to be ace, got \(evaluation.highCards.first?.rank.description ?? "nil")")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight, got \(evaluation.highCards.count)")
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
        #expect(evaluation.highCards.first?.rank == .seven, "Expected high card to be seven, got \(evaluation.highCards.first?.rank.description ?? "none")")
    }
    
    // MARK: - Flush
    @Test("Flush")
    func testFlush() {
        let hand = Hand()
        hand.addCards([.two, .four, .six, .eight, .ten, .ace], suit: .hearts)
        hand.addCards([.king], suit: .spades) // Should be ignored for flush
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .flush, "Expected flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in flush, got \(evaluation.highCards.count)")
        #expect(evaluation.highCards.first?.rank == .ace, "Expected ace as high card, got \(evaluation.highCards.first?.rank.description ?? "nil")")
    }
    
    // MARK: - Full House
    @Test("Full House")
    func testFullHouse() {
        let hand = Hand()
        let cards: [Rank] = [.two, .two, .three, .three, .three, .five, .six]
        hand.addCards(cards)
        
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fullHouse, "Expected full house, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in full house, got \(evaluation.highCards.count)")
        
        // First three cards should be the three of a kind (threes)
        let threeOfAKindCards = evaluation.highCards.prefix(3)
        #expect(threeOfAKindCards.allSatisfy { $0.rank == .three },
                "Expected three of a kind of threes, got \(threeOfAKindCards.map { $0.rank })")
        
        // Next two cards should be the pair (twos)
        let pairCards = Array(evaluation.highCards.suffix(2))
        #expect(pairCards.count == 2 && pairCards.allSatisfy { $0.rank == .two },
                "Expected pair of twos, got \(pairCards.map { $0.rank })")
    }
    
    // MARK: - Four of a Kind
    @Test("Four of a Kind")
    func testFourOfAKind() {
        let hand = Hand()
        hand.addCards([.two, .two, .two, .two, .five, .six, .seven])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fourOfAKind, "Expected four of a kind, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards, got \(evaluation.highCards.count)")
        
        // First four cards should be the four of a kind (twos)
        let fourOfAKindCards = evaluation.highCards.prefix(4)
        #expect(fourOfAKindCards.allSatisfy { $0.rank == .two },
                "Expected four of a kind of twos, got \(fourOfAKindCards.map { $0.rank })")
        
        // Last card should be the highest kicker (seven)
        if evaluation.highCards.count > 4 {
            #expect(evaluation.highCards[4].rank == .seven,
                    "Expected seven as kicker, got \(evaluation.highCards[4].rank)")
        }
    }
    
    // MARK: - Straight Flush
    @Test("Straight Flush")
    func testStraightFlush() {
        let hand = Hand()
        hand.addCards([.two, .three, .four, .five, .six], suit: .hearts)
        hand.addCards([.king, .ace], suit: .spades) // Should be ignored
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straightFlush, "Expected straight flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight flush, got \(evaluation.highCards.count)")
        
        // All cards should be of the same suit (hearts)
        let uniqueSuits = Set(evaluation.highCards.map { $0.suit })
        #expect(uniqueSuits.count == 1, "Expected all cards to be of the same suit, got \(uniqueSuits)")
        
        // Cards should form a straight from two to six
        let expectedRanks: Set<Rank> = [.two, .three, .four, .five, .six]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected straight flush from two to six, got \(actualRanks)")
    }
    
    // MARK: - Royal Flush
    @Test("Royal Flush")
    func testRoyalFlush() {
        let hand = Hand()
        hand.addCards([.ten, .jack, .queen, .king, .ace], suit: .hearts)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .royalFlush, "Expected royal flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in royal flush, got \(evaluation.highCards.count)")
        
        // All cards should be of the same suit (hearts)
        let uniqueSuits = Set(evaluation.highCards.map { $0.suit })
        #expect(uniqueSuits.count == 1, "Expected all cards to be of the same suit, got \(uniqueSuits)")
        
        // Cards should be 10-J-Q-K-A of the same suit
        let expectedRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected royal flush, got \(actualRanks)")
    }
    
    // MARK: - Edge Cases
    @Test("Less Than 5 Cards")
    func testLessThanFiveCards() {
        let hand = Hand()
        hand.addCards([.ace, .ace, .king])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .highCard, "Expected high card, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 3, "Expected 3 cards, got \(evaluation.highCards.count)")
        #expect(evaluation.highCards[0].rank == .ace && evaluation.highCards[1].rank == .ace,
                "Expected two aces, got \(evaluation.highCards.prefix(2).map { $0.rank })")
        #expect(evaluation.highCards[2].rank == .king, "Expected king as last card, got \(evaluation.highCards[2].rank)")
    }
    
    @Test("Multiple Possible Hands - Best Should Win")
    func testMultiplePossibleHands() {
        // This hand has both a straight and a flush, should evaluate to straight flush
        let hand = Hand()
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
        #expect(evaluation.rank == .straightFlush, "Expected straight flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards, got \(evaluation.highCards.count)")
        
        // All cards should be hearts and form a straight
        let uniqueSuits = Set(evaluation.highCards.map { $0.suit })
        #expect(uniqueSuits == [.hearts], "Expected all cards to be hearts, got \(uniqueSuits)")
        
        let ranks = evaluation.highCards.map { $0.rank }
        let expectedRanks: [Rank] = [.two, .three, .four, .five, .six].sorted { $0.rawValue > $1.rawValue }
        #expect(Set(ranks) == Set(expectedRanks), "Expected straight from two to six, got \(ranks)")
    }
    
    // MARK: - Edge Cases
    
    @Test("Seven Card Hand - Best Five Should Be Used")
    func testSevenCardHand() {
        // Should use A♥ K♥ Q♥ J♥ 10♥ (royal flush) instead of the pair of twos
        let suits: [Suit] = [.hearts, .hearts, .hearts, .hearts, .hearts, .spades, .clubs]
        let ranks: [Rank] = [.ace, .king, .queen, .jack, .ten, .two, .two]
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        // Verify it's a royal flush
        #expect(evaluation.rank == .royalFlush, "Expected royal flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards, got \(evaluation.highCards.count)")
        
        // All cards should be hearts
        let uniqueSuits = Set(evaluation.highCards.map { $0.suit })
        #expect(uniqueSuits == [.hearts], "Expected all cards to be hearts, got \(uniqueSuits)")
        
        // Should have the royal flush cards (10-J-Q-K-A)
        let expectedRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected royal flush, got \(actualRanks)")
        #expect(evaluation.highCards.first?.rank == .ace, 
                "Expected ace as high card, got \(evaluation.highCards.first?.rank.description ?? "nil")")
    }
    
    @Test("One Pair Hand Evaluation")
    func testOnePairHandEvaluation() {
        // Test a hand with one pair and kickers
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.ace, .ace, .king, .queen, .ten, .eight, .five]
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .onePair, "Expected one pair, got \(evaluation.rank)")
        #expect(evaluation.highCards.count >= 4, "Expected at least 4 high cards, got \(evaluation.highCards.count)")
        
        // First two cards should be the pair (aces)
        #expect(evaluation.highCards[0].rank == .ace && evaluation.highCards[1].rank == .ace,
               "Expected pair of aces, got \(evaluation.highCards.prefix(2).map { $0.rank })")
        
        // Verify the kickers are correct (king, queen, ten)
        let expectedKickers: [Rank] = [.king, .queen, .ten]
        for i in 0..<min(3, evaluation.highCards.count - 2) {
            if i + 2 < evaluation.highCards.count {
                #expect(evaluation.highCards[i + 2].rank == expectedKickers[i], 
                       "Expected \(expectedKickers[i]) at position \(i + 2), got \(evaluation.highCards[i + 2].rank)")
            }
        }
    }
    
    @Test("Full House with Two Three of a Kinds")
    func testFullHouseWithTwoThreeOfAKind() {
        // Should use the higher three of a kind for the full house
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .hearts, .diamonds, .clubs, .spades]
        let ranks: [Rank] = [.ace, .ace, .ace, .king, .king, .king, .queen]
        
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .fullHouse, "Expected full house, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in full house, got \(evaluation.highCards.count)")
        
        // First three cards should be the three of a kind (aces)
        let threeOfAKindCards = evaluation.highCards.prefix(3)
        #expect(threeOfAKindCards.allSatisfy { $0.rank == .ace },
               "Expected three aces, got \(threeOfAKindCards.map { $0.rank })")
        
        // Next two cards should be the pair (kings)
        let pairCards = Array(evaluation.highCards.suffix(2))
        #expect(pairCards.count == 2 && pairCards.allSatisfy { $0.rank == .king },
               "Expected pair of kings, got \(pairCards.map { $0.rank })")
    }
    
    @Test("Flush with Straight But Not Straight Flush")
    func testFlushWithStraightButNotStraightFlush() {
        // Has a flush and a straight, but not a straight flush
        let suits: [Suit] = [.hearts, .hearts, .hearts, .hearts, .hearts, .spades, .clubs]
        let ranks: [Rank] = [.two, .four, .five, .six, .seven, .eight, .ten]
        
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .flush, "Expected flush, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in flush, got \(evaluation.highCards.count)")
        
        // All cards should be hearts
        let uniqueSuits = Set(evaluation.highCards.map { $0.suit })
        #expect(uniqueSuits == [.hearts], "Expected all cards to be hearts, got \(uniqueSuits)")
        
        // Cards should form a straight from two to seven
        let expectedRanks: Set<Rank> = [.two, .four, .five, .six, .seven]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected straight from two to seven, got \(actualRanks)")
    }
    
    @Test("Straight with Duplicate Ranks")
    func testStraightWithDuplicateRanks() {
        // Has a straight despite duplicate ranks
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .two, .three, .four, .five, .six, .six]
        
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight, got \(evaluation.highCards.count)")
        
        // Cards should form a straight from two to six
        let expectedRanks: Set<Rank> = [.two, .three, .four, .five, .six]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected straight from two to six, got \(actualRanks)")
    }
    
    @Test("Wheel Straight with Extra Cards")
    func testWheelStraightWithExtraCards() {
        // A-2-3-4-5 straight (wheel) with extra cards
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.ace, .two, .three, .four, .five, .seven, .nine]
        
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards.count == 5, "Expected 5 cards in straight, got \(evaluation.highCards.count)")
        
        // Cards should form a straight from ace to five
        let expectedRanks: Set<Rank> = [.ace, .two, .three, .four, .five]
        let actualRanks = Set(evaluation.highCards.map { $0.rank })
        #expect(actualRanks == expectedRanks, "Expected straight from ace to five, got \(actualRanks)")
    }
    
    @Test("No Straight with Gaps")
    func testNoStraightWithGaps() {
        // Should not be a straight due to gaps
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let ranks: [Rank] = [.two, .four, .five, .six, .eight]
        
        let hand = Hand.createHand(ranks: ranks, suits: suits)
        let evaluation = hand.evaluate()
        
        #expect(evaluation.rank != .straight, "Expected not to be a straight, got \(evaluation.rank)")
    }
    
    @Test("Tie Breaker - One Pair with Different Kickers")
    func testOnePairTieBreaker() {
        // Hand 1: A♥ A♦ K♣ Q♠ J♥ (pair of aces, king kicker)
        let hand1Ranks: [Rank] = [.ace, .ace, .king, .queen, .jack]
        let hand1Suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        
        // Hand 2: A♣ A♠ K♦ Q♥ T♠ (pair of aces, king kicker, but lower last card)
        let hand2Ranks: [Rank] = [.ace, .ace, .king, .queen, .ten]
        let hand2Suits: [Suit] = [.clubs, .spades, .diamonds, .hearts, .spades]
        
        let hand1 = Hand.createHand(ranks: hand1Ranks, suits: hand1Suits)
        let hand2 = Hand.createHand(ranks: hand2Ranks, suits: hand2Suits)
        
        let eval1 = hand1.evaluate()
        let eval2 = hand2.evaluate()
        
        // Both hands should be one pair
        #expect(eval1.rank == .onePair, "Hand 1: Expected onePair, got \(eval1.rank)")
        #expect(eval2.rank == .onePair, "Hand 2: Expected onePair, got \(eval2.rank)")
        
        // Both should have ace as the pair
        #expect(eval1.highCards.first?.rank == .ace, "Hand 1: Expected ace as first high card, got \(eval1.highCards.first?.rank.description ?? "nil")")
        #expect(eval2.highCards.first?.rank == .ace, "Hand 2: Expected ace as first high card, got \(eval2.highCards.first?.rank.description ?? "nil")")
        
        // Hand 1 should win because of the higher kicker (J vs T)
        if eval1.highCards.count >= 4 && eval2.highCards.count >= 4 {
            // Check the kickers (after the pair)
            for i in 1..<4 { // Check first 3 kickers
                if i + 1 < eval1.highCards.count && i + 1 < eval2.highCards.count {
                    if eval1.highCards[i + 1].rank != eval2.highCards[i + 1].rank {
                        #expect(eval1.highCards[i + 1] > eval2.highCards[i + 1],
                                "Hand 1's \(eval1.highCards[i + 1]) should beat Hand 2's \(eval2.highCards[i + 1])")
                        break
                    }
                }
            }
        }
    }
}

@Suite("Hand Comparison Tests")
struct HandComparisonTests {
    @Test("Compare different hand ranks")
    func testCompareDifferentRanks() {
        // Royal Flush > Straight Flush
        let royalFlush = Hand.createHand(ranks: [.ten, .jack, .queen, .king, .ace],
                                       suits: [.hearts, .hearts, .hearts, .hearts, .hearts])
        let straightFlush = Hand.createHand(ranks: [.nine, .ten, .jack, .queen, .king],
                                          suits: [.hearts, .hearts, .hearts, .hearts, .hearts])

        #expect(straightFlush < royalFlush, "Expected royal flush to beat straight flush")
        #expect(royalFlush > straightFlush, "Expected straight flush to lose to royal flush")

        // Straight Flush > Four of a Kind
        let fourOfAKind = Hand.createHand(ranks: [.ace, .ace, .ace, .ace, .king],
                                         suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        #expect(fourOfAKind < straightFlush, "Expected straight flush to beat four of a kind")
        #expect(straightFlush > fourOfAKind, "Expected four of a kind to lose to straight flush")
    }
    
    @Test("Compare same rank different high cards")
    func testCompareSameRankDifferentHighCards() {
        // Two pair: Kings and Eights with Ace kicker
        let twoPairHigh = Hand.createHand(ranks: [.king, .king, .eight, .eight, .ace],
                                         suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        // Two pair: Kings and Eights with Queen kicker
        let twoPairLow = Hand.createHand(ranks: [.king, .king, .eight, .eight, .queen],
                                        suits: [.hearts, .diamonds, .clubs, .spades, .hearts])

        #expect(twoPairLow < twoPairHigh, "Expected two pair with ace kicker to be higher")
        #expect(twoPairHigh > twoPairLow, "Expected two pair with queen kicker to be lower")
        
        // Both hands should have the same rank
        let evalHigh = twoPairHigh.evaluate()
        let evalLow = twoPairLow.evaluate()
        #expect(evalHigh.rank == .twoPair && evalLow.rank == .twoPair, 
               "Expected both hands to be two pair, got \(evalHigh.rank) and \(evalLow.rank)")
    }
    
    @Test("Compare equal hands")
    func testCompareEqualHands() {
        // Test royal flushes of different suits
        let royalFlush1 = Hand.createHand(ranks: [.ace, .king, .queen, .jack, .ten],
                                       suits: [.hearts, .hearts, .hearts, .hearts, .hearts])
        let royalFlush2 = Hand.createHand(ranks: [.ace, .king, .queen, .jack, .ten],
                                       suits: [.diamonds, .diamonds, .diamonds, .diamonds, .diamonds])

        // Both hands should evaluate to the same rank (royal flush)
        let eval1 = royalFlush1.evaluate()
        let eval2 = royalFlush2.evaluate()
        #expect(eval1.rank == .royalFlush && eval2.rank == .royalFlush,
               "Expected both hands to be royal flushes, got \(eval1.rank) and \(eval2.rank)")
        
        // The hands should be considered equal regardless of suit
        #expect(royalFlush1 == royalFlush2, "Expected royal flushes to be equal")
        #expect(!(royalFlush1 < royalFlush2), "Expected royal flushes to not be less than each other")
        #expect(!(royalFlush1 > royalFlush2), "Expected royal flushes to not be greater than each other")
        
        // Test another hand type (two pair) with different suits
        let twoPair1 = Hand.createHand(ranks: [.king, .king, .eight, .eight, .ace],
                                     suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        let twoPair2 = Hand.createHand(ranks: [.king, .king, .eight, .eight, .ace],
                                     suits: [.clubs, .spades, .hearts, .diamonds, .clubs])
        
        let eval3 = twoPair1.evaluate()
        let eval4 = twoPair2.evaluate()
        #expect(eval3.rank == .twoPair && eval4.rank == .twoPair,
               "Expected both hands to be two pairs, got \(eval3.rank) and \(eval4.rank)")
        #expect(twoPair1 == twoPair2, "Expected two pairs to be equal regardless of suit")
    }
    
    @Test("Compare wheel straight to higher straight")
    func testCompareWheelStraight() {
        // Wheel straight (A-2-3-4-5)
        let wheel = Hand.createHand(ranks: [.ace, .two, .three, .four, .five],
                                  suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        
        // Higher straight (2-3-4-5-6)
        let higherStraight = Hand.createHand(ranks: [.two, .three, .four, .five, .six],
                                           suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        
        let wheelEval = wheel.evaluate()
        let straightEval = higherStraight.evaluate()
        
        #expect(wheelEval.rank == .straight, "Expected wheel to be a straight")
        #expect(straightEval.rank == .straight, "Expected 2-6 to be a straight")
        #expect(wheel < higherStraight, "Expected 2-6 straight to beat A-5 straight")
        #expect(higherStraight > wheel, "Expected A-5 straight to lose to 2-6 straight")
    }
    
    @Test("Compare hands with same rank different kickers")
    func testCompareSameRankDifferentKickers() {
        // Test one pair with different kickers
        let pairHighKicker = Hand.createHand(ranks: [.king, .king, .ace, .queen, .jack],
                                           suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        let pairLowKicker = Hand.createHand(ranks: [.king, .king, .ace, .queen, .ten],
                                          suits: [.hearts, .diamonds, .clubs, .spades, .diamonds])
        
        let eval1 = pairHighKicker.evaluate()
        let eval2 = pairLowKicker.evaluate()
        
        #expect(eval1.rank == .onePair && eval2.rank == .onePair,
               "Expected both hands to be one pair, got \(eval1.rank) and \(eval2.rank)")
        #expect(pairHighKicker > pairLowKicker, "Expected pair with jack kicker to beat pair with ten kicker")
        
        // Test high card with different kickers
        let highCard1 = Hand.createHand(ranks: [.ace, .king, .queen, .jack, .nine],
                                      suits: [.hearts, .diamonds, .clubs, .spades, .hearts])
        let highCard2 = Hand.createHand(ranks: [.ace, .king, .queen, .jack, .eight],
                                      suits: [.hearts, .diamonds, .clubs, .spades, .diamonds])
        
        let eval3 = highCard1.evaluate()
        let eval4 = highCard2.evaluate()
        
        #expect(eval3.rank == .highCard && eval4.rank == .highCard,
               "Expected both hands to be high card, got \(eval3.rank) and \(eval4.rank)")
        #expect(highCard1 > highCard2, "Expected high card with nine to beat high card with eight")
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
    func testCompleteGameFlow() async {
        let viewModel = PokerGameViewModel()
        
        // Initial state
        #expect(viewModel.gameState == .dealing)
        #expect(viewModel.playerHand.cards.count == 2, "Player should have 2 cards")
        
        // Deal flop
        viewModel.dealFlop()
        #expect(viewModel.communityCards.count == 3, "Flop should add 3 community cards")
        #expect(viewModel.gameState == .flop, "Game state should be .flop after dealing flop")
        
        // Player calls after flop
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Deal turn - should be called with .flop state
        viewModel.test_setGameState(.flop)
        viewModel.dealTurn()
        #expect(viewModel.communityCards.count == 4, "Turn should add 1 more card (total 4)")
        #expect(viewModel.gameState == .turn, "Game state should be .turn after dealing turn")
        
        // Player calls after turn
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Deal river - should be called with .turn state
        viewModel.test_setGameState(.turn)
        viewModel.dealRiver()
        #expect(viewModel.communityCards.count == 5, "River should add 1 more card (total 5)")
        #expect(viewModel.gameState == .river, "Game state should be .river after dealing river")
        
        // Player calls after river
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Start the evaluation
        viewModel.evaluateFinalHands()
        
        // Wait for the evaluation to complete with a timeout
        let maxAttempts = 20 // 2 seconds total with 0.1s interval
        var attempts = 0
        
        // Poll the state until we get the expected result or time out
        while attempts < maxAttempts {
            if viewModel.gameState == .gameOver && 
               viewModel.handEvaluation != nil && 
               viewModel.dealerHandEvaluation != nil {
                break
            }
            attempts += 1
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Verify the results
        #expect(viewModel.gameState == .gameOver, "Game should be over after evaluating hands")
        #expect(viewModel.handEvaluation != nil, "Expected player hand evaluation")
        #expect(viewModel.dealerHandEvaluation != nil, "Expected dealer hand evaluation")
    }
}

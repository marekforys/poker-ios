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

@Suite("Hand Evaluation Tests")
struct HandEvaluationTests {
    // MARK: - High Card
    @Test("High Card")
    func testHighCard() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts, .diamonds, .clubs]
        let ranks: [Rank] = [.two, .four, .six, .eight, .ten, .jack, .king]
        let hand = Hand()
        
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
        
        let hand = Hand()
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
}

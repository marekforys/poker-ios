import Testing
@testable import PokerGame

@Suite("Hand Tests")
struct HandTests {
    // MARK: - Test Helpers
    
    private func createHand(ranks: [Rank], suits: [Suit] = [.hearts]) -> Hand {
        let hand = Hand()
        for (index, rank) in ranks.enumerated() {
            let suit = suits[index % suits.count]
            hand.addCard(Card(rank: rank, suit: suit, isFaceUp: true))
        }
        return hand
    }
    
    // MARK: - High Card Tests
    
    @Test("High Card - Basic")
    func testHighCard() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let hand = createHand(ranks: [.ace, .king, .queen, .jack, .nine], suits: suits)
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .highCard, "Expected high card, got \(evaluation.rank). Cards: \(hand.cards)")
        #expect(evaluation.highCards[0].rank == .ace, "Expected ace high, got \(evaluation.highCards[0].rank)")
    }
    
    // MARK: - One Pair Tests
    
    @Test("One Pair - Basic")
    func testOnePair() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let hand = createHand(
            ranks: [.ace, .ace, .king, .queen, .jack],
            suits: suits
        )
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .onePair, "Expected one pair, got \(evaluation.rank). Cards: \(hand.cards)")
        
        // For one pair, highCards will contain both cards from the pair first, then kickers
        // So the order will be [ace, ace, king, queen, jack]
        #expect(evaluation.highCards[0].rank == .ace, "Expected first ace, got \(evaluation.highCards[0].rank)")
        #expect(evaluation.highCards[1].rank == .ace, "Expected second ace, got \(evaluation.highCards[1].rank)")
        #expect(evaluation.highCards[2].rank == .king, "Expected king kicker, got \(evaluation.highCards[2].rank). High cards: \(evaluation.highCards.map { $0.rank })")
    }
    
    // MARK: - Two Pair Tests
    
    @Test("Two Pair - Basic")
    func testTwoPair() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let hand = createHand(
            ranks: [.ace, .ace, .king, .king, .queen],
            suits: suits
        )
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .twoPair, "Expected two pair, got \(evaluation.rank). Cards: \(hand.cards)")
        
        // For two pair, highCards will contain both cards from the first pair, 
        // then both cards from the second pair, then the kicker
        // So the order will be [ace, ace, king, king, queen]
        #expect(evaluation.highCards[0].rank == .ace, "Expected first ace, got \(evaluation.highCards[0].rank)")
        #expect(evaluation.highCards[1].rank == .ace, "Expected second ace, got \(evaluation.highCards[1].rank)")
        #expect(evaluation.highCards[2].rank == .king, "Expected first king, got \(evaluation.highCards[2].rank)")
        #expect(evaluation.highCards[3].rank == .king, "Expected second king, got \(evaluation.highCards[3].rank)")
        #expect(evaluation.highCards[4].rank == .queen, "Expected queen kicker, got \(evaluation.highCards[4].rank). High cards: \(evaluation.highCards.map { $0.rank })")
    }
    
    // MARK: - Three of a Kind Tests
    
    @Test("Three of a Kind - Basic")
    func testThreeOfAKind() {
        // Use different suits to prevent flush detection
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let hand = createHand(
            ranks: [.ace, .ace, .ace, .king, .queen],
            suits: suits
        )
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .threeOfAKind, 
               "Expected three of a kind, got \(evaluation.rank). Cards: \(hand.cards)")
        
        // For three of a kind, highCards will contain the three matching cards first,
        // then the highest kickers
        // So the order will be [ace, ace, ace, king, queen]
        #expect(evaluation.highCards[0].rank == .ace, "Expected first ace, got \(evaluation.highCards[0].rank)")
        #expect(evaluation.highCards[1].rank == .ace, "Expected second ace, got \(evaluation.highCards[1].rank)")
        #expect(evaluation.highCards[2].rank == .ace, "Expected third ace, got \(evaluation.highCards[2].rank)")
        #expect(evaluation.highCards[3].rank == .king, "Expected king kicker, got \(evaluation.highCards[3].rank). High cards: \(evaluation.highCards.map { $0.rank })")
        #expect(evaluation.highCards[4].rank == .queen, "Expected queen kicker, got \(evaluation.highCards[4].rank)")
    }
    
    // MARK: - Straight Tests
    
    @Test("Straight - Basic")
    func testStraight() {
        // Use a straight that can't be a royal flush (9-10-J-Q-K)
        let suits: [Suit] = [.hearts, .diamonds, .clubs, .spades, .hearts]
        let hand = createHand(
            ranks: [.nine, .ten, .jack, .queen, .king],
            suits: suits
        )
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, 
               "Expected straight, got \(evaluation.rank). Cards: \(hand.cards)")
        #expect(evaluation.highCards[0].rank == .king, 
               "Expected king high straight, got \(evaluation.highCards[0].rank). High cards: \(evaluation.highCards.map { $0.rank })")
    }
    
    @Test("Wheel Straight (A-2-3-4-5)")
    func testWheelStraight() {
        let hand = createHand(ranks: [.ace, .two, .three, .four, .five], suits: [.hearts, .diamonds, .hearts, .hearts, .hearts])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straight, "Expected straight, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .five, "Expected five high straight, got \(evaluation.highCards[0].rank)")
    }
    
    // MARK: - Flush Tests
    
    @Test("Flush - Basic")
    func testFlush() {
        let hand = createHand(ranks: [.ace, .three, .five, .seven, .nine], suits: [.hearts, .hearts, .hearts, .hearts, .hearts])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .flush, "Expected flush, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .ace, "Expected ace high flush, got \(evaluation.highCards[0].rank)")
    }
    
    // MARK: - Full House Tests
    
    @Test("Full House - Basic")
    func testFullHouse() {
        let hand = createHand(ranks: [.ace, .ace, .ace, .king, .king])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fullHouse, "Expected full house, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .ace, "Expected three aces, got \(evaluation.highCards[0].rank)")
        #expect(evaluation.highCards[3].rank == .king, "Expected two kings, got \(evaluation.highCards[3].rank)")
    }
    
    // MARK: - Four of a Kind Tests
    
    @Test("Four of a Kind - Basic")
    func testFourOfAKind() {
        let hand = createHand(ranks: [.ace, .ace, .ace, .ace, .king])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fourOfAKind, "Expected four of a kind, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .ace, "Expected four aces, got \(evaluation.highCards[0].rank)")
        #expect(evaluation.highCards[4].rank == .king, "Expected king kicker, got \(evaluation.highCards[4].rank)")
    }
    
    // MARK: - Straight Flush Tests
    
    @Test("Straight Flush - Basic")
    func testStraightFlush() {
        // Create a hand with a straight flush from 5 to 9 of hearts
        let hand = createHand(
            ranks: [.five, .six, .seven, .eight, .nine],
            suits: [.hearts, .hearts, .hearts, .hearts, .hearts]
        )
        let evaluation = hand.evaluate()
        
        // First check the rank is correct
        #expect(evaluation.rank == .straightFlush, 
               "Expected straight flush, got \(evaluation.rank). Cards: \(hand.cards)")
        
        // Then verify the high cards are in the correct order
        // For a straight flush, highCards should be in descending order
        #expect(evaluation.highCards.count == 5, 
               "Expected 5 high cards, got \(evaluation.highCards.count)")
        #expect(evaluation.highCards[0].rank == .nine, 
               "Expected nine high, got \(evaluation.highCards[0].rank). High cards: \(evaluation.highCards.map { $0.rank })")
        #expect(evaluation.highCards[1].rank == .eight, 
               "Expected eight, got \(evaluation.highCards[1].rank)")
        #expect(evaluation.highCards[2].rank == .seven, 
               "Expected seven, got \(evaluation.highCards[2].rank)")
        #expect(evaluation.highCards[3].rank == .six, 
               "Expected six, got \(evaluation.highCards[3].rank)")
        #expect(evaluation.highCards[4].rank == .five, 
               "Expected five, got \(evaluation.highCards[4].rank)")
    }
    
    @Test("Wheel Straight Flush (A-2-3-4-5)")
    func testWheelStraightFlush() {
        let hand = createHand(ranks: [.ace, .two, .three, .four, .five], suits: [.hearts, .hearts, .hearts, .hearts, .hearts])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .straightFlush, "Expected straight flush, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .five, "Expected five high straight flush, got \(evaluation.highCards[0].rank)")
    }
    
    // MARK: - Royal Flush Tests
    
    @Test("Royal Flush")
    func testRoyalFlush() {
        let hand = createHand(ranks: [.ten, .jack, .queen, .king, .ace], suits: [.hearts, .hearts, .hearts, .hearts, .hearts])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .royalFlush, "Expected royal flush, got \(evaluation.rank)")
        #expect(evaluation.highCards[0].rank == .ace, "Expected ace high royal flush, got \(evaluation.highCards[0].rank)")
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty Hand")
    func testEmptyHand() {
        let hand = Hand()
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .highCard, "Expected high card for empty hand, got \(evaluation.rank)")
        #expect(evaluation.highCards.isEmpty, "Expected no high cards for empty hand")
    }
    
    @Test("Hand With Duplicate Cards")
    func testDuplicateCards() {
        let card = Card(rank: .ace, suit: .hearts, isFaceUp: true)
        let hand = Hand(cards: [card, card, card, card, card])
        let evaluation = hand.evaluate()
        #expect(evaluation.rank == .fourOfAKind, "Expected four of a kind for duplicate cards, got \(evaluation.rank)")
    }
    
    @Test("Hand Comparison - Same Rank Different Kickers")
    func testHandComparisonSameRank() {
        let hand1 = createHand(ranks: [.ace, .ace, .king, .queen, .jack])
        let hand2 = createHand(ranks: [.ace, .ace, .king, .queen, .ten])
        #expect(hand1 > hand2, "Expected hand1 to be stronger than hand2")
    }
    
    @Test("Hand Comparison - Different Ranks")
    func testHandComparisonDifferentRanks() {
        let pairHand = createHand(ranks: [.ace, .ace, .king, .queen, .jack])
        let twoPairHand = createHand(ranks: [.ace, .ace, .king, .king, .queen])
        #expect(twoPairHand > pairHand, "Expected two pair to beat one pair")
    }
}

import Testing
@testable import PokerGame

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

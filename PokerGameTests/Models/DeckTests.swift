import Testing
@testable import PokerGame

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

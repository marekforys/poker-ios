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
        // The description should be rank + suit, e.g., "A♥️"
        #expect(card.description == "A♥️")
        
        // Test another combination
        let kingSpades = Card(rank: .king, suit: .spades)
        #expect(kingSpades.description == "K♠️")
    }
    
    @Test("Card flip")
    func testCardFlip() {
        let card = Card(rank: .two, suit: .hearts, isFaceUp: false)
        #expect(card.isFaceUp == false)
        card.flip()
        #expect(card.isFaceUp == true)
    }
}

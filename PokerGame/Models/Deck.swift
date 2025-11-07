import Foundation

class Deck {
    private(set) var cards: [Card] = []
    
    init() {
        reset()
    }
    
    func reset() {
        cards = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
    }
    
    func shuffle() {
        cards.shuffle()
    }
    
    func deal() -> Card? {
        guard !cards.isEmpty else { return nil }
        var card = cards.removeFirst()
        card.isFaceUp = true
        return card
    }
    
    func dealCards(count: Int) -> [Card] {
        var dealtCards: [Card] = []
        for _ in 0..<count {
            if let card = deal() {
                dealtCards.append(card)
            } else {
                break
            }
        }
        return dealtCards
    }
    
    var remainingCards: Int {
        return cards.count
    }
}

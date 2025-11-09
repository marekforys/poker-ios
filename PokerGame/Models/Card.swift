import Foundation

enum Suit: String, CaseIterable {
    case hearts = "♥️"
    case diamonds = "♦️"
    case clubs = "♣️"
    case spades = "♠️"
}

enum Rank: Int, CaseIterable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king, ace
    
    var description: String {
        switch self {
        case .ace: return "A"
        case .king: return "K"
        case .queen: return "Q"
        case .jack: return "J"
        default: return String(rawValue)
        }
    }
}

final class Card: Identifiable, Equatable, Comparable {
    let id = UUID()
    let rank: Rank
    let suit: Suit
    var isFaceUp: Bool = false
    
    init(rank: Rank, suit: Suit, isFaceUp: Bool = false) {
        self.rank = rank
        self.suit = suit
        self.isFaceUp = isFaceUp
    }
    
    var description: String {
        return "\(rank.description)\(suit.rawValue)"
    }
    
    func flip() {
        isFaceUp.toggle()
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.rank == rhs.rank && lhs.suit == rhs.suit
    }
    
    static func < (lhs: Card, rhs: Card) -> Bool {
        return lhs.rank.rawValue < rhs.rank.rawValue
    }
}

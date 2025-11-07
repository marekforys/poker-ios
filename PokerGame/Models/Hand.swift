import Foundation

enum HandRank: Int, Comparable {
    case highCard = 1
    case onePair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush
    case royalFlush
    
    static func < (lhs: HandRank, rhs: HandRank) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

struct HandEvaluation {
    let rank: HandRank
    let highCards: [Rank]
    
    init(rank: HandRank, highCards: [Rank]) {
        self.rank = rank
        self.highCards = highCards
    }
}

struct Hand {
    private(set) var cards: [Card] = []
    
    mutating func addCard(_ card: Card) {
        cards.append(card)
    }
    
    mutating func addCards(_ newCards: [Card]) {
        cards.append(contentsOf: newCards)
    }
    
    mutating func removeAll() {
        cards.removeAll()
    }
    
    func evaluate() -> HandEvaluation {
        guard cards.count >= 5 else { 
            return HandEvaluation(rank: .highCard, highCards: [cards.max { $0.rank.rawValue < $1.rank.rawValue }?.rank ?? .two])
        }
        
        // Sort cards by rank in descending order
        let sortedCards = cards.sorted { $0.rank.rawValue > $1.rank.rawValue }
        
        // Check for Royal Flush
        if isRoyalFlush() {
            return HandEvaluation(rank: .royalFlush, highCards: [.ace])
        }
        
        // Check for Straight Flush
        if let straightFlushHigh = isStraightFlush() {
            return HandEvaluation(rank: .straightFlush, highCards: [straightFlushHigh])
        }
        
        // Check for Four of a Kind
        if let fourOfAKindRank = nOfAKind(4) {
            let kicker = sortedCards.first { $0.rank != fourOfAKindRank }?.rank ?? .two
            return HandEvaluation(rank: .fourOfAKind, highCards: [fourOfAKindRank, kicker])
        }
        
        // Check for Full House
        if let threeOfAKindRank = nOfAKind(3) {
            let remainingCards = sortedCards.filter { $0.rank != threeOfAKindRank }
            if let pairRank = nOfAKind(2, in: remainingCards) {
                return HandEvaluation(rank: .fullHouse, highCards: [threeOfAKindRank, pairRank])
            }
        }
        
        // Check for Flush
        if let flushHigh = isFlush() {
            return HandEvaluation(rank: .flush, highCards: [flushHigh])
        }
        
        // Check for Straight
        if let straightHigh = isStraight() {
            return HandEvaluation(rank: .straight, highCards: [straightHigh])
        }
        
        // Check for Three of a Kind
        if let threeOfAKindRank = nOfAKind(3) {
            let kickers = sortedCards
                .filter { $0.rank != threeOfAKindRank }
                .prefix(2)
                .map { $0.rank }
            return HandEvaluation(rank: .threeOfAKind, highCards: [threeOfAKindRank] + kickers)
        }
        
        // Check for Two Pair
        if let twoPairRanks = twoPair() {
            let kicker = sortedCards.first { !twoPairRanks.contains($0.rank) }?.rank ?? .two
            return HandEvaluation(rank: .twoPair, highCards: twoPairRanks + [kicker])
        }
        
        // Check for One Pair
        if let pairRank = nOfAKind(2) {
            let kickers = sortedCards
                .filter { $0.rank != pairRank }
                .prefix(3)
                .map { $0.rank }
            return HandEvaluation(rank: .onePair, highCards: [pairRank] + kickers)
        }
        
        // High Card
        let highCards = Array(sortedCards.prefix(5).map { $0.rank })
        return HandEvaluation(rank: .highCard, highCards: highCards)
    }
    
    private func isRoyalFlush() -> Bool {
        guard let flushSuit = flushSuit() else { return false }
        let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let flushCards = cards.filter { $0.suit == flushSuit }
        let flushRanks = Set(flushCards.map { $0.rank })
        return royalRanks.isSubset(of: flushRanks)
    }
    
    private func isStraightFlush() -> Rank? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.filter { $0.suit == flushSuit }
        return checkStraight(in: flushCards)
    }
    
    private func isFlush() -> Rank? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.filter { $0.suit == flushSuit }
        return flushCards.max { $0.rank.rawValue < $1.rank.rawValue }?.rank
    }
    
    private func isStraight() -> Rank? {
        return checkStraight(in: cards)
    }
    
    private func checkStraight(in cards: [Card]) -> Rank? {
        let uniqueRanks = Set(cards.map { $0.rank.rawValue }).sorted()
        
        // Need at least 5 unique ranks to form a straight
        guard uniqueRanks.count >= 5 else { return nil }
        
        // Check for Ace-low straight (A-2-3-4-5) first
        let hasAceLow = Set([2, 3, 4, 5]).isSubset(of: uniqueRanks) && 
                       uniqueRanks.contains(Rank.ace.rawValue)
        
        if hasAceLow {
            return .five
        }
        
        // Check for regular straight (5 consecutive ranks)
        // We only need to check up to count - 4 because we're looking at 5 cards at a time
        for i in 0...(uniqueRanks.count - 5) {
            let start = uniqueRanks[i]
            let end = uniqueRanks[i + 4]
            
            // If the difference between first and last card is 4, it's a straight
            if end - start == 4 {
                return Rank(rawValue: end) // Return the highest rank in the straight
            }
        }
        
        return nil
    }
    
    private func nOfAKind(_ n: Int, in cardList: [Card]? = nil) -> Rank? {
        let cardsToCheck = cardList ?? self.cards
        let rankCounts = Dictionary(grouping: cardsToCheck, by: { $0.rank })
        return rankCounts.first { $0.value.count >= n }?.key
    }
    
    private func twoPair() -> [Rank]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank })
        let pairs = rankCounts.filter { $0.value.count >= 2 }.keys.sorted { $0.rawValue > $1.rawValue }
        return pairs.count >= 2 ? Array(pairs.prefix(2)) : nil
    }
    
    private func flushSuit() -> Suit? {
        let suitCounts = Dictionary(grouping: cards, by: { $0.suit })
        return suitCounts.first { $0.value.count >= 5 }?.key
    }
}

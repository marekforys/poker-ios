import Foundation

enum HandRank: Int, Comparable, CustomStringConvertible {
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
    
    var description: String {
        switch self {
        case .highCard: return "High Card"
        case .onePair: return "One Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}

struct HandEvaluation: Equatable {
    let rank: HandRank
    let highCards: [Card] // Cards that form the best hand, ordered by importance
    
    init(rank: HandRank, highCards: [Card]) {
        self.rank = rank
        self.highCards = highCards
    }
    
    static func == (lhs: HandEvaluation, rhs: HandEvaluation) -> Bool {
        guard lhs.rank == rhs.rank && 
              lhs.highCards.count == rhs.highCards.count else {
            return false
        }
        
        // Compare only the ranks of the high cards, not the suits
        return zip(lhs.highCards, rhs.highCards).allSatisfy { $0.rank == $1.rank }
    }
}

final class Hand: Equatable, Comparable {
    private(set) var cards: [Card] = []
    
    init() {}
    
    init(cards: [Card]) {
        self.cards = cards
    }
    
    func addCard(_ card: Card) {
        cards.append(card)
    }
    
    func addCards(_ newCards: [Card]) {
        cards.append(contentsOf: newCards)
    }
    
    func removeAll() {
        cards.removeAll()
    }
    
    func evaluate() -> HandEvaluation {
        // For hands with fewer than 5 cards, just return the high cards
        guard cards.count >= 5 else {
            let sortedCards = cards.sorted { $0.rank.rawValue > $1.rank.rawValue }
            return HandEvaluation(rank: .highCard, highCards: sortedCards)
        }
        
        // Sort cards by rank in descending order
        let sortedCards = cards.sorted { $0.rank.rawValue > $1.rank.rawValue }
        
        // Check for Royal Flush
        if let royalFlushCards = isRoyalFlush() {
            return HandEvaluation(rank: .royalFlush, highCards: royalFlushCards)
        }
        
        // Check for Straight Flush
        if let straightFlushCards = isStraightFlush() {
            return HandEvaluation(rank: .straightFlush, highCards: straightFlushCards)
        }
        
        // Check for Four of a Kind
        if let fourOfAKindCards = nOfAKindCards(4) {
            // Get the kicker (highest card not part of the four of a kind)
            let kicker = sortedCards.first { card in
                !fourOfAKindCards.contains(where: { $0.rank == card.rank })
            } ?? sortedCards[0]
            
            return HandEvaluation(
                rank: .fourOfAKind,
                highCards: fourOfAKindCards + [kicker]
            )
        }
        
        // Get all rank counts for full house and other hand evaluations
        let rankCounts = Dictionary(grouping: sortedCards, by: { $0.rank })
        
        // Find all three of a kind ranks (exactly 3 cards)
        let threeOfAKindRanks = rankCounts.filter { $0.value.count == 3 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Find all pair ranks (exactly 2 cards)
        let pairRanks = rankCounts.filter { $0.value.count == 2 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Check for full house with two three of a kinds (use the highest two)
        if threeOfAKindRanks.count >= 2 {
            let firstSet = rankCounts[threeOfAKindRanks[0], default: []].prefix(3)
            let secondSet = rankCounts[threeOfAKindRanks[1], default: []].prefix(2)
            return HandEvaluation(
                rank: .fullHouse,
                highCards: Array(firstSet + secondSet)
            )
        }
        
        // Check for standard full house (three of a kind + pair)
        if let threeOfAKindRank = threeOfAKindRanks.first, !pairRanks.isEmpty {
            // Find the highest pair that's not part of the three of a kind
            if let pairRank = pairRanks.first(where: { $0 != threeOfAKindRank }) {
                let threeOfAKindCards = rankCounts[threeOfAKindRank, default: []].prefix(3)
                let pairCards = rankCounts[pairRank, default: []].prefix(2)
                return HandEvaluation(
                    rank: .fullHouse,
                    highCards: Array(threeOfAKindCards + pairCards)
                )
            } else if pairRanks.contains(threeOfAKindRank) {
                // Special case: We have three of a kind and a pair of the same rank (e.g., 3,3,3,3,2,2)
                let allCards = rankCounts[threeOfAKindRank, default: []]
                return HandEvaluation(
                    rank: .fullHouse,
                    highCards: Array(allCards.prefix(5))
                )
            }
        }
        
        // Check for Flush
        if let flushCards = isFlush() {
            return HandEvaluation(rank: .flush, highCards: Array(flushCards.prefix(5)))
        }
        
        // Check for Straight
        if let straightCards = isStraight() {
            return HandEvaluation(rank: .straight, highCards: straightCards)
        }
        
        // Check for three of a kind (if no full house)
        if let threeOfAKindRank = threeOfAKindRanks.first {
            let threeOfAKindCards = rankCounts[threeOfAKindRank, default: []].prefix(3)
            let kickerCards = sortedCards
                .filter { $0.rank != threeOfAKindRank }
                .prefix(2)
            
            return HandEvaluation(
                rank: .threeOfAKind,
                highCards: Array(threeOfAKindCards + kickerCards)
            )
        }
        
        // Check for Two Pair
        if pairRanks.count >= 2 {
            let firstPairCards = rankCounts[pairRanks[0], default: []].prefix(2)
            let secondPairCards = rankCounts[pairRanks[1], default: []].prefix(2)
            let kickerCard = sortedCards.first { card in
                card.rank != pairRanks[0] && card.rank != pairRanks[1]
            } ?? sortedCards[0]
            
            return HandEvaluation(
                rank: .twoPair,
                highCards: Array(firstPairCards + secondPairCards + [kickerCard])
            )
        }
        
        // Check for One Pair
        if let pairRank = pairRanks.first {
            let pairCards = rankCounts[pairRank, default: []].prefix(2)
            let kickerCards = sortedCards
                .filter { $0.rank != pairRank }
                .prefix(3)
            
            return HandEvaluation(
                rank: .onePair,
                highCards: Array(pairCards + kickerCards)
            )
        }
        
        // High Card
        return HandEvaluation(
            rank: .highCard,
            highCards: Array(sortedCards.prefix(5))
        )
    }
    
    private func isRoyalFlush() -> [Card]? {
        guard let flushSuit = flushSuit() else { return nil }
        let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let flushCards = cards.filter { $0.suit == flushSuit }
        let flushRanks = Set(flushCards.map { $0.rank })
        
        guard royalRanks.isSubset(of: flushRanks) else { return nil }
        
        // Return the royal flush cards in order
        return royalRanks.sorted { $0.rawValue > $1.rawValue }
            .compactMap { rank in
                flushCards.first { $0.rank == rank }
            }
    }
    
    private func isStraightFlush() -> [Card]? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.filter { $0.suit == flushSuit }
        
        // Get the unique ranks and sort them in descending order
        let uniqueRanks = Array(Set(flushCards.map { $0.rank })).sorted { $0.rawValue > $1.rawValue }
        
        // Check for Ace-low straight flush (A-2-3-4-5)
        let wheelRanks: Set<Rank> = [.ace, .two, .three, .four, .five]
        let hasWheel = wheelRanks.isSubset(of: uniqueRanks.map { $0 })
        
        if hasWheel {
            // Return the wheel straight flush in order (A-5-4-3-2)
            return wheelRanks.sorted { $0.rawValue > $1.rawValue }
                .compactMap { rank in
                    flushCards.first { $0.rank == rank }
                }
        }
        
        // Check for regular straight flush
        for i in 0..<(uniqueRanks.count - 4) {
            let currentRank = uniqueRanks[i].rawValue
            let straightRanks = (currentRank-4...currentRank).map { Rank(rawValue: $0) }.compactMap { $0 }
            
            if Set(straightRanks).isSubset(of: uniqueRanks) {
                // Return the straight flush cards in order (high to low)
                return straightRanks.sorted { $0.rawValue > $1.rawValue }
                    .compactMap { rank in
                        flushCards.first { $0.rank == rank }
                    }
            }
        }
        
        return nil
    }
    
    private func isFlush() -> [Card]? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.filter { $0.suit == flushSuit }
        guard flushCards.count >= 5 else { return nil }
        
        // Return the highest 5 cards of the flush
        return flushCards
            .sorted { $0.rank.rawValue > $1.rank.rawValue }
            .prefix(5)
            .map { $0 }
    }
    
    private func isStraight() -> [Card]? {
        guard let straightHigh = checkStraight(in: cards) else { return nil }
        
        // Get all cards that could be part of the straight
        let straightRanks: [Rank]
        if straightHigh == .five { // Handle wheel (A-2-3-4-5)
            straightRanks = [.five, .four, .three, .two, .ace]
        } else {
            let startRank = straightHigh.rawValue - 4
            straightRanks = (startRank...straightHigh.rawValue)
                .compactMap { Rank(rawValue: $0) }
                .sorted { $0.rawValue > $1.rawValue }
        }
        
        // For each rank in the straight, get one card of that rank
        var straightCards: [Card] = []
        var remainingCards = cards
        
        for rank in straightRanks {
            if let index = remainingCards.firstIndex(where: { $0.rank == rank }) {
                straightCards.append(remainingCards.remove(at: index))
            }
        }
        
        return straightCards.count >= 5 ? Array(straightCards.prefix(5)) : nil
    }
    
    private func checkStraight(in cards: [Card]) -> Rank? {
        // Get unique ranks and sort them in ascending order
        let uniqueRanks = Array(Set(cards.map { $0.rank.rawValue })).sorted()
        
        // Need at least 5 unique ranks to form a straight
        guard uniqueRanks.count >= 5 else {
            return nil
        }
        
        // Check for Ace-low straight (A-2-3-4-5) first
        let wheel = [2, 3, 4, 5, 14] // A-2-3-4-5 (Ace is 14)
        let hasWheel = Set(wheel).isSubset(of: uniqueRanks)
        
        if hasWheel {
            return .five // Five is the high card in a wheel
        }
        
        // Check for regular straight (5 consecutive ranks)
        // We need to check all possible sequences of 5 consecutive ranks
        for i in 0...(uniqueRanks.count - 5) {
            let currentRank = uniqueRanks[i]
            let straightRanks = [currentRank, currentRank + 1, currentRank + 2,
                                 currentRank + 3, currentRank + 4]
            
            // If all ranks in the straight exist in our unique ranks
            if Set(straightRanks).isSubset(of: uniqueRanks) {
                // Get the actual ranks we have that form this straight
                let consecutiveRanks = uniqueRanks.filter { straightRanks.contains($0) }
                
                // Verify we have at least 5 consecutive ranks
                if consecutiveRanks.count >= 5 {
                    // Find the highest rank in the straight
                    if let maxRank = straightRanks.last(where: { uniqueRanks.contains($0) }) {
                        return Rank(rawValue: maxRank)
                    }
                }
            }
        }
        
        return nil
    }
    
    // This method is kept for backward compatibility but should be removed if not used elsewhere
    private func nOfAKind(_ n: Int, in cardList: [Card]? = nil) -> Rank? {
        let cardsToCheck = cardList ?? self.cards
        let rankCounts = Dictionary(grouping: cardsToCheck, by: { $0.rank })
        return rankCounts.first { $0.value.count == n }?.key
    }
    
    private func flushSuit() -> Suit? {
        let suitCounts = Dictionary(grouping: cards, by: { $0.suit })
        return suitCounts.first { $0.value.count >= 5 }?.key
    }
    
    private func twoPair() -> ([Rank], [Card])? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank })
        let pairs = rankCounts.filter { $1.count >= 2 }
            .sorted { $0.key.rawValue > $1.key.rawValue }
            .prefix(2)
            .map { ($0.key, $0.value.prefix(2).map { $0 }) } // Take up to 2 cards per pair
        
        guard pairs.count >= 2 else { return nil }
        
        let pairRanks = pairs.map { $0.0 }
        let cards = pairs.flatMap { $0.1 }
        return (pairRanks, cards)
    }
    
    private func nOfAKindCards(_ n: Int) -> [Card]? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank })
        if let (_, cards) = rankCounts.first(where: { $0.value.count >= n }) {
            return Array(cards.prefix(n))
        }
        return nil
    }
    
    private func nOfAKind(_ n: Int) -> Rank? {
        return nOfAKindCards(n)?.first?.rank
    }
    
    private func writeToDebugFile(_ message: String) {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let debugFile = documents.appendingPathComponent("poker_debug.log")
        
        // Append to the file if it exists, otherwise create it
        if let fileHandle = FileHandle(forWritingAtPath: debugFile.path) {
            fileHandle.seekToEndOfFile()
            if let data = message.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            try? message.write(to: debugFile, atomically: true, encoding: .utf8)
        }
    }
    
    static func == (lhs: Hand, rhs: Hand) -> Bool {
        let lhsEval = lhs.evaluate()
        let rhsEval = rhs.evaluate()
        
        // Compare rank
        guard lhsEval.rank == rhsEval.rank && 
              lhsEval.highCards.count == rhsEval.highCards.count else {
            return false
        }
        
        // Compare only the ranks of the high cards, not the suits
        return zip(lhsEval.highCards, rhsEval.highCards).allSatisfy { $0.rank == $1.rank }
    }
    
    static func < (lhs: Hand, rhs: Hand) -> Bool {
        let lhsEval = lhs.evaluate()
        let rhsEval = rhs.evaluate()
        
        // First compare by hand rank
        if lhsEval.rank != rhsEval.rank {
            return lhsEval.rank.rawValue < rhsEval.rank.rawValue
        }
        
        // If ranks are equal, compare high cards
        for (lhsCard, rhsCard) in zip(lhsEval.highCards, rhsEval.highCards) {
            if lhsCard.rank != rhsCard.rank {
                return lhsCard.rank.rawValue < rhsCard.rank.rawValue
            }
        }
        
        // If all high cards are equal, the hands are considered equal in terms of comparison
        return false
    }
}

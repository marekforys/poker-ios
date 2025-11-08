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
        
        // Get all rank counts for full house and other hand evaluations
        let rankCounts = Dictionary(grouping: sortedCards, by: { $0.rank })
        
        // Find all three of a kind ranks (exactly 3 cards)
        let threeOfAKindRanks = rankCounts.filter { $0.value.count == 3 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Find all pair ranks (exactly 2 cards)
        let pairRanks = rankCounts.filter { $0.value.count == 2 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Check for full house with two three of a kinds (use the highest two)
        if threeOfAKindRanks.count >= 2 {
            return HandEvaluation(rank: .fullHouse, highCards: [threeOfAKindRanks[0], threeOfAKindRanks[1]])
        }
        
        // Check for standard full house (three of a kind + pair)
        if let threeOfAKindRank = threeOfAKindRanks.first, !pairRanks.isEmpty {
            // Find the highest pair that's not part of the three of a kind
            if let pairRank = pairRanks.first(where: { $0 != threeOfAKindRank }) {
                return HandEvaluation(rank: .fullHouse, highCards: [threeOfAKindRank, pairRank])
            } else if pairRanks.contains(threeOfAKindRank) {
                // Special case: We have three of a kind and a pair of the same rank (e.g., 3,3,3,3,2,2)
                return HandEvaluation(rank: .fullHouse, highCards: [threeOfAKindRank, threeOfAKindRank])
            }
        }
        
        // Check for Flush (moved after full house check)
        if let flushHigh = isFlush() {
            return HandEvaluation(rank: .flush, highCards: [flushHigh])
        }
        
        // Check for Straight (moved after flush check)
        if let straightHigh = isStraight() {
            return HandEvaluation(rank: .straight, highCards: [straightHigh])
        }
        
        // Check for three of a kind (if no full house)
        if let threeOfAKindRank = threeOfAKindRanks.first {
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
    
    func isStraight() -> Rank? {
        return checkStraight(in: cards)
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
    
    func nOfAKind(_ n: Int, in cardList: [Card]? = nil) -> Rank? {
        let cardsToCheck = cardList ?? self.cards
        let rankCounts = Dictionary(grouping: cardsToCheck, by: { $0.rank })
        
        // Find all ranks that have at least n cards
        let matchingRanks = rankCounts.filter { $0.value.count >= n }
        
        // If no matches, return nil
        if matchingRanks.isEmpty {
            return nil
        }
        
        // If we're looking for exactly n cards, we need to be careful not to count higher counts
        let exactMatchRanks = matchingRanks.filter { $0.value.count == n }
        
        // If we have exact matches, return the highest one
        if !exactMatchRanks.isEmpty {
            return exactMatchRanks.keys.sorted { $0.rawValue > $1.rawValue }.first
        }
        
        // Otherwise, return the highest rank with at least n cards
        return matchingRanks.keys.sorted { $0.rawValue > $1.rawValue }.first
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
            // File doesn't exist, create it
            try? message.write(to: debugFile, atomically: true, encoding: .utf8)
        }
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

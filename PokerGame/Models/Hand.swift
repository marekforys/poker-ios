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

struct HandEvaluation: Equatable {
    let rank: HandRank
    let highCards: [Rank]
    let cardIndices: [Int] // Indices of the cards that form this hand
    
    init(rank: HandRank, highCards: [Rank], cardIndices: [Int] = []) {
        self.rank = rank
        self.highCards = highCards
        self.cardIndices = cardIndices
    }
    
    static func == (lhs: HandEvaluation, rhs: HandEvaluation) -> Bool {
        return lhs.rank == rhs.rank && 
               lhs.highCards == rhs.highCards && 
               lhs.cardIndices == rhs.cardIndices
    }
}

struct Hand: Identifiable, Equatable {
    let id = UUID()
    
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
        // For hands with fewer than 5 cards, just return the high card
        guard cards.count >= 5 else {
            let sortedCards = cards.enumerated().sorted { $0.element.rank.rawValue > $1.element.rank.rawValue }
            let sortedRanks = sortedCards.map { $0.element.rank }
            let indices = sortedCards.map { $0.offset }
            return HandEvaluation(rank: .highCard, highCards: sortedRanks, cardIndices: indices)
        }
        
        // Sort cards by rank in descending order with indices
        let sortedCards = cards.enumerated().sorted { $0.element.rank.rawValue > $1.element.rank.rawValue }
        _ = sortedCards.map { $0.offset }
        let sortedCardValues = sortedCards.map { $0.element }
        
        // Check for Royal Flush
        if isRoyalFlush() {
            if let flushSuit = flushSuit() {
                let flushCards = cards.enumerated().filter { $0.element.suit == flushSuit }
                let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
                let royalFlushCards = flushCards.filter { royalRanks.contains($0.element.rank) }
                let indices = royalFlushCards.prefix(5).map { $0.offset }
                return HandEvaluation(rank: .royalFlush, highCards: [.ace], cardIndices: indices)
            }
            return HandEvaluation(rank: .royalFlush, highCards: [.ace])
        }
        
        // Check for Straight Flush
        if let (straightFlushHigh, indices) = isStraightFlush() {
            return HandEvaluation(rank: .straightFlush, highCards: [straightFlushHigh], cardIndices: indices)
        }
        
        // Check for Four of a Kind
        if let fourOfAKindRank = nOfAKind(4) {
            let fourOfAKindIndices = cards.enumerated()
                .filter { $0.element.rank == fourOfAKindRank }
                .map { $0.offset }
            
            let kickerCard = sortedCardValues.first { $0.rank != fourOfAKindRank } ?? sortedCardValues[0]
            let kickerIndex = cards.firstIndex { $0 == kickerCard } ?? 0
            
            return HandEvaluation(
                rank: .fourOfAKind,
                highCards: [fourOfAKindRank, kickerCard.rank],
                cardIndices: fourOfAKindIndices + [kickerIndex]
            )
        }
        
        // Get all rank counts for full house and other hand evaluations
        let rankCounts = Dictionary(grouping: sortedCardValues, by: { $0.rank })
        
        // Find all three of a kind ranks (exactly 3 cards)
        let threeOfAKindRanks = rankCounts.filter { $0.value.count == 3 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Find all pair ranks (exactly 2 cards)
        let pairRanks = rankCounts.filter { $0.value.count == 2 }.keys.sorted { $0.rawValue > $1.rawValue }
        
        // Check for full house with two three of a kinds (use the highest two)
        if threeOfAKindRanks.count >= 2 {
            let firstSetIndices = cards.enumerated()
                .filter { $0.element.rank == threeOfAKindRanks[0] }
                .map { $0.offset }
            let secondSetIndices = cards.enumerated()
                .filter { $0.element.rank == threeOfAKindRanks[1] }
                .map { $0.offset }
            let indices = Array((firstSetIndices.prefix(3) + secondSetIndices.prefix(2)).prefix(5))
            return HandEvaluation(
                rank: .fullHouse,
                highCards: [threeOfAKindRanks[0], threeOfAKindRanks[1]],
                cardIndices: indices
            )
        }
        
        // Check for standard full house (three of a kind + pair)
        if let threeOfAKindRank = threeOfAKindRanks.first, !pairRanks.isEmpty {
            // Find the highest pair that's not part of the three of a kind
            if let pairRank = pairRanks.first(where: { $0 != threeOfAKindRank }) {
                let threeOfAKindIndices = cards.enumerated()
                    .filter { $0.element.rank == threeOfAKindRank }
                    .map { $0.offset }
                let pairIndices = cards.enumerated()
                    .filter { $0.element.rank == pairRank }
                    .map { $0.offset }
                let indices = Array((threeOfAKindIndices + pairIndices).prefix(5))
                return HandEvaluation(
                    rank: .fullHouse,
                    highCards: [threeOfAKindRank, pairRank],
                    cardIndices: indices
                )
            } else if pairRanks.contains(threeOfAKindRank) {
                // Special case: We have three of a kind and a pair of the same rank (e.g., 3,3,3,3,2,2)
                let allIndices = cards.enumerated()
                    .filter { $0.element.rank == threeOfAKindRank }
                    .map { $0.offset }
                return HandEvaluation(
                    rank: .fullHouse,
                    highCards: [threeOfAKindRank, threeOfAKindRank],
                    cardIndices: Array(allIndices.prefix(5))
                )
            }
        }
        
        // Check for Flush (moved after full house check)
        if let (flushHigh, indices) = isFlush() {
            return HandEvaluation(rank: .flush, highCards: [flushHigh], cardIndices: indices)
        }
        
        // Check for Straight (moved after flush check)
        if let (straightHigh, indices) = isStraight() {
            return HandEvaluation(rank: .straight, highCards: [straightHigh], cardIndices: indices)
        }
        
        // Check for three of a kind (if no full house)
        if let threeOfAKindRank = threeOfAKindRanks.first {
            let threeOfAKindIndices = cards.enumerated()
                .filter { $0.element.rank == threeOfAKindRank }
                .map { $0.offset }
            
            let kickerCards = sortedCardValues
                .filter { $0.rank != threeOfAKindRank }
                .prefix(2)
            
            let kickerIndices = kickerCards.compactMap { card in
                cards.firstIndex { $0 == card }
            }
            
            return HandEvaluation(
                rank: .threeOfAKind,
                highCards: [threeOfAKindRank] + kickerCards.map { $0.rank },
                cardIndices: threeOfAKindIndices + kickerIndices
            )
        }
        
        // Check for Two Pair
        if let (pairRanks, indices) = twoPair() {
            let kickerCard = sortedCardValues.first { !pairRanks.contains($0.rank) } ?? sortedCardValues[0]
            let kickerIndex = cards.firstIndex { $0 == kickerCard } ?? 0
            
            return HandEvaluation(
                rank: .twoPair,
                highCards: pairRanks + [kickerCard.rank],
                cardIndices: indices + [kickerIndex]
            )
        }
        
        // Check for One Pair
        if let pairRank = nOfAKind(2) {
            let pairIndices = cards.enumerated()
                .filter { $0.element.rank == pairRank }
                .map { $0.offset }
            
            let kickerCards = sortedCardValues
                .filter { $0.rank != pairRank }
                .prefix(3)
            
            let kickerIndices = kickerCards.compactMap { card in
                cards.firstIndex { $0 == card }
            }
            
            return HandEvaluation(
                rank: .onePair,
                highCards: [pairRank] + kickerCards.map { $0.rank },
                cardIndices: pairIndices + kickerIndices
            )
        }
        
        // High Card
        let highCardIndices = sortedCards.prefix(5).compactMap { card in
            cards.firstIndex { $0 == card.element }
        }
        let highCards = Array(sortedCardValues.prefix(5).map { $0.rank })
        return HandEvaluation(
            rank: .highCard,
            highCards: highCards,
            cardIndices: highCardIndices
        )
    }
    
    private func isRoyalFlush() -> Bool {
        guard let flushSuit = flushSuit() else { return false }
        let royalRanks: Set<Rank> = [.ten, .jack, .queen, .king, .ace]
        let flushCards = cards.filter { $0.suit == flushSuit }
        let flushRanks = Set(flushCards.map { $0.rank })
        return royalRanks.isSubset(of: flushRanks)
    }
    
    private func isStraightFlush() -> (Rank, [Int])? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.enumerated().filter { $0.element.suit == flushSuit }
        let cardValues = flushCards.map { $0.element }
        if let straightHigh = checkStraight(in: cardValues) {
            // Get the indices of the straight cards
            let straightIndices = flushCards
                .filter { $0.element.rank == straightHigh ||
                    $0.element.rank.rawValue >= straightHigh.rawValue - 4 }
                .map { $0.offset }
            return (straightHigh, Array(straightIndices.prefix(5)))
        }
        return nil
    }
    
    private func isFlush() -> (Rank, [Int])? {
        guard let flushSuit = flushSuit() else { return nil }
        let flushCards = cards.enumerated().filter { $0.element.suit == flushSuit }
        let sortedFlushCards = flushCards.sorted { $0.element.rank.rawValue > $1.element.rank.rawValue }
        guard let highCard = sortedFlushCards.first else { return nil }
        let indices = sortedFlushCards.prefix(5).map { $0.offset }
        return (highCard.element.rank, indices)
    }
    
    func isStraight() -> (Rank, [Int])? {
        if let straightHigh = checkStraight(in: cards) {
            // Get the indices of the straight cards
            let straightCards = cards.enumerated()
                .filter { $0.element.rank == straightHigh ||
                    $0.element.rank.rawValue >= straightHigh.rawValue - 4 }
                .prefix(5)
            return (straightHigh, straightCards.map { $0.offset })
        }
        return nil
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
    
    private func twoPair() -> ([Rank], [Int])? {
        let rankCounts = Dictionary(grouping: cards.enumerated(), by: { $0.element.rank })
        let pairs = rankCounts.filter { $1.count == 2 }
            .sorted { $0.key.rawValue > $1.key.rawValue }
            .prefix(2)
            .map { ($0.key, $0.value.map { $0.offset }) }
        
        guard pairs.count >= 2 else { return nil }
        
        let pairRanks = pairs.map { $0.0 }
        let indices = pairs.flatMap { $0.1 }
        return (pairRanks, Array(indices.prefix(4))) // 2 pairs = 4 cards
    }
    
    private func nOfAKind(_ n: Int) -> Rank? {
        let rankCounts = Dictionary(grouping: cards, by: { $0.rank })
        return rankCounts.first { $0.value.count == n }?.key
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
        return lhs.id == rhs.id &&
               lhs.cards == rhs.cards
    }
}

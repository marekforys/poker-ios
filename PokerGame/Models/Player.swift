import Foundation
import Combine

class Player: ObservableObject {
    @Published private(set) var tokens: Int
    @Published private(set) var currentBet: Int = 0
    @Published private(set) var isAllIn: Bool = false
    
    init(initialTokens: Int = 1000) {
        self.tokens = initialTokens
    }
    
    func placeBet(amount: Int) -> Bool {
        guard amount > 0 else { return false }
        
        if amount >= tokens {
            // If not enough tokens, go all-in
            let allInAmount = tokens
            DispatchQueue.main.async { [weak self] in
                self?.currentBet += allInAmount
                self?.tokens = 0
                self?.isAllIn = true
            }
            return true
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.tokens -= amount
                self?.currentBet += amount
            }
            return true
        }
    }
    
    func win(amount: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.tokens += amount
            self?.resetBet()
        }
    }
    
    func lose() {
        DispatchQueue.main.async { [weak self] in
            self?.resetBet()
        }
    }
    
    func resetBet() {
        DispatchQueue.main.async { [weak self] in
            self?.currentBet = 0
            self?.isAllIn = false
        }
    }
    
    func canAfford(amount: Int) -> Bool {
        return tokens >= amount || tokens > 0
    }
}

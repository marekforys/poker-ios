import Testing
@testable import PokerGame

@Suite("Player Tests")
struct PlayerTests {
    @Test("Player initialization")
    func testPlayerInitialization() {
        let initialTokens = 1000
        let player = Player(initialTokens: initialTokens)
        
        #expect(player.tokens == initialTokens, "Player should start with initial tokens")
        #expect(player.currentBet == 0, "Player's initial bet should be 0")
        #expect(player.isAllIn == false, "Player should not be all-in initially")
    }
    
    @Test("Player places bet")
    func testPlaceBet() async throws {
        let initialTokens = 1000
        let betAmount = 100
        let player = Player(initialTokens: initialTokens)
        
        let success = player.placeBet(amount: betAmount)
        
        // Wait for the async update to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(success == true, "Bet should be placed successfully")
        #expect(player.tokens == initialTokens - betAmount, "Tokens should be reduced by bet amount")
        #expect(player.currentBet == betAmount, "Current bet should be updated")
    }
    
    @Test("Player goes all-in")
    func testAllIn() async throws {
        let initialTokens = 1000
        let allInAmount = initialTokens + 500 // More than player has
        let player = Player(initialTokens: initialTokens)
        
        let success = player.placeBet(amount: allInAmount)
        
        // Wait for the async update to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(success == true, "All-in should be successful")
        #expect(player.tokens == 0, "Player should have 0 tokens after all-in")
        #expect(player.currentBet == initialTokens, "Current bet should be all tokens")
        #expect(player.isAllIn == true, "Player should be marked as all-in")
    }
    
    @Test("Player wins")
    func testWin() async throws {
        let initialTokens = 1000
        let winAmount = 500
        let player = Player(initialTokens: initialTokens)
        
        // Place a bet first
        _ = player.placeBet(amount: 100)
        
        // Win with some amount
        player.win(amount: winAmount)
        
        // Need to wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(player.tokens == initialTokens + winAmount - 100, "Should have initial tokens - bet + winnings")
        #expect(player.currentBet == 0, "Bet should be reset after win")
    }
    
    @Test("Player loses")
    func testLose() async throws {
        let initialTokens = 1000
        let player = Player(initialTokens: initialTokens)
        
        // Place a bet first
        _ = player.placeBet(amount: 100)
        
        // Lose (reset bet)
        player.lose()
        
        // Need to wait for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(player.tokens == initialTokens - 100, "Should have initial tokens - bet")
        #expect(player.currentBet == 0, "Bet should be reset after loss")
    }
    
    @Test("Player can afford bet")
    func testCanAffordBet() {
        let initialTokens = 1000
        let player = Player(initialTokens: initialTokens)
        
        #expect(player.canAfford(amount: 500) == true, "Should be able to afford 500")
        #expect(player.canAfford(amount: 1000) == true, "Should be able to afford all tokens")
        #expect(player.canAfford(amount: 1001) == false, "Should not be able to afford more than tokens")
        #expect(player.canAfford(amount: 0) == true, "Should be able to afford 0")
    }
    
    @Test("Player reset bet")
    func testResetBet() {
        let player = Player(initialTokens: 1000)
        
        // Place a bet
        _ = player.placeBet(amount: 100)
        
        // Reset bet
        player.resetBet()
        
        #expect(player.currentBet == 0, "Bet should be reset to 0")
        #expect(player.isAllIn == false, "All-in status should be false after reset")
    }
    
    @Test("Multiple bets")
    func testMultipleBets() async throws {
        let initialTokens = 1000
        let player = await Player(initialTokens: initialTokens)
        
        // First bet
        _ = await player.placeBet(amount: 100)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(player.tokens == 900, "After first bet, tokens should be 900 (1000 - 100)")
        #expect(player.currentBet == 100, "Current bet should be 100 after first bet")
        
        // Second bet
        _ = await player.placeBet(amount: 200)
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(player.tokens == 700, "After second bet, tokens should be 700 (900 - 200)")
        #expect(player.currentBet == 300, "Current bet should be 300 (100 + 200) after second bet")
    }
    
    @Test("Player cannot place negative bet")
    func testNegativeBet() {
        let player = Player(initialTokens: 1000)
        
        let success = player.placeBet(amount: -100)
        
        #expect(success == false, "Should not be able to place negative bet")
        #expect(player.tokens == 1000, "Tokens should remain unchanged")
        #expect(player.currentBet == 0, "Bet should remain 0")
    }
}

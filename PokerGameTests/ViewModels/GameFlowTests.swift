import Testing
@testable import PokerGame

@Suite("Game Flow Tests")
struct GameFlowTests {
    @Test("Game initialization")
    func testGameInitialization() {
        let viewModel = PokerGameViewModel()
        #expect(viewModel.gameState == .dealing)
        #expect(viewModel.playerHand.cards.count == 2, "Player should have 2 cards")
    }
    
    @Test("Deal flop")
    func testDealFlop() {
        let viewModel = PokerGameViewModel()
        viewModel.dealFlop()
        #expect(viewModel.communityCards.count == 3, "Flop should add 3 community cards")
        #expect(viewModel.gameState == .flop, "Game state should be .flop after dealing flop")
    }
    
    @Test("Complete game flow")
    @MainActor func testCompleteGameFlow() async {
        let viewModel = PokerGameViewModel()
        
        // Initial state
        #expect(viewModel.gameState == .dealing)
        #expect(viewModel.playerHand.cards.count == 2, "Player should have 2 cards")
        
        // Deal flop
        viewModel.dealFlop()
        #expect(viewModel.communityCards.count == 3, "Flop should add 3 community cards")
        #expect(viewModel.gameState == .flop, "Game state should be .flop after dealing flop")
        
        // Player calls after flop
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Deal turn - should be called with .flop state
        viewModel.test_setGameState(.flop)
        viewModel.dealTurn()
        #expect(viewModel.communityCards.count == 4, "Turn should add 1 more card (total 4)")
        #expect(viewModel.gameState == .turn, "Game state should be .turn after dealing turn")
        
        // Player calls after turn
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Deal river - should be called with .turn state
        viewModel.test_setGameState(.turn)
        viewModel.dealRiver()
        #expect(viewModel.communityCards.count == 5, "River should add 1 more card (total 5)")
        #expect(viewModel.gameState == .river, "Game state should be .river after dealing river")
        
        // Player calls after river
        viewModel.test_setGameState(.playerTurn)
        viewModel.playerCalls()
        
        // Start the evaluation
        viewModel.evaluateFinalHands()
        
        // Wait for the evaluation to complete with a timeout
        let maxAttempts = 20 // 2 seconds total with 0.1s interval
        var attempts = 0
        
        // Poll the state until we get the expected result or time out
        while attempts < maxAttempts && 
              !(viewModel.gameState == .gameOver && 
                viewModel.handEvaluation != nil && 
                viewModel.dealerHandEvaluation != nil) {
            attempts += 1
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Verify the results
        #expect(viewModel.gameState == .gameOver, "Game should be over after evaluating hands")
        #expect(viewModel.handEvaluation != nil, "Expected player hand evaluation")
        #expect(viewModel.dealerHandEvaluation != nil, "Expected dealer hand evaluation")
    }
}

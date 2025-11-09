import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = PokerGameViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.green.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Community cards
                VStack(spacing: 8) {
                    Text("Community Cards")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) { // Negative spacing to make cards overlap slightly
                            ForEach(viewModel.communityCards) { card in
                                let isBestCard = viewModel.bestHandCards.contains { $0.id == card.id }
                                CardView(card: card)
                                    .scaleEffect(0.9) // Slightly smaller cards to fit better
                                    .offset(y: isBestCard ? -15 : 0) // Slight upward movement for best cards
                                    .zIndex(isBestCard ? 1 : 0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.bestHandCards)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15) // More vertical padding
                    }
                    .frame(height: 140) // Adjusted height for better spacing
                }
                .padding(.top, 2)
                .padding(.bottom, 10)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10) // Add some space between sections
                
                Spacer()
                
                // Player's hand
                VStack(spacing: 8) {
                    Text("Your Hand")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: -20) { // Negative spacing to make cards overlap more
                        ForEach(viewModel.playerHand.cards) { card in
                            let isBestCard = viewModel.bestHandCards.contains { $0.id == card.id }
                            CardView(card: card)
                                .scaleEffect(0.9) // Slightly larger to match community cards
                                .offset(y: isBestCard ? -25 : 10) // Move up more when highlighted, otherwise slightly down
                                .zIndex(isBestCard ? 1 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.bestHandCards)
                        }
                    }
                    .frame(height: 140) // Increased height for better spacing
                    .padding(.horizontal, 20)
                    .padding(.top, 5) // Less top padding to bring cards up slightly
                    .padding(.bottom, 15) // More bottom padding
                }
                .padding(.top, 2)
                .padding(.bottom, 10)
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10) // Add some space between sections
                
                // Game controls
                VStack(spacing: 15) {
                    if let evaluation = viewModel.handEvaluation {
                        VStack(spacing: 10) {
                            Text(viewModel.getHandRankString())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if evaluation.rank == .highCard, !evaluation.highCards.isEmpty {
                                // Create a card view for the high card
                                let highCard = evaluation.highCards[0]
                                let card = Card(rank: highCard, suit: .hearts, isFaceUp: true) // Suit is arbitrary for display
                                CardView(card: card)
                                    .scaleEffect(0.6)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        switch viewModel.gameState {
                        case .notStarted, .gameOver:
                            viewModel.startNewGame()
                        case .dealing:
                            viewModel.dealFlop()
                        case .flop:
                            viewModel.dealTurn()
                        case .turn:
                            viewModel.dealRiver()
                        case .river:
                            break
                        }
                    }) {
                        Text(buttonText())
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(buttonColor())
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .padding(.top, 40)
        }
    }
    
    private func buttonText() -> String {
        switch viewModel.gameState {
        case .notStarted, .gameOver:
            return "Deal New Hand"
        case .dealing:
            return "Deal Flop"
        case .flop:
            return "Deal Turn"
        case .turn:
            return "Deal River"
        case .river:
            return "Show Hand"
        }
    }
    
    private func buttonColor() -> Color {
        switch viewModel.gameState {
        case .notStarted, .gameOver:
            return .blue
        case .dealing, .flop, .turn, .river:
            return .orange
        }
    }
}

struct CardView: View {
    let card: Card
    private let cardWidth: CGFloat = 80
    private let cardHeight: CGFloat = 120
    private let cornerRadius: CGFloat = 8
    
    private var cardColor: Color {
        card.suit == .hearts || card.suit == .diamonds ? .red : .black
    }
    
    var body: some View {
        ZStack {
            // Card background with border
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
                .frame(width: cardWidth, height: cardHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 2, x: 0, y: 2)
            
            if card.isFaceUp {
                VStack(spacing: 0) {
                    // Top rank and suit
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(card.rank.description)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(cardColor)
                            Text(card.suit.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(cardColor)
                        }
                        .padding(.leading, 6)
                        .padding(.top, 6)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Center suit symbol
                    Text(card.suit.rawValue)
                        .font(.system(size: 28))
                        .foregroundColor(cardColor)
                    
                    Spacer()
                    
                    // Bottom rank and suit (upside down)
                    HStack(alignment: .bottom) {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(card.rank.description)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(cardColor)
                            Text(card.suit.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(cardColor)
                        }
                        .rotationEffect(.degrees(180))
                        .padding(.trailing, 6)
                        .padding(.bottom, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(width: cardWidth, height: cardHeight)
            } else {
                // Face down card
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: cardWidth, height: cardHeight)
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            
                            // Card back pattern
                            Image(systemName: "suit.spade.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.2))
                        }
                    )
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}

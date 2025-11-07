import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = PokerGameViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.green.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Community cards
                VStack {
                    Text("Community Cards")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        ForEach(viewModel.communityCards) { card in
                            CardView(card: card)
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
                
                // Player's hand
                VStack {
                    Text("Your Hand")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        ForEach(viewModel.playerHand.cards) { card in
                            CardView(card: card)
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Game controls
                VStack(spacing: 15) {
                    if viewModel.handEvaluation != nil {
                        Text("\(viewModel.getHandRankString())")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
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
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(width: 80, height: 120)
                .shadow(radius: 5)
            
            if card.isFaceUp {
                VStack(spacing: 0) {
                    // Top rank and suit
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.rank.description)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                            Text(card.suit.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                        }
                        .padding(.leading, 8)
                        .padding(.top, 5)
                        Spacer()
                    }
                    
                    // Center suit symbol (larger)
                    Text(card.suit.rawValue)
                        .font(.system(size: 32))
                        .padding(.vertical, 5)
                        .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                    
                    Spacer()
                    
                    // Bottom rank and suit (upside down)
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(card.rank.description)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                            Text(card.suit.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                        }
                        .rotationEffect(.degrees(180))
                        .padding(.trailing, 8)
                        .padding(.bottom, 5)
                    }
                }
                .frame(width: 80, height: 120)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Face down card
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), 
                                       startPoint: .topLeading, 
                                       endPoint: .bottomTrailing))
                    .frame(width: 80, height: 120)
                    .overlay(
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            
                            // Card back pattern
                            Image(systemName: "suit.spade.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    )
            }
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
    }
}

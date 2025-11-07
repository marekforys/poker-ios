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
                    if let evaluation = viewModel.handEvaluation {
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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .frame(width: 80, height: 120)
                .shadow(radius: 3)
            
            if card.isFaceUp {
                VStack {
                    HStack {
                        Text(card.rank.description)
                            .font(.headline)
                            .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                        Spacer()
                    }
                    
                    Text(card.suit.rawValue)
                        .font(.title)
                        .padding(.vertical, 5)
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text(card.rank.description)
                            .font(.headline)
                            .foregroundColor(card.suit == .hearts || card.suit == .diamonds ? .red : .black)
                    }
                }
                .padding(8)
                .frame(width: 80, height: 120)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 80, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
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

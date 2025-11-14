import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = PokerGameViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.green.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 12) {
                // Game status
                Text(viewModel.gameState.description)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                
                // Dealer's hand
                VStack(spacing: 8) {
                    Text("Dealer's Hand")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: -20) {
                        ForEach(viewModel.dealer.hand.cards) { card in
                            let isBestCard = viewModel.dealerBestHandCards.contains { $0.id == card.id }
                            CardView(card: card)
                                .scaleEffect(0.8)
                                .offset(y: isBestCard ? -15 : 0)
                                .zIndex(isBestCard ? 1 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.dealerBestHandCards)
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal)
                
                // Community cards
                VStack(spacing: 8) {
                    Text("Community Cards")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -15) {
                            ForEach(viewModel.communityCards) { card in
                                let isBestCard = viewModel.bestHandCards.contains { $0.id == card.id } || 
                                               viewModel.dealerBestHandCards.contains { $0.id == card.id }
                                CardView(card: card)
                                    .scaleEffect(0.8)
                                    .offset(y: isBestCard ? 10 : 0)
                                    .zIndex(isBestCard ? 1 : 0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.bestHandCards + viewModel.dealerBestHandCards)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .frame(height: 120)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Game result
                if viewModel.gameResult != nil {
                    VStack(spacing: 10) {
                        Text(viewModel.getGameResultString())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                // Player's hand
                VStack(spacing: 8) {
                    Text("Your Hand")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: -20) {
                        ForEach(viewModel.playerHand.cards) { card in
                            let isBestCard = viewModel.bestHandCards.contains { $0.id == card.id }
                            CardView(card: card)
                                .scaleEffect(0.8)
                                .offset(y: isBestCard ? -15 : 0)
                                .zIndex(isBestCard ? 1 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.bestHandCards)
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal)
                
                // Game controls
                VStack(spacing: 15) {
                    // Hand evaluation
                    if let evaluation = viewModel.handEvaluation, viewModel.gameState == .gameOver {
                        VStack(spacing: 8) {
                            Text("Your hand: \(viewModel.getHandRankString())")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if viewModel.showDealerCards {
                                Text("Dealer's hand: \(viewModel.getDealerHandRankString())")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                    }
                    
                    // Action buttons
                    if viewModel.gameState == .playerTurn {
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.playerCalls()
                            }) {
                                Text("Call")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                viewModel.playerFolds()
                            }) {
                                Text("Fold")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    } else {
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
                                viewModel.evaluateFinalHands()
                            default:
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
                }
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
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
            return "Show Down"
        case .playerTurn:
            return "Your Turn"
        case .dealerTurn:
            return "Dealer's Turn"
        }
    }
    
    private func buttonColor() -> Color {
        switch viewModel.gameState {
        case .notStarted, .gameOver:
            return .blue
        case .dealing, .flop, .turn, .river, .playerTurn, .dealerTurn:
            return .orange
        }
    }
}

struct CardView: View {
    @ObservedObject var card: Card
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

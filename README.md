# Poker iOS

A Texas Hold'em poker game built with Swift and SwiftUI for iOS.

## Features

- Texas Hold'em poker rules implementation
- Full deck of 52 cards with proper shuffling
- Hand evaluation for all standard poker hands
- Game flow management (dealing, flop, turn, river)
- Unit tests for game logic and rules

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Game Rules

- Each player is dealt 2 private cards
- 5 community cards are dealt face-up on the "board"
- Players aim to make the best possible 5-card hand using any combination of their private cards and the community cards
- Hand rankings follow standard poker rules (Royal Flush, Straight Flush, Four of a Kind, etc.)

## Project Structure

- `PokerGame/`
  - `Models/` - Core game models (Card, Deck, Hand)
  - `ViewModels/` - Game logic and state management
  - `Views/` - SwiftUI views
  - `Extensions/` - Helper extensions

## Running Tests

The project includes comprehensive unit tests. To run them:
1. Open the project in Xcode
2. Press Cmd+U or select Product > Test

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

# Vesta

Vesta is an AI-powered chat application for iOS that leverages Apple Intelligence's Foundation Models framework for on-device AI capabilities. Built with SwiftUI and featuring iOS 26 Beta's Liquid Glass UI design system, Vesta provides a modern, privacy-focused AI assistant experience.

## Features

- **Apple Intelligence Integration**: Uses the Foundation Models framework for on-device AI processing
- **Liquid Glass UI**: Modern iOS 26 Beta design with glass effects and animations  
- **Real-time Chat**: Streaming responses with smooth animations
- **Voice Input**: Speech-to-text functionality for hands-free interaction
- **Math Rendering**: LaTeX equation support with MathJax integration
- **Privacy-First**: All AI processing happens on-device - no data leaves your device

## Requirements

- **iOS**: 26.0+ Beta
- **Device**: iPhone 15 Pro/Pro Max or iPhone 16 series (required for Apple Intelligence)
- **Xcode**: 26.0 Beta or later
- **Swift**: 5.0+

## Dependencies

The project uses Swift Package Manager for dependency management:

- **MarkdownUI** (2.4.1): Rich markdown rendering with custom styling
- **NetworkImage** (6.0.1): Efficient image loading and caching
- **Swift Algorithms** (1.2.1): Additional Swift algorithms
- **Swift Numerics** (1.0.3): Numerical computing utilities

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd Vesta
   ```

2. **Open the project:**
   ```bash
   open Vesta.xcodeproj
   ```

3. **Configure your development team:**
   - In Xcode, select the project in the navigator
   - Under "Signing & Capabilities", select your development team
   - Ensure the bundle identifier is unique if needed

4. **Build and run:**
   - Select an iOS 26 Beta simulator or connected device
   - Press Cmd+R to build and run

## Development Commands

### Building
```bash
# Build the project
xcodebuild -project Vesta.xcodeproj -scheme Vesta -configuration Debug build
```

### Testing
```bash
# Run all tests
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only unit tests
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VestaTests

# Run only UI tests
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:VestaUITests
```

## Project Structure

```
Vesta/
├── Vesta/                          # Main app source code
│   ├── VestaApp.swift             # App entry point
│   ├── ContentView.swift          # Main chat interface
│   ├── Assets.xcassets/           # App icons and assets
│   └── Info.plist                 # App configuration
├── VestaTests/                     # Unit tests
│   └── VestaTests.swift
├── VestaUITests/                   # UI tests
│   ├── VestaUITests.swift
│   └── VestaUITestsLaunchTests.swift
├── Vesta.xcodeproj/               # Xcode project files
├── CLAUDE.md                      # Development guidelines
└── README.md                      # This file
```

## Architecture

### Core Components

- **VestaApp.swift**: Main app entry point using SwiftUI's `@main` attribute
- **ContentView.swift**: Primary chat interface featuring:
  - Apple Intelligence integration via Foundation Models
  - Streaming chat responses
  - Voice recognition with Speech framework
  - LaTeX math rendering with WebKit/MathJax
  - Liquid Glass UI design elements

### Key Features Implementation

**Apple Intelligence**:
- Uses `LanguageModelSession` for on-device AI processing
- Streams responses asynchronously for real-time updates
- No data transmission to external servers

**Speech Recognition**:
- Integrated with AVFoundation and Speech frameworks
- Real-time speech-to-text conversion
- Visual feedback for recording state

**Math Rendering**:
- Custom LaTeX parser supporting inline and block equations
- WebKit-based MathJax rendering
- Supports multiple LaTeX notation formats

## iOS 26 Beta Features

Vesta takes advantage of several iOS 26 Beta enhancements:

- **Liquid Glass UI**: Modern glass effects with materials and gradients
- **Enhanced SwiftUI**: WebView integration, rich-text editing capabilities
- **@Animatable Macro**: Smoother view animations
- **Foundation Models**: On-device LLM capabilities
- **Improved Navigation**: Enhanced TabView and scroll behaviors

## Configuration

The app can be customized through the session initialization in `ContentView.swift`:

```swift
private func initializeSession() {
    session = LanguageModelSession(instructions: """
    You are a helpful AI assistant. Provide clear, concise, and friendly responses...
    """)
}
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Privacy

Vesta prioritizes user privacy:
- All AI processing occurs on-device using Apple Intelligence
- No chat data is transmitted to external servers
- Voice recordings are processed locally only
- No user data collection or tracking

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on the repository or contact the development team.

---

**Bundle Identifier**: `soprano.Vesta`  
**Deployment Target**: iOS 26.0 Beta  
**Swift Version**: 5.0
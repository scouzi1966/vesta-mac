# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS SwiftUI application created with Xcode 26.0 Beta, targeting macOS 26.0+. The project follows the standard Xcode project structure with SwiftUI and includes both unit tests and UI tests.

**macOS 26 Features:**
- **Apple Intelligence Integration**: Uses FoundationModels framework for on-device LLM capabilities
- Modern SwiftUI design adapted for desktop use with Liquid Glass effects
- Built with latest SwiftUI enhancements including WebView, rich-text editing, and modern material backgrounds
- Native macOS window management and sizing
- Speech recognition and audio input support
- Mathematical content rendering with MathJax

**Project Structure:**
- `Vesta/` - Main app source code
- `VestaTests/` - Unit tests using XCTest
- `VestaUITests/` - UI tests using XCTest
- `Vesta.xcodeproj/` - Xcode project configuration

## Development Commands

**Build the project:**
```bash
xcodebuild -project Vesta.xcodeproj -scheme Vesta -configuration Debug build
```

**Run unit tests:**
```bash
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=macOS'
```

**Run UI tests:**
```bash
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=macOS' -only-testing:VestaUITests
```

**Run unit tests only:**
```bash
xcodebuild test -project Vesta.xcodeproj -scheme Vesta -destination 'platform=macOS' -only-testing:VestaTests
```

**Build and run the app:**
```bash
xcodebuild -project Vesta.xcodeproj -scheme Vesta -configuration Debug build && open build/Debug/Vesta.app
```

## Architecture

**App Entry Point:** `VestaApp.swift` contains the main App struct using SwiftUI's `@main` attribute

**Main View:** `ContentView.swift` contains the AI chat interface with mock AI responses (ready for integration with external AI services)

**Testing:** Standard XCTest framework is used for both unit tests and UI tests. Test files include basic template methods for setup, teardown, and example tests.

**Bundle Identifier:** `soprano.Vesta-mac`

**Deployment Target:** macOS 26.0

**Swift Version:** 5.0 with modern Swift features enabled including:
- Swift 6 language mode features
- String catalog symbol generation
- Actor isolation on MainActor

## macOS Development Notes

**macOS UI Considerations:**
- Uses modern SwiftUI materials (`.regularMaterial`, `.thinMaterial`) for native macOS appearance
- Adapted window management with proper sizing and resizability
- Speech recognition works with macOS microphone permissions
- MathJax integration via WebKit for mathematical content rendering

**Apple Intelligence Integration:**
- Uses FoundationModels framework for on-device LLM capabilities
- Streaming responses via `session.streamResponse(to:)` method
- Maintains user privacy with on-device processing
- Supports mathematical content with LaTeX notation
- Seamless integration with SwiftUI through declarative data binding

**Requirements:**
- macOS 26.0+ with Apple Intelligence support
- Mac with M1 or later chip (M4 Pro recommended)
- Sufficient storage (7GB+ available)
- Language settings configured for supported regions

**macOS-Specific Testing:**
- Test on macOS 26.0+ systems with Apple Intelligence support
- Verify Apple Intelligence integration and streaming responses
- Verify window behavior and resizing
- Test speech recognition with macOS microphone permissions
- Verify material backgrounds and Liquid Glass effects appear correctly in light/dark modes
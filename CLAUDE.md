# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS SwiftUI application created with Xcode 26.0 Beta, targeting iOS 26.0+ Beta. The project follows the standard Xcode project structure with SwiftUI and includes both unit tests and UI tests.

**iOS 26 Beta Features:**
- Uses the new Liquid Glass UI design system introduced in iOS 26
- Supports dynamic clock adaptation and Clear mode for Home Screen icons
- Built with latest SwiftUI enhancements including WebView, rich-text editing, and @Animatable macro
- Includes improvements for TabView minimization, section spacing, and navigation subtitles
- **Apple Intelligence Integration**: Access to Foundation Models framework for on-device LLM capabilities

**Project Structure:**
- `Claude-vscode-test/` - Main app source code
- `Claude-vscode-testTests/` - Unit tests using XCTest
- `Claude-vscode-testUITests/` - UI tests using XCTest
- `Claude-vscode-test.xcodeproj/` - Xcode project configuration

## Development Commands

**Build the project:**
```bash
xcodebuild -project Claude-vscode-test.xcodeproj -scheme Claude-vscode-test -configuration Debug build
```

**Run unit tests:**
```bash
xcodebuild test -project Claude-vscode-test.xcodeproj -scheme Claude-vscode-test -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Run UI tests:**
```bash
xcodebuild test -project Claude-vscode-test.xcodeproj -scheme Claude-vscode-test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Claude-vscode-testUITests
```

**Run unit tests only:**
```bash
xcodebuild test -project Claude-vscode-test.xcodeproj -scheme Claude-vscode-test -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Claude-vscode-testTests
```

## Architecture

**App Entry Point:** `Claude_vscode_testApp.swift` contains the main App struct using SwiftUI's `@main` attribute

**Main View:** `ContentView.swift` contains the primary SwiftUI view with a simple "Hello, world!" interface

**Testing:** Standard XCTest framework is used for both unit tests and UI tests. Test files include basic template methods for setup, teardown, and example tests.

**Bundle Identifier:** `soprano.Claude-vscode-test`

**Deployment Target:** iOS 26.0

**Swift Version:** 5.0 with modern Swift features enabled including:
- Swift 6 language mode features
- String catalog symbol generation
- Actor isolation on MainActor

## iOS 26 Beta Development Notes

**Liquid Glass UI Considerations:**
- When developing UI components, consider the new Liquid Glass design system
- Use the new @Animatable macro for smoother view animations
- Leverage improved SwiftUI features like WebView and rich-text editing with TextView
- Consider TabView minimization behavior on scroll for navigation design

**Apple Intelligence & Foundation Models Framework:**
- Import `FoundationModels` framework for on-device LLM capabilities
- Use `streamResponse` method for async sequence of partially generated responses
- Integrate seamlessly with SwiftUI through declarative data binding
- Optimize for on-device tasks: summarization, extraction, classification
- Benefits: Works offline, protects privacy, no inference costs
- Supports guided generation and tool calling
- Compatible with iPhone 15 Pro/Pro Max and iPhone 16 series

**Example Integration Pattern:**
```swift
import FoundationModels
import SwiftUI

// Stream responses and update UI declaratively
// Ideal for summarizing content, generating suggestions, or extracting information
```

**Beta-Specific Testing:**
- Test on iOS 26 beta simulators and devices (iPhone 15 Pro+ or iPhone 16 series)
- Verify compatibility with Liquid Glass UI elements
- Test new SwiftUI features like section index labels and custom scroll edge effects
- Test Foundation Models integration for on-device AI features
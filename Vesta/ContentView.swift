//
//  ContentView.swift
//  Vesta
//
//  Created by Sylvain Cousineau on 2025-06-23.
//

import SwiftUI
import FoundationModels
import MarkdownUI
import Speech
import AVFoundation
import WebKit
import AppKit
import UniformTypeIdentifiers

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date = Date()
}

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var session: LanguageModelSession?
    @State private var headerOpacity: Double = 1.0
    @State private var streamingText: String = ""
    @State private var isStreaming: Bool = false
    @State private var isRecording: Bool = false
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine: AVAudioEngine = AVAudioEngine()
    
    @State private var showInstructionsEditor = false
    @State private var currentInstructions: String = """
    You are a helpful AI assistant. Provide clear, concise, and friendly responses to user questions and requests. 
    Keep responses conversational and maintain context from previous messages in our conversation.
    
    For mathematical content, use LaTeX notation:
    - Inline math: $equation$
    - Block math: $$equation$$
    
    Examples:
    - Inline: The quadratic formula is $x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}$
    - Block: $$E = mc^2$$
    """
    
    @State private var showAdapterPicker = false
    @State private var currentAdapter: SystemLanguageModel.Adapter?
    @State private var adapterName: String?
    @State private var isLoadingAdapter = false
    @State private var showAdapterError = false
    @State private var adapterErrorMessage = ""

    var body: some View {
        ZStack {
            // macOS Background
            LinearGradient(
                colors: [
                    Color(.windowBackgroundColor).opacity(0.95),
                    Color(.controlBackgroundColor).opacity(0.8),
                    Color(.windowBackgroundColor).opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // Header for macOS
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vesta AI")
                            .font(.headline)
                            .fontWeight(.semibold)
                        HStack(spacing: 4) {
                            Text("Powered by Apple Intelligence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let adapterName = adapterName {
                                Text("•")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Custom: \(adapterName)")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(.green.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(.green.gradient)
                        .frame(width: 8, height: 8)
                        .shadow(color: .green, radius: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                .opacity(headerOpacity)
            
                // Chat Messages with Glass Scroll View
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                VStack(spacing: 24) {
                                    ZStack {
                                        Circle()
                                            .fill(.thinMaterial)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Circle()
                                                    .stroke(.linearGradient(
                                                        colors: [.white.opacity(0.5), .clear],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ), lineWidth: 2)
                                            )
                                        
                                        Image(systemName: "brain.head.profile.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.linearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    }
                                    .scaleEffect(1.0)
                                    .symbolEffect(.breathe.byLayer, isActive: true)
                                    
                                    VStack(spacing: 8) {
                                        Text("Welcome to Vesta AI")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Text("Start a conversation with Apple Intelligence")
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.top, 80)
                                .padding(.horizontal, 40)
                            }
                            
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)
                                    ))
                            }
                            
                            // Show streaming message separately
                            if isStreaming && !streamingText.isEmpty {
                                ChatBubble(message: ChatMessage(content: streamingText, isUser: false))
                                    .id("streaming")
                            }
                            
                            // Invisible anchor for smooth scrolling
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                            
                            if isLoading {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(.thinMaterial)
                                            .frame(width: 40, height: 40)
                                        
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.secondary)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Vesta is thinking...")
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                        Text("Powered by Apple Intelligence")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                    .scrollClipDisabled()
                    .onChange(of: messages.count) { _, _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: streamingText) { _, _ in
                        // Only scroll during streaming, with gentle animation
                        if isStreaming {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.linear(duration: 0.1)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        geometry.contentOffset.y
                    } action: { _, newValue in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            headerOpacity = newValue > 50 ? 0.9 : 1.0
                        }
                    }
                }
            
                // Glass Input Area with iOS 26 Design
                VStack(spacing: 8) {
                    // Input container with glass effect
                    HStack(spacing: 8) {
                        // New chat button with iOS 26 Liquid Glass design
                        Button(action: startNewChat) {
                            ZStack {
                                // Glass background
                                Circle()
                                    .fill(.thinMaterial)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(.linearGradient(
                                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ), lineWidth: 1.5)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                // Icon with glass effect
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.linearGradient(
                                        colors: messages.isEmpty ? 
                                            [.secondary, .secondary.opacity(0.6)] : 
                                            [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .symbolEffect(.bounce, value: !messages.isEmpty)
                            }
                        }
                        .disabled(messages.isEmpty)
                        .scaleEffect(messages.isEmpty ? 0.85 : 1.0)
                        .opacity(messages.isEmpty ? 0.6 : 1.0)
                        .animation(.bouncy(duration: 0.4, extraBounce: 0.1), value: messages.isEmpty)
                        
                        // Microphone button with iOS 26 Liquid Glass design
                        Button(action: toggleSpeechRecognition) {
                            ZStack {
                                // Glass background
                                if isRecording {
                                    Circle()
                                        .fill(.red.opacity(0.8))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(.linearGradient(
                                                    colors: [.red.opacity(0.6), .red.opacity(0.2)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ), lineWidth: 1.5)
                                        )
                                        .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                                } else {
                                    Circle()
                                        .fill(.thinMaterial)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(.linearGradient(
                                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ), lineWidth: 1.5)
                                        )
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                                
                                // Icon with recording state
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(
                                        isRecording
                                            ? LinearGradient(colors: [.white, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .symbolEffect(.pulse.byLayer, isActive: isRecording)
                            }
                        }
                        .scaleEffect(isRecording ? 1.05 : 1.0)
                        .animation(.bouncy(duration: 0.3), value: isRecording)
                        
                        // New instructions edit button
                        Button(action: {
                            showInstructionsEditor = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.thinMaterial)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .help("Edit Model Instructions")
                        
                        // LoRA Adapter loading button
                        Button(action: {
                            showAdapterPicker = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.thinMaterial)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(currentAdapter != nil ? 
                                                LinearGradient(colors: [.green.opacity(0.6), .green.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                                lineWidth: 1.5)
                                    )
                                
                                if isLoadingAdapter {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(.orange)
                                } else {
                                    Image(systemName: currentAdapter != nil ? "doc.badge.gearshape.fill" : "doc.badge.gearshape")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(currentAdapter != nil ? .green : .orange)
                                        .symbolEffect(.bounce, value: adapterName)
                                }
                            }
                        }
                        .help(currentAdapter != nil ? "Custom adapter loaded: \(adapterName ?? "Unknown")\nRight-click for options" : "Load LoRA Adapter")
                        .disabled(isLoadingAdapter)
                        .contextMenu {
                            if currentAdapter != nil {
                                Button("Load Different Adapter") {
                                    showAdapterPicker = true
                                }
                                Button("Test Hardcoded Adapter") {
                                    Task {
                                        await loadHardcodedAdapter()
                                    }
                                }
                                Button("Reset to Default Model") {
                                    resetAdapter()
                                }
                            } else {
                                Button("Test Hardcoded Adapter") {
                                    Task {
                                        await loadHardcodedAdapter()
                                    }
                                }
                            }
                        }
                        
                        // Glass text field
                        HStack(spacing: 8) {
                            TextField("Message Vesta AI...", text: $inputText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(1...4)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .onSubmit {
                                    sendMessage()
                                }
                        }
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.linearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                        
                        // Send button with enhanced glass effect
                        Button(action: sendMessage) {
                            ZStack {
                                Circle()
                                    .fill(.linearGradient(
                                        colors: inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 
                                            [.gray.opacity(0.3), .gray.opacity(0.2)] : 
                                            [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 28, height: 28)
                                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .symbolEffect(.bounce, value: inputText)
                            }
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading)
                        .scaleEffect(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading ? 0.9 : 1.0)
                        .animation(.bouncy(duration: 0.3), value: inputText.isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Apple Intelligence attribution
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Apple Intelligence")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 6)
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.linearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ), lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
            }
        }
        .onAppear {
            initializeSession()
            setupSpeechRecognition()
        }
        .sheet(isPresented: $showInstructionsEditor) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Model Instructions")
                    .font(.headline)
                Text("Edit the instructions that guide Vesta AI's behavior. The default is suitable for most use cases.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $currentInstructions)
                    .font(.body)
                    .frame(minHeight: 200)
                    .border(Color.gray.opacity(0.3), width: 1)
                HStack {
                    Button("Cancel") {
                        showInstructionsEditor = false
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Save") {
                        showInstructionsEditor = false
                        initializeSession()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 400)
        }
        .fileImporter(
            isPresented: $showAdapterPicker,
            allowedContentTypes: [
                UTType("com.apple.foundation-model-adapter") ?? .folder,
                UTType.package,
                UTType.folder
            ],
            allowsMultipleSelection: false
        ) { result in
            Task {
                await handleAdapterSelection(result)
            }
        }
        .alert("Adapter Loading Error", isPresented: $showAdapterError) {
            Button("OK") {
                showAdapterError = false
            }
        } message: {
            Text(adapterErrorMessage)
        }
    }
    
    private func initializeSession() {
        if let adapter = currentAdapter {
            // An instance of the system language model using your adapter
            let customAdapterModel = SystemLanguageModel(adapter: adapter)
            session = LanguageModelSession(model: customAdapterModel, instructions: currentInstructions)
            print("Session initialized with custom adapter")
        } else {
            session = LanguageModelSession(instructions: currentInstructions)
            print("Session initialized with default model")
        }
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                // Handle different authorization states if needed
            }
        }
    }
    
    private func toggleSpeechRecognition() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // macOS doesn't use AVAudioSession - permissions are handled differently
        // Audio engine setup will handle the audio input directly
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    inputText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    stopRecording()
                }
            }
        }
        
        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine start failed: \(error)")
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty, !isLoading else { return }
        
        // Stop any active speech recognition
        if isRecording {
            stopRecording()
        }
        
        // Add user message
        messages.append(ChatMessage(content: userMessage, isUser: true))
        inputText = ""
        isLoading = true
        
        Task {
            await getAIResponse(for: userMessage)
        }
    }
    
    
    private func startNewChat() {
        messages.removeAll()
        inputText = ""
        isLoading = false
        initializeSession()
    }
    
    private func handleAdapterSelection(_ result: Result<[URL], Error>) async {
        // For testing purposes, use hardcoded adapter path
        await loadHardcodedAdapter()
    }
  /*
    
    // The absolute path to your adapter.
    let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")


    // Initialize the adapter by using the local URL.
    let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)

   // An instance of the the system language model using your adapter.
   let customAdapterModel = SystemLanguageModel(adapter: adapter)


   // Create a session and prompt the model.
   let session = LanguageModelSession(model: customAdapterModel)
   let response = try await session.respond(to: "Your prompt here")
*/
    private func loadHardcodedAdapter() async {
        await MainActor.run {
            isLoadingAdapter = true
        }
        
        do {
            // The absolute path to your test adapter - the actual .fmadapter directory
          let localURL = URL(filePath: "/Users/syl/Downloads/adapter_training_toolkit_v26_0_0-s/train/test_lora.fmadapter")
 
            // Initialize the adapter by using the local URL
            let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)
            
            await MainActor.run {
                currentAdapter = adapter
                adapterName = "test_lora" // Hardcoded name for testing
                isLoadingAdapter = false
                
                // Reinitialize session with new adapter
                initializeSession()
                print("Successfully loaded test adapter from: \(localURL.path)")
            }
            
        } catch {
            await MainActor.run {
                isLoadingAdapter = false
                adapterErrorMessage = "Failed to load test adapter: \(error.localizedDescription)"
                showAdapterError = true
                print("Failed to load test adapter: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetAdapter() {
        currentAdapter = nil
        adapterName = nil
        initializeSession()
    }
    
    private func getAIResponse(for userInput: String) async {
        guard let session = session else {
            await MainActor.run {
                messages.append(ChatMessage(content: "Sorry, I'm having trouble connecting. Please try again.", isUser: false))
                isLoading = false
            }
            return
        }
        
        await MainActor.run {
            isLoading = false
            isStreaming = true
            streamingText = ""
        }
        
        do {
            let stream = session.streamResponse(to: userInput)
            
            for try await partialText in stream {
                await MainActor.run {
                    streamingText = partialText.content
                }
                // Small delay to make it readable
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            }
            
            // Move to permanent messages after streaming completes
            await MainActor.run {
                let finalText = streamingText
                messages.append(ChatMessage(content: finalText, isUser: false))
                isStreaming = false
                streamingText = ""
            }
            
        } catch {
            await MainActor.run {
                isStreaming = false
                streamingText = ""
                messages.append(ChatMessage(content: "Sorry, I encountered an error. Please try again.", isUser: false))
                isLoading = false
            }
        }
    }
}

struct MathMarkdownView: View {
    let content: String
    let foregroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Split content by LaTeX blocks and inline equations
            let parts = parseContent(content)
            
            // If no LaTeX content found, just use regular Markdown
            if parts.allSatisfy({ if case .markdown = $0 { return true } else { return false } }) {
                Markdown(content)
                    .foregroundStyle(foregroundColor)
            } else {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    switch part {
                    case .markdown(let text):
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Markdown(text)
                                .foregroundStyle(foregroundColor)
                        }
                    case .latexBlock(let latex):
                        MathView(equation: latex, displayStyle: true, textColor: foregroundColor)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    case .latexInline(let latex):
                        MathView(equation: latex, displayStyle: false, textColor: foregroundColor)
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private func parseContent(_ content: String) -> [ContentPart] {
        var parts: [ContentPart] = []
        var currentText = ""
        var i = content.startIndex
        
        while i < content.endIndex {
            // Check for block LaTeX \[...\]
            if content[i...].hasPrefix("\\[") {
                if !currentText.isEmpty {
                    parts.append(.markdown(currentText))
                    currentText = ""
                }
                
                let startIndex = content.index(i, offsetBy: 2)
                if let endRange = content[startIndex...].range(of: "\\]") {
                    let latexContent = String(content[startIndex..<endRange.lowerBound])
                    parts.append(.latexBlock(latexContent))
                    i = endRange.upperBound
                } else {
                    currentText.append(content[i])
                    i = content.index(after: i)
                }
            }
            // Check for block LaTeX ($$...$$)
            else if content[i...].hasPrefix("$$") {
                if !currentText.isEmpty {
                    parts.append(.markdown(currentText))
                    currentText = ""
                }
                
                let startIndex = content.index(i, offsetBy: 2)
                if let endRange = content[startIndex...].range(of: "$$") {
                    let latexContent = String(content[startIndex..<endRange.lowerBound])
                    parts.append(.latexBlock(latexContent))
                    i = endRange.upperBound
                } else {
                    currentText.append(content[i])
                    i = content.index(after: i)
                }
            }
            // Check for inline LaTeX \(...\)
            else if content[i...].hasPrefix("\\(") {
                if !currentText.isEmpty {
                    parts.append(.markdown(currentText))
                    currentText = ""
                }
                
                let startIndex = content.index(i, offsetBy: 2)
                if let endRange = content[startIndex...].range(of: "\\)") {
                    let latexContent = String(content[startIndex..<endRange.lowerBound])
                    parts.append(.latexInline(latexContent))
                    i = endRange.upperBound
                } else {
                    currentText.append(content[i])
                    i = content.index(after: i)
                }
            }
            // Check for inline LaTeX ($...$)
            else if content[i] == "$" {
                if !currentText.isEmpty {
                    parts.append(.markdown(currentText))
                    currentText = ""
                }
                
                let startIndex = content.index(after: i)
                if let endIndex = content[startIndex...].firstIndex(of: "$") {
                    let latexContent = String(content[startIndex..<endIndex])
                    parts.append(.latexInline(latexContent))
                    i = content.index(after: endIndex)
                } else {
                    currentText.append(content[i])
                    i = content.index(after: i)
                }
            }
            // Check for square bracket LaTeX [...]
            else if content[i] == "[" && content[i...].contains("]") {
                let remainder = content[i...]
                if let endIndex = remainder.firstIndex(of: "]") {
                    let startIndex = content.index(after: i)
                    let latexContent = String(content[startIndex..<endIndex])
                    
                    // Check if this looks like a mathematical expression
                    if latexContent.contains("\\") || latexContent.contains("mathbf") || latexContent.contains("nabla") || latexContent.contains("cdot") || latexContent.contains("frac") || latexContent.contains("partial") || latexContent.contains("times") || latexContent.contains("varepsilon") || latexContent.contains("mu_") {
                        if !currentText.isEmpty {
                            parts.append(.markdown(currentText))
                            currentText = ""
                        }
                        parts.append(.latexInline(latexContent))
                        i = content.index(after: endIndex)
                    } else {
                        currentText.append(content[i])
                        i = content.index(after: i)
                    }
                } else {
                    currentText.append(content[i])
                    i = content.index(after: i)
                }
            } else {
                currentText.append(content[i])
                i = content.index(after: i)
            }
        }
        
        if !currentText.isEmpty {
            parts.append(.markdown(currentText))
        }
        
        return parts
    }
}

enum ContentPart {
    case markdown(String)
    case latexBlock(String)
    case latexInline(String)
}

struct MathView: NSViewRepresentable {
    let equation: String
    let displayStyle: Bool
    let textColor: Color
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let mathDelimiters = displayStyle ? "\\[" + equation + "\\]" : "\\(" + equation + "\\)"
        
        // Convert SwiftUI Color to CSS color
        let cssColor = colorToCSS(textColor)
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            <script>
                window.MathJax = {
                    tex: { inlineMath: [['\\\\(', '\\\\)']], displayMath: [['\\\\[', '\\\\]']] },
                    chtml: { scale: 0.9 }
                };
            </script>
            <style>
                body {
                    margin: 0;
                    padding: 8px;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: transparent;
                    color: \(cssColor) !important;
                    text-align: \(displayStyle ? "center" : "left");
                }
                /* Force MathJax to use our color */
                .MathJax {
                    color: \(cssColor) !important;
                }
                mjx-math {
                    color: \(cssColor) !important;
                }
                mjx-mrow {
                    color: \(cssColor) !important;
                }
                /* Target all MathJax elements */
                [class*="mjx"] {
                    color: \(cssColor) !important;
                }
            </style>
        </head>
        <body>
            \(mathDelimiters)
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func colorToCSS(_ color: Color) -> String {
        // Convert SwiftUI Color to NSColor to get RGB values
        let nsColor: NSColor
        
        // Handle common SwiftUI colors
        switch color {
        case .primary:
            nsColor = NSColor.labelColor // System primary text color
        case .white:
            nsColor = NSColor.white
        case .black:
            nsColor = NSColor.black
        case .secondary:
            nsColor = NSColor.secondaryLabelColor
        default:
            // Try to convert to NSColor via CGColor
            nsColor = NSColor.labelColor // fallback to system label color
        }
        
        // Convert to RGB hex
        guard let rgbColor = nsColor.usingColorSpace(.sRGB) else {
            return "#000000" // fallback to black
        }
        
        let red = Int(round(rgbColor.redComponent * 255))
        let green = Int(round(rgbColor.greenComponent * 255))  
        let blue = Int(round(rgbColor.blueComponent * 255))
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    @State private var isVisible = false
    @State private var showCopyFeedback = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isUser {
                Spacer(minLength: 40)
            } else {
                // AI Avatar with glass effect
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(.linearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                // Message content with enhanced glass bubble
                VStack(alignment: .leading, spacing: 0) {
                    MathMarkdownView(
                        content: message.content,
                        foregroundColor: message.isUser ? .white : .primary
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    ZStack {
                        if message.isUser {
                            // User message: gradient glass effect
                            LinearGradient(
                                colors: [.blue, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            // AI message: subtle glass material
                            Color.clear
                                .background(.thinMaterial)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.linearGradient(
                                colors: message.isUser ? 
                                    [.white.opacity(0.4), .clear] :
                                    [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 1)
                    )
                )
                .shadow(
                    color: message.isUser ? .blue.opacity(0.3) : .black.opacity(0.1),
                    radius: message.isUser ? 8 : 4,
                    x: 0,
                    y: message.isUser ? 2 : 1
                )
                .textSelection(.enabled)
                
                // Timestamp with glass styling
                HStack(spacing: 4) {
                    if !message.isUser {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 8))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                    
                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                    
                    // Copy button for AI messages only
                    if !message.isUser {
                        Button(action: {
                            copyToClipboard(message.content)
                        }) {
                            Image(systemName: showCopyFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                                .frame(width: 16, height: 16)
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                        .background(.ultraThinMaterial, in: Circle())
                        .opacity(0.8)
                        .scaleEffect(showCopyFeedback ? 1.1 : 1.0)
                        .animation(.bouncy(duration: 0.3), value: showCopyFeedback)
                    }
                }
            }
            
            if !message.isUser {
                Spacer(minLength: 40)
            } else {
                // User indicator
                ZStack {
                    Circle()
                        .fill(.thinMaterial)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(.linearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.1)) {
                isVisible = true
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Show feedback
        withAnimation(.bouncy(duration: 0.3)) {
            showCopyFeedback = true
        }
        
        // Reset feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.bouncy(duration: 0.3)) {
                showCopyFeedback = false
            }
        }
    }
}

#Preview {
    ContentView()
}


//
//  ContentView.swift
//  Claude-vscode-test
//
//  Created by Sylvain Cousineau on 2025-06-23.
//

import SwiftUI
import FoundationModels

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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.tint)
                    .font(.title2)
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                Text("Start a conversation!")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 50)
                        }
                        
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.leading)
                            .id("loading")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isLoading) { _, newValue in
                    if newValue {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // Input Area
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    Button(action: startNewChat) {
                        Image(systemName: "plus.message")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(messages.isEmpty ? .gray : .green)
                            .clipShape(Circle())
                    }
                    .disabled(messages.isEmpty)
                    
                    TextField("Type your message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? .gray : .blue)
                            .clipShape(Circle())
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .onAppear {
            initializeSession()
        }
    }
    
    private func initializeSession() {
        session = LanguageModelSession(instructions: """
        You are a helpful AI assistant. Provide clear, concise, and friendly responses to user questions and requests. 
        Keep responses conversational and maintain context from previous messages in our conversation.
        """)
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty, !isLoading else { return }
        
        // Add user message
        messages.append(ChatMessage(content: userMessage, isUser: true))
        inputText = ""
        isLoading = true
        
        Task {
            await getAIResponse(for: userMessage)
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                if isLoading {
                    proxy.scrollTo("loading", anchor: .bottom)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    private func startNewChat() {
        messages.removeAll()
        inputText = ""
        isLoading = false
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
        
        do {
            let stream = session.streamResponse(to: userInput)
            var accumulatedResponse = ""
            var currentMessageIndex: Int?
            
            for try await partialText in stream {
                await MainActor.run {
                    accumulatedResponse = partialText
                    
                    if let index = currentMessageIndex {
                        // Update existing message
                        messages[index] = ChatMessage(content: accumulatedResponse, isUser: false)
                    } else {
                        // Add new message
                        messages.append(ChatMessage(content: accumulatedResponse, isUser: false))
                        currentMessageIndex = messages.count - 1
                    }
                    
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                messages.append(ChatMessage(content: "Sorry, I encountered an error. Please try again.", isUser: false))
                isLoading = false
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? .blue : .gray.opacity(0.2))
                    .foregroundStyle(message.isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    ContentView()
}

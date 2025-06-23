//
//  ContentView.swift
//  Claude-vscode-test
//
//  Created by Sylvain Cousineau on 2025-06-23.
//

import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var haikuText: String = "Generating haiku..."
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "horse.circle")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            }
            
            Text(haikuText)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding()
            
            Button("Generate Another Haiku") {
                Task {
                    isLoading = true
                    haikuText = "Generating haiku..."
                    await generateHaiku()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
        }
        .padding()
        .task {
            await generateHaiku()
        }
    }
    
    private func generateHaiku() async {
        do {
            let session = LanguageModelSession()
            let prompt = "Write a short haiku poem about horses. Format it as three lines with 5-7-5 syllables."
            
            let stream = session.streamResponse(to: prompt)
            
            for try await partialText in stream {
                await MainActor.run {
                    haikuText = partialText
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                haikuText = "Graceful horses run\nThrough meadows of morning dew\nFreedom in motion"
                isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}

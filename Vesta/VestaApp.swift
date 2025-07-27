//
//  VestaApp.swift
//  Vesta
//
//  Created by Sylvain Cousineau on 2025-06-23.
//

import SwiftUI

@main
struct VestaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 800, height: 600)
    }
}

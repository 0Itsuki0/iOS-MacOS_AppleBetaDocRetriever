//
//  AppleBetaDocRetrieverApp.swift
//  AppleBetaDocRetriever
//
//  Created by Itsuki on 2026/04/04.
//

import SwiftUI

@main
struct AppleBetaDocRetrieverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
            .windowResizability(.contentSize)
        #endif
    }
}

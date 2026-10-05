//
//  TranslatorApp.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//

import SwiftUI

@main
struct TranslatorApp: App {
    @State private var translator = TranslatorModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(translator)
        }
    }
}

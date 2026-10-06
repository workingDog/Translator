//
//  TranslatorApp.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//

import SwiftUI
import SwiftData



@main
struct TranslatorApp: App {
    @State private var translator = TranslatorModel()
    
    
    var sharedModelContainer: ModelContainer = {
        let appSupportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        do {
            try FileManager.default.createDirectory(
                at: appSupportDir,
                withIntermediateDirectories: true
            )
        } catch {
            print("Couldn't create Application Support:", error)
            fatalError("Couldn't create Application Support directory: \(error)")
        }
        let storeURL = appSupportDir.appending(path: "translator.sqlite")
        print("\n---> database at: \(storeURL.absoluteString)\n")
        let schema = Schema([TranslatedMenu.self])
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Could not create ModelContainer:", error)
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(translator)
        }
        .modelContainer(sharedModelContainer)
    }
}

//
//  SettingsView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/12.
//

import SwiftUI


struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(TranslatorModel.self) private var translator
    
    var body: some View {
        @Bindable var translator = translator
        
        ZStack {
            AppBackground().ignoresSafeArea()
            
            VStack (alignment: .leading, spacing: 20) {
                if ProcessInfo.processInfo.isiOSAppOnMac {
                    HStack {
                        Button("Done") {
                            dismiss()
                        }.buttonStyle(.glass)
                        Spacer()
                        Text("Settings").font(.title).bold()
                        Spacer()
                    }
                }
                HStack {
                    Text("Correction buttons")
                        .font(.title2)
                        .padding(20)
                    Toggle("", isOn: $translator.showPerspective).fixedSize()
                    Spacer()
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .padding(10)
        }
    }
    
}

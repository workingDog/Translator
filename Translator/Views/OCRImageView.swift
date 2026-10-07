//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


 struct OCRImageView: View {
     @Environment(TranslatorModel.self) private var translator
 
     var body: some View {
         if let image = translator.selectedImage {
             ZoomableImageView(
                 image: image,
                 items: translator.ocrTextItems,
                 translations: translator.translatedText
             )
         }
     }
 
 }

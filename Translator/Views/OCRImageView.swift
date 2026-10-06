//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import PhotosUI
import Translation
import Vision
import UIKit
import ImageIO


struct OCRImageView: View {
    
    let image: UIImage
    let items: [OCRTextItem]
    var translatedText: [UUID: String] = [:]

    var body: some View {
        GeometryReader { geometry in
            let imageSize = image.size
            let scale = min(
                geometry.size.width / imageSize.width,
                geometry.size.height / imageSize.height
            )
            let displayedWidth = imageSize.width * scale
            let displayedHeight = imageSize.height * scale
            let offsetX = (geometry.size.width - displayedWidth) / 2
            let offsetY = (geometry.size.height - displayedHeight) / 2
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                ForEach(items) { item in
                    let box = item.boundingBox
                    let x = offsetX + box.midX * displayedWidth
                    let y = offsetY + (1 - box.midY) * displayedHeight
                    let width = box.width * displayedWidth
                    let height = box.height * displayedHeight
                    Text(translatedText[item.id] ?? item.text)
                        .font(.system(size: max(height * 0.75, 8)))
                        .frame(width: width, height: height)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

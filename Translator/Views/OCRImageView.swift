//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


/*
struct OCRImageView: View {
    
    @Environment(TranslatorModel.self) private var translator
    
    let fontScale: Double
    
    var body: some View {
        if let image = translator.selectedImage {
            ZoomableImageView(
                image: image,
                items: translator.ocrTextItems,
                translations: translator.translatedText,
                fontScale: fontScale
            )
        }
    }
}
*/

struct OCRImageView: View {
    @Environment(TranslatorModel.self) private var translator
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var gestureStartZoom: CGFloat = 1.0
    @State private var gestureStartOffset: CGSize = .zero
    @State private var gestureStartAnchor: CGPoint = .zero
    @State private var isPinching = false
    
    var body: some View {
        if let image = translator.selectedImage {
            GeometryReader { geometry in
                let baseWidth: CGFloat = 800
                let baseHeight = baseWidth * image.size.height / image.size.width
                let canvasSize = CGSize(width: baseWidth, height: baseHeight)
                
                ZStack {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: canvasSize.width, height: canvasSize.height)
                        ForEach(translator.ocrTextItems) { item in
                            OCRTextOverlay(
                                item: item,
                                text: translator.translatedText[item.id] ?? item.text,
                                imageSize: image.size,
                                containerSize: canvasSize
                            )
                        }
                    }
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .scaleEffect(zoomScale, anchor: .topLeading)
                    .offset(panOffset)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard !isPinching else { return }
                            panOffset = constrainedOffset(
                                CGSize(
                                    width: gestureStartOffset.width + value.translation.width,
                                    height: gestureStartOffset.height + value.translation.height
                                ),
                                zoomScale: zoomScale,
                                canvasSize: canvasSize,
                                viewportSize: geometry.size
                            )
                        }
                        .onEnded { _ in
                            gestureStartOffset = panOffset
                        }
                )
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            if !isPinching {
                                isPinching = true
                                gestureStartZoom = zoomScale
                                gestureStartOffset = panOffset
                                gestureStartAnchor = CGPoint(
                                    x: value.startAnchor.x * geometry.size.width,
                                    y: value.startAnchor.y * geometry.size.height
                                )
                            }
                            let newZoom = min(max(gestureStartZoom * value.magnification, 1.0), 4.0)
                            let contentX = (gestureStartAnchor.x - gestureStartOffset.width) / gestureStartZoom
                            let contentY = (gestureStartAnchor.y - gestureStartOffset.height) / gestureStartZoom
                            let newOffset = CGSize(
                                width: gestureStartAnchor.x - contentX * newZoom,
                                height: gestureStartAnchor.y - contentY * newZoom
                            )
                            zoomScale = newZoom
                            panOffset = constrainedOffset(
                                newOffset,
                                zoomScale: newZoom,
                                canvasSize: canvasSize,
                                viewportSize: geometry.size
                            )
                        }
                        .onEnded { _ in
                            isPinching = false
                            gestureStartZoom = zoomScale
                            gestureStartOffset = panOffset
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        zoomScale = 1.0
                        panOffset = .zero
                        gestureStartZoom = 1.0
                        gestureStartOffset = .zero
                    }
                }
            }
            .frame(height: min(600, 800 * image.size.height / image.size.width))
        }
    }
    
    private func constrainedOffset(_ offset: CGSize, zoomScale: CGFloat, canvasSize: CGSize, viewportSize: CGSize) -> CGSize {
        
        let scaledWidth = canvasSize.width * zoomScale
        let scaledHeight = canvasSize.height * zoomScale
        let minX = min(0, viewportSize.width - scaledWidth)
        let minY = min(0, viewportSize.height - scaledHeight)
        
        return CGSize(
            width: min(max(offset.width, minX), 0),
            height: min(max(offset.height, minY), 0)
        )
    }
    
}

struct OCRTextOverlay: View {
    @Environment(TranslatorModel.self) private var translator
    
    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize

    private var scale: CGFloat {
        min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
    }
    
    private var displayedSize: CGSize {
        CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }
    
    private var offsetX: CGFloat {
        (containerSize.width - displayedSize.width) / 2
    }
    private var offsetY: CGFloat {
        (containerSize.height - displayedSize.height) / 2
    }
    
    private var boxWidth: CGFloat {
        item.boundingBox.width * displayedSize.width
    }
    
    private var boxHeight: CGFloat {
        item.boundingBox.height * displayedSize.height
    }
    
    private var x: CGFloat {
        offsetX + item.boundingBox.midX * displayedSize.width
    }
    
    private var y: CGFloat {
        offsetY + (1 - item.boundingBox.midY) * displayedSize.height
    }
    
    private var fontSize: CGFloat {
        max(boxHeight * 0.72 * translator.fontScale, 8)
    }
    
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(.primary)
            .frame(width: boxWidth + 8, height: boxHeight + 4)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.background.opacity(0.92))
            }
            .position(x: x, y: y)
    }
}

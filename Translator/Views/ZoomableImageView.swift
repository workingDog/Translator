//
//  ZoomableImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


struct ZoomableImageView: View {
    
    let image: UIImage
    let items: [OCRTextItem]
    let translations: [UUID: String]
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var gestureStartZoom: CGFloat = 1.0
    @State private var gestureStartOffset: CGSize = .zero
    @State private var gestureStartAnchor: CGPoint = .zero
    @State private var isPinching = false
    
    
    var body: some View {
        GeometryReader { geometry in
            let baseWidth: CGFloat = 800
            let baseHeight = baseWidth * image.size.height / image.size.width
            let canvasSize = CGSize(width: baseWidth, height: baseHeight)
            
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: canvasSize.width, height: canvasSize.height)
                ForEach(items) { item in
                    OCRTextOverlay(
                        item: item,
                        text: translations[item.id] ?? item.text,
                        imageSize: image.size,
                        containerSize: canvasSize
                    )
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(zoomScale, anchor: .topLeading)
            .offset(panOffset)
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
                        let newZoom = min(max(gestureStartZoom * value.magnification, 0.5), 4.0)
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
    
    private func constrainedOffset(_ offset: CGSize, zoomScale: CGFloat, canvasSize: CGSize, viewportSize: CGSize) -> CGSize {
        let scaledWidth = canvasSize.width * zoomScale
        let scaledHeight = canvasSize.height * zoomScale
        let x: CGFloat
        let y: CGFloat
        if scaledWidth <= viewportSize.width {
            x = (viewportSize.width - scaledWidth) / 2
        } else {
            x = min(max(offset.width, viewportSize.width - scaledWidth), 0)
        }
        if scaledHeight <= viewportSize.height {
            y = (viewportSize.height - scaledHeight) / 2
        } else {
            y = min(max(offset.height, viewportSize.height - scaledHeight), 0)
        }
        return CGSize(width: x, height: y)
    }
    
}

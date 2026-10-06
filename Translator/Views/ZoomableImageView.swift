//
//  ZoomableImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI
import SwiftData


struct ZoomableImageView: View {
    let image: UIImage
    
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
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(zoomScale, anchor: .topLeading)
            .offset(panOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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

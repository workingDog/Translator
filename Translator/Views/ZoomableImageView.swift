//
//  ZoomableImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


struct ZoomableImageView: View {
    @Environment(TranslatorModel.self) private var translator
    
    let image: UIImage
    let items: [OCRTextItem]
    
    @State private var zoomScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @State private var gestureStartZoom: CGFloat = 1
    @State private var gestureStartOffset: CGSize = .zero
    @State private var gestureStartAnchor: CGPoint = .zero
    @State private var isPinching = false

    
    var body: some View {
        
        GeometryReader { geometry in
            
            let viewport = geometry.size
            
            let baseWidth = viewport.width
            let baseHeight = baseWidth * image.size.height / image.size.width
            let canvasSize = CGSize(width: baseWidth, height: baseHeight)
            let imageSize = CGSize(width: baseWidth, height: baseHeight)
            
            ZStack(alignment: .topLeading) {
                AppBackground()
                
                ZStack(alignment: .topLeading) {
                    
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: imageSize.width, height: imageSize.height)
                    
                    ForEach(items) { item in
                        OCRTextOverlay(
                            item: item,
                            imageSize: image.size,
                            containerSize: imageSize,
                            verticalOffset: (1 - item.boundingBox.midY) * translator.spacing
                        )
                    }
                }
                .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
                .scaleEffect(zoomScale, anchor: .topLeading)
                .offset(panOffset)
            }
            .frame(width: viewport.width, height: viewport.height)
            .contentShape(Rectangle())
            .clipped()
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
                            viewportSize: viewport
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
                                x: value.startAnchor.x * viewport.width,
                                y: value.startAnchor.y * viewport.height
                            )
                        }
                        
                        let newZoom = min(max(gestureStartZoom * value.magnification, 0.5), 4)
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
                            viewportSize: viewport
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
                    zoomScale = 1
                    panOffset = .zero
                    gestureStartZoom = 1
                    gestureStartOffset = .zero
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func constrainedOffset(_ offset: CGSize, zoomScale: CGFloat, canvasSize: CGSize, viewportSize: CGSize) -> CGSize {
        
        let scaledWidth = canvasSize.width * zoomScale

        let x: CGFloat = scaledWidth <= viewportSize.width
        ? (viewportSize.width - scaledWidth) / 2
        : min(max(offset.width, viewportSize.width - scaledWidth), 0)
        
        let y: CGFloat = min(offset.height, 0)

        return CGSize(width: x, height: y)
    }
}

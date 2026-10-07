//
//  OCRTextOverlay.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/07.
//
import SwiftUI


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


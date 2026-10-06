//
//  OCRImageView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/06.
//
import SwiftUI


struct OCRImageView: View {
    @Environment(TranslatorModel.self) private var translator
    
    let fontScale: Double
    
    var body: some View {
        if let image = translator.selectedImage {
            GeometryReader { geometry in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    ForEach(translator.ocrTextItems) { item in
                        OCRTextOverlay(
                            item: item,
                            text: translator.translatedText[item.id] ?? item.text,
                            imageSize: image.size,
                            containerSize: geometry.size,
                            fontScale: fontScale
                        )
                    }
                }
            }
            .aspectRatio(image.size.width / image.size.height, contentMode: .fit)
        }
    }
}

struct OCRTextOverlay: View {
    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize
    let fontScale: Double
    
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
        max(boxHeight * 0.72 * fontScale, 8)
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



/*

struct OCRTextOverlay1: View {
    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize
    let fontSize: Double
    
    var body: some View {
        OCRTextOverlayContent(
            item: item,
            text: text,
            imageSize: imageSize,
            containerSize: containerSize,
            fontSize: fontSize
        )
    }
}

struct OCRTextOverlayContent: View {
    
    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize
    let fontSize: Double
    
    private var geometry: OCROverlayGeometry {
        OCROverlayGeometry(item: item, imageSize: imageSize, fontSize: fontSize)
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: geometry.fontSize, weight: .regular))
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .foregroundStyle(.primary)
            .frame(width: geometry.width, height: geometry.height)
            .background {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.background.opacity(0.92))
            }
            .position(x: geometry.x, y: geometry.y)
    }
}
struct OCROverlayGeometry {
    
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    
    init(item: OCRTextItem, imageSize: CGSize, containerSize: CGSize) {
        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let displayedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        let offsetX = (containerSize.width - displayedSize.width) / 2
        let offsetY = (containerSize.height - displayedSize.height) / 2
        let box = item.boundingBox
        
        let originalWidth = box.width * displayedSize.width
        let originalHeight = box.height * displayedSize.height
        
        width = originalWidth + 8
        height = originalHeight + 4
        x = offsetX + box.midX * displayedSize.width
        y = offsetY + (1 - box.midY) * displayedSize.height
        fontSize = max(originalHeight * 0.72, 8)
    }
    
}




// display the translated text
struct OCRTextOverlay1: View {

    let item: OCRTextItem
    let text: String
    let imageSize: CGSize
    let containerSize: CGSize

    var body: some View {
        let scale = min(
            containerSize.width / imageSize.width,
            containerSize.height / imageSize.height
        )

        let displayedSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        let offsetX = (containerSize.width - displayedSize.width) / 2
        let offsetY = (containerSize.height - displayedSize.height) / 2
        
        let box = item.boundingBox

        Text(text)
            .font(.system(size: max(box.height * displayedSize.height * 0.7, 8)))
            .foregroundStyle(.black)
            .padding(.horizontal, 2)
            .background(.white)
            .position(
                x: offsetX + box.midX * displayedSize.width,
                y: offsetY + (1 - box.midY) * displayedSize.height
            )
        
        Rectangle()
            .stroke(.red, lineWidth: 2)
            .frame(width: box.width * displayedSize.width, height: box.height * displayedSize.height)
            .position(
                x: offsetX + box.midX * displayedSize.width,
                y: offsetY + (1 - box.midY) * displayedSize.height
            )
        
    }

}


*/

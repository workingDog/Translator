//
//  Utility.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI



struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    var uimage: UIImage
    
    var imgData: Data? {
        let resized = uimage.resizedToFitWidth(1280)
        return resized.jpegData(compressionQuality: 0.9)
    }
}

extension String {
    
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}

extension UIImage {
    
    func resizedToFitWidth(_ targetWidth: CGFloat) -> UIImage {
        let scale = targetWidth / self.size.width
        let newHeight = self.size.height * scale
        let newSize = CGSize(width: targetWidth, height: newHeight)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
            case .up: .up
            case .down: .down
            case .left: .left
            case .right: .right
            case .upMirrored: .upMirrored
            case .downMirrored: .downMirrored
            case .leftMirrored: .leftMirrored
            case .rightMirrored: .rightMirrored
            @unknown default: .up
        }
    }
    
    func resizedToMaximumDimension1(_ maximumDimension: CGFloat) -> UIImage {
        let longestDimension = max(size.width, size.height)
        guard longestDimension > maximumDimension else { return self }
        
        let scale = maximumDimension / longestDimension
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    func resizedToMaximumDimension(_ maximumDimension: CGFloat) -> UIImage {
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longestDimension = max(pixelWidth, pixelHeight)
        
        guard longestDimension > maximumDimension else { return self }
        
        let factor = maximumDimension / longestDimension
        let newSize = CGSize(width: size.width * factor, height: size.height * factor)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    
}

extension Array where Element == OCRTextItem {
    
    func reconstructedText() -> String {
        let sorted = sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.02 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }
        var lines: [[OCRTextItem]] = []
        for item in sorted {
            if let index = lines.firstIndex(where: {
                abs($0[0].boundingBox.midY - item.boundingBox.midY) < 0.025
            }) {
                lines[index].append(item)
            } else {
                lines.append([item])
            }
        }
        return lines.map { line in
            line.sorted { $0.boundingBox.minX < $1.boundingBox.minX }
                .map(\.text)
                .joined(separator: " ")
        }.joined(separator: "\n")
    }
    
}

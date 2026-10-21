//
//  Utility.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import Foundation
import SwiftUI
import Vision
import CoreImage
import UIKit
import CoreGraphics
import CoreImage.CIFilterBuiltins


extension String {
    
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // The katakana block is primarily U+30A0...U+30FF
    var containsKatakana: Bool {
        unicodeScalars.contains { (0x30A0...0x30FF).contains($0.value) }
    }
    
    var katakanaWords: [String] {
        let pattern = "[\\u{30A0}-\\u{30FF}]+"
        guard let regex = try? Regex(pattern) else { return [] }
        return matches(of: regex).map { String(describing: $0) }
    }
    
    /*
     var katakanaWords: [String] {
         let pattern = "[ァ-ヿー]+"
         guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
         let range = NSRange(startIndex..., in: self)
         return regex.matches(in: self, range: range).compactMap {
             Range($0.range, in: self).map { String(self[$0]) }
         }
     }
     */
    
}

extension UIImage {
    
    // a blank image of the given size
    convenience init(size: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        self.init(cgImage: image.cgImage!)
    }
    
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

    func rotated(by degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size

        let renderer = UIGraphicsImageRenderer(size: rotatedSize)

        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            cgContext.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
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
                .map(\.jaText)
                .joined(separator: " ")
        }.joined(separator: "\n")
    }
    
}

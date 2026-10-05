//
//  Utility.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//
import SwiftUI
import PhotosUI
import Translation
import UIKit



extension String {
    func trimLowercased() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
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
  
}

enum NavRoute: Hashable {
    case japanese
    case english
}

enum PhotoError: LocalizedError {
    case invalidData
    
    var errorDescription: String? {
        "The selected photo could not be loaded."
    }
}

struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    var uimage: UIImage
    
    var imgData: Data? {
        let resized = uimage.resizedToFitWidth(1280)
        return resized.jpegData(compressionQuality: 0.9)
    }
}


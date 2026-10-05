//
//  CameraView.swift
//  Translator
//
//  Created by Ringo Wathelet on 2026/10/05.
//

import Foundation
import SwiftUI
import PhotosUI


struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedImages: [ImageItem]
    @Binding var cameraCancel: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            selectedImages: $selectedImages,
            cameraCancel: $cameraCancel,
            dismiss: dismiss
        )
    }

}

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var selectedImages: [ImageItem]
    @Binding var cameraCancel: Bool
    var dismiss: DismissAction

    init(selectedImages: Binding<[ImageItem]>,
         cameraCancel: Binding<Bool>,
         dismiss: DismissAction) {
        
        self._selectedImages = selectedImages
        self._cameraCancel = cameraCancel
        self.dismiss = dismiss
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.selectedImages = [ImageItem(uimage: selectedImage)]
        self.dismiss()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.cameraCancel = true
        self.dismiss()
    }
    
}


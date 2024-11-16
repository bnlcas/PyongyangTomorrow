//
//  PhotoPickerView.swift
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/10/24.
//
import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedItemProvider: NSItemProvider?
    @Binding var selectedAsset: PHAsset?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        
        configuration.selectionLimit = 1 // Only one photo to be selected at a time
        configuration.filter = .images // Only allow images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func requestPhotoLibraryAccessIfNeeded(completion: @escaping (Bool) -> Void) {
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .notDetermined:
                // Request access
                PHPhotoLibrary.requestAuthorization { newStatus in
                    DispatchQueue.main.async {
                        completion(newStatus == .authorized || newStatus == .limited)
                    }
                }
            case .authorized, .limited:
                // Permission already granted
                completion(true)
            default:
                // Permission denied or restricted
                completion(false)
            }
        }


        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            
            picker.dismiss(animated: true, completion: nil)
            
            self.requestPhotoLibraryAccessIfNeeded { granted in
                guard granted else {
                    print("Photo library access denied.")
                    return
                }
            }

            let status = PHPhotoLibrary.authorizationStatus()
            print("status", status)
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) != .authorized {
                print("not authorized")
                
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized || newStatus == .limited {
                        // Now the user has granted permission, proceed as above
                    } else {
                        print("Access denied by user.")
                    }
                }
                
            }
            if PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                print("limited")
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: picker)
            }
                
            if let provider = results.first?.itemProvider {
                self.parent.selectedItemProvider = provider
                print("provider", provider)

            }
            
            if let assetId = results.first?.assetIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                if fetchResult.count == 0 {
                    print("Asset not found or accessible.")
                } else if let asset = fetchResult.firstObject {
                    self.parent.selectedAsset = asset
                    print("asset", asset)
                }
            } else {
                print("Asset identifier is nil.")
            }
        }
    }
}

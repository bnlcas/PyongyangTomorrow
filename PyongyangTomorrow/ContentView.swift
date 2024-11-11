//
//  ContentView.swift
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/10/24.
//

import SwiftUI
import Photos
import ImageIO
import CoreLocation

struct ContentView: View{
    @State private var selectedItemProvider: NSItemProvider?
    @State private var showPicker = false
    @State private var image: UIImage?
    
    @State private var photoSelected = false
    
    @State private var isDatePickerSheetPresented = false
    @State private var selectedTimestamp = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

    @AppStorage("selectedLocation") private var savedLocation: String = Location.pyongyang.rawValue
    @State private var selectedLocation : Location = .pyongyang
    
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func getLatLong(_ selectedLocation : Location) -> (latitude: Double, longitude: Double) {
        switch selectedLocation {
        case .northPole:
            return (latitude: 90.0, longitude: 135.0) // Approximate coordinates for the North Pole
        case .pyongyang:
            return (latitude: 39.0392, longitude: 125.7625) // Coordinates for Pyongyang, North Korea
        case .whiteHouse:
            return (latitude: 38.8977, longitude: -77.0365) // Coordinates for the White House, Washington, D.C.
        case .antarctica:
            return (latitude: -77.8419, longitude: 166.6863) // Coordinates for McMurdo Station, Antarctica
        }
    }
    
    // Modify EXIF metadata and save the image
    func modifyAndSavePhoto(image: UIImage) {
        let latLong = getLatLong(selectedLocation)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        
        if let imageData = image.jpegData(compressionQuality: 1.0),
           let source = CGImageSourceCreateWithData(imageData as CFData, nil) {
            let UTI = CGImageSourceGetType(source)!
            let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
            var mutableMetadata = metadata

            // Modify location metadata
            mutableMetadata[kCGImagePropertyGPSDictionary] = [
                kCGImagePropertyGPSLatitude: latLong.latitude,
                kCGImagePropertyGPSLatitudeRef: latLong.latitude >= 0 ? "N" : "S",
                kCGImagePropertyGPSLongitude: latLong.longitude,
                kCGImagePropertyGPSLongitudeRef: latLong.longitude >= 0 ? "E" : "W",
                kCGImagePropertyGPSAltitudeRef: -100,
                kCGImagePropertyGPSTimeStamp: tomorrow
            ]

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            let formattedDate = formatter.string(from: tomorrow)

            mutableMetadata[kCGImagePropertyExifDictionary] = [
                kCGImagePropertyExifDateTimeOriginal: formattedDate,
                kCGImagePropertyExifDateTimeDigitized: formattedDate,
                kCGImagePropertyExifSubsecTimeOriginal: "0",
                kCGImagePropertyExifSubsecTimeDigitized: "0"
            ]

            mutableMetadata[kCGImagePropertyTIFFDictionary] = [
                kCGImagePropertyTIFFDateTime: formattedDate
            ]
            
            guard let mutableData = CFDataCreateMutable(nil, 0),
                  let destination = CGImageDestinationCreateWithData(mutableData, UTI, 1, nil) else {
                return
            }

            CGImageDestinationAddImageFromSource(destination, source, 0, mutableMetadata as CFDictionary)

            if CGImageDestinationFinalize(destination) {
                let modifiedImageData = mutableData as Data

                // Save to Photos Library
                saveModifiedImage(modifiedImageData)
            }
        }
    }

    func saveModifiedImage(_ imageData: Data) {
        PHPhotoLibrary.shared().performChanges({
            let options = PHAssetResourceCreationOptions()
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: imageData, options: options)
        }) { success, error in
            if success {
                //deleteOriginalPhoto(asset: originalAsset)
                print("Modified image saved successfully.")
            } else if let error = error {
                print("Error saving modified image: \(error)")
            }
        }
    }
    
    func deleteOriginalPhoto(asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSArray)
        }) { success, error in
            if success {
                print("Original photo deleted successfully.")
                
            } else if let error = error {
                print("Error deleting original photo: \(error)")
            }
        }
    }

    var body: some View {
        if(!photoSelected){
            VStack{
                Text("Pyongyang Tomorrow")
                Text("내일 평양")
                Spacer()
            }
        }

        VStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            }
            Spacer()
            if(!photoSelected){
                Button(action: {
                    showPicker = true
                }){
                    Text("🇰🇵 Select Photo  🇰🇵")
                }
                .padding()
            } else
            {
                VStack{
                    LocationPickerView(selectedLocation: $selectedLocation)
                    HStack{
                        Text("Date:")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Button(action: {
                            isDatePickerSheetPresented = true
                        }){
                            Text("\(formattedDate(selectedTimestamp))")
                                .padding()
                        }
                    }
                    .sheet(isPresented: $isDatePickerSheetPresented ) {
                        FutureDatePickerView(selectedDate: $selectedTimestamp)
                            .presentationDetents([.fraction(0.3), .medium]) // Cover 30% of screen or use medium height
                            .presentationDragIndicator(.visible) // Adds a drag indicator to the sheet
                    }
                    HStack{
                        Button(action: {
                            showPicker = true
                        }){
                            Text("🖼️ Select Photo")
                        }
                        Button("💾 Save Changes") {
                            if let image = image {
                                modifyAndSavePhoto(image: image)
                            }
                        }
                        .disabled(image == nil)
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            PhotoPickerView(selectedItemProvider: $selectedItemProvider)
        }
        .onChange(of: selectedItemProvider) {
            if let provider = $0, provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.image = object as? UIImage
                        withAnimation(.easeInOut(duration: 0.5)) {
                            photoSelected = (self.image != nil)
                        }
                    }
                }
            }
        }
        .onAppear {
            if let loadedLocation = Location(rawValue: savedLocation) {
                selectedLocation = loadedLocation
            }
        }
        .onChange(of: selectedLocation) {
            savedLocation = $0.rawValue
        }
    }
}
    
    /*
            Button(action: {
                print("future")
                showPicker = true
            }){
                ZStack{

                    RoundedRectangle(cornerSize: CGSize(width: 20.0, height: 20.0))
                        .frame(width: 300, height:150)
                        //.background(Color.red)
                        .foregroundColor(Color.red)
                    
                    VStack{
                        Text("Pyongyang Tomorrow")
                        Text("내일 평양")
                    }


                }
            }

        }
        .padding()
    }
}*/

#Preview {
    ContentView()
}

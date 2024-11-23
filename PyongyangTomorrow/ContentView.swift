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
    @State private var originalAsset : PHAsset?
    
    @State private var showPicker = false
    @State private var image: UIImage?
    
    @State private var photoSelected = false
    
    @State private var deleteOriginal = false
    
    @State var fadeInterval = 0.0
    
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
        case .ciaHQ:
            return (latitude: 38.950887, longitude: -77.147589) // George Bush Center for intelligence
        case .antarctica:
            return (latitude: -77.8419, longitude: 166.6863) // Coordinates for McMurdo Station, Antarctica
        case .area51:
            return (latitude: 37.238629,  longitude: -115.813694)//area 51
        }
    }
    
    // Modify EXIF metadata and save the image
    func modifyAndSavePhoto(image: UIImage) {
        withAnimation(.easeInOut(duration: 2.2)){
            fadeInterval = 1.0
        }
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
                if(deleteOriginal){
                    if let asset = originalAsset {
                        deleteOriginalPhoto(asset: asset)
                    }
                }
                withAnimation(.easeInOut(duration: 0.5)){
                    fadeInterval = 1.0
                }
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
        VStack {
            /*Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 200))
                .colorEffect(ShaderLibrary.burnTransition(.float(0.8)))*/
            if let image = image {
                ZStack{
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .visualEffect { content, proxy in
                            content
                                .colorEffect(ShaderLibrary.burnTransition(
                                    .float(fadeInterval),
                                    .float2(proxy.size)
                                ))
                        }
                    Button(action: {
                        showPicker = true
                    }){
                        VStack{
                            Text("Sent to Future!")
                            Text("🇰🇵 Select New Photo 🇰🇵")
                        }
                        .opacity(fadeInterval)
                    }
                }
            }
            if(!photoSelected){
                Button(action: {
                    showPicker = true
                }){
                    VStack{
                        Text("Pyongyang Tomorrow")
                        Text("내일 평양")
                        Text("🇰🇵 Select Photo 🇰🇵")
                    }
                }
                .padding()
            } else
            {
                VStack{
                    HStack{
                        Text("Delete Original:")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Toggle(isOn: $deleteOriginal){
                            EmptyView()
                        }
                        .tint(.red)
                        .padding()
                    }
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
                            .presentationDetents([.fraction(0.45), .medium])
                            .presentationDragIndicator(.visible)
                    }
                    HStack{
                        Button(action: {
                            showPicker = true
                        }){
                            Text("🖼️ New Photo")
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
            PhotoPickerView(selectedItemProvider: $selectedItemProvider, selectedAsset: $originalAsset)
        }
        .onChange(of: selectedItemProvider) {
            if let provider = $0, provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { object, error in
                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        fadeInterval = 0.0
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

#Preview {
    ContentView()
}

//
//  LocationPickerView.swift
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/10/24.
//

import SwiftUI

enum Location: String, CaseIterable, Identifiable {
    case pyongyang = "🇰🇵Pyongyang"
    case whiteHouse = "🏛️White House"
    case northPole = "⛄North Pole"
    case antarctica = "🐧Antarctica"

    var id: String { self.rawValue }
}

struct LocationPickerView: View {
    // Options for the picker
    //let locations = ["🇰🇵Pyongyang", "⛄North Pole", "🏛️White House", "🐧Antarctica"]

    // State variable to track the selected option
    @Binding var selectedLocation: Location

    var body: some View {
        HStack {
            Text("Location:")
                .font(.headline)
                .padding()
            Spacer()
            Picker("Location", selection: $selectedLocation) {
                ForEach(Location.allCases) { location in
                    Text(location.rawValue).tag(location)
                }
            }
            .pickerStyle(MenuPickerStyle()) // Dropdown style picker
            .padding()
        }
    }
}

#Preview {
    LocationPickerView(selectedLocation: .constant(.pyongyang))
}

//
//  FutureDatePickerView.swift
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/10/24.
//

import SwiftUI

struct FutureDatePickerView: View {
    @Binding var selectedDate : Date
    //= Calendar.current.date(byAdding: .day, value: 1, to: Date())!

     var body: some View {
         VStack {
             Text("Select a Future Date")
                 .font(.headline)
                 .padding()

             DatePicker(
                 "Date",
                 selection: $selectedDate,
                 in: Date()..., // Restrict selection to dates in the future
                 displayedComponents: [.date, .hourAndMinute]
             )
             .datePickerStyle(WheelDatePickerStyle())
             //(GraphicalDatePickerStyle())
             .padding()
             Text("You selected: \(formattedDate(selectedDate))")
                 .padding()
         }
     }

     private func formattedDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateStyle = .medium
         formatter.timeStyle = .short
         return formatter.string(from: date)
     }
}

#Preview {
    FutureDatePickerView(selectedDate: .constant(Calendar.current.date(byAdding: .day, value: 1, to: Date())!))
}

//
//  TestView.swift
//  PyongyangTomorrow
//
//  Created by Benjamin Lucas on 11/22/24.
//

import SwiftUI

struct TestView: View {
    @State var fadeInterval = 0.5
    let startDate = Date()
    //
    var body: some View {
            Rectangle()
                .fill(.gray)
                .frame(width:400, height:300)
                .visualEffect { content, proxy in
                    content
                        .colorEffect(ShaderLibrary.burnTransition(
                            .float(fadeInterval),
                            .float2(proxy.size)
                        ))
                }
                .onTapGesture  {
                    fadeInterval = 0.0
                    withAnimation(.linear(duration: 2.2)){
                        fadeInterval = 1.0
                    }
                }
            //.colorEffect(ShaderLibrary.burnTransition(.float(0.7)))
    }
}

#Preview {
    TestView()
}

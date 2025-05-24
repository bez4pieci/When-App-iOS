//
//  NoStationView.swift
//  Departures
//
//  Created on 24.05.25.
//

import SwiftUI

struct NoStationView: View {
    let onSelectStation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("No Station Selected")
                .foregroundColor(.white)
            
            Button(action: onSelectStation) {
                Text("SELECT STATION")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
            .padding(.top, 20)
        }
        .frame(maxHeight: .infinity)
    }
} 
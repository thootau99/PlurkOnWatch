//
//  ContentView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/4.
//

import SwiftUI

struct NotLoginView: View {
    @EnvironmentObject var connector : PlurkConnectorWatch
    var body: some View {
        VStack {
            Text("Not login yet")
                .padding()
        }
    }
}

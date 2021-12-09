//
//  PlurkDetailView.swift
//  PlurkOnWatch
//
//  Created by Burke Khoo on 2021/12/7.
//

import SwiftUI

struct ResponseView : View {
    @EnvironmentObject var plurk: PlurkConnectorWatch
    var post : Response
    var body: some View {
        Button(action: {}) {
            VStack {
                Text(post.display_name ?? "")
                Text(post.content ?? "")
            }
            
        }
    }
}

struct PlurkDetailView: View {
    @EnvironmentObject var plurk: PlurkConnectorWatch
    
    
    var plurk_id: Int
    var body: some View {
        ScrollView {
            VStack {
                ForEach(self.plurk.plurk_response.responses, id: \.self) { _plurk in
                    ResponseView(post: _plurk)
                        .environmentObject(self.plurk)
                        .padding()
                }
            }
        }
            .onAppear(perform: {() in
                getPlurks()
            })
    }
    private func getPlurks() {
        self.plurk.getPlurkResponses(plurk_id: self.plurk_id)
    }
}

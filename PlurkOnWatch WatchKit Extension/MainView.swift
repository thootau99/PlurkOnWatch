//
//  MainView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/5.
//

import SwiftUI
import SwiftSoup


struct PlurkPostView : View {
    @EnvironmentObject var plurk: PlurkConnector
    var post : PlurkPost
    var body: some View {
        NavigationLink(destination: {
            PlurkDetailView(plurk_id: post.plurk_id ?? 0).environmentObject(plurk) }) {
            VStack {
                Text(post.display_name ?? "")
                Text(post.content ?? "")
            }
            
        }
        .overlay(Text(String(post.response_count!)).offset(x: 0, y: -10), alignment: Alignment.topTrailing)
    }
}

struct MainView: View {
    @EnvironmentObject var connector : PhoneConnector
    @EnvironmentObject var plurk: PlurkConnector
    
    private func tokenInsert() {
        if (plurk._OAuthSwift.client.credential.oauthToken.isEmpty || plurk._OAuthSwift.client.credential.oauthTokenSecret.isEmpty) {
            plurk.login(token: connector.oauthToken, tokenSecret: connector.oauthTokenSecret)
            //plurk.login(token: "yk0faWMkZiGV", tokenSecret: "WB8HU9oZ6oYAJwz49mXXMpGpPJKkOxcn")
        }
        
        plurk.getPlurks()
    }
    
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    NavigationLink {
                        MyProfileView()
                            .environmentObject(plurk)
                    } label: {
                        HStack {
                            Text("me")
                        }
                    }
                    Button("Only my plurk") {
                        plurk.getMyPlurks()
                    }
                    Button("All plurk") {
                        plurk.getPlurks()
                    }
                    Button("Logout") {
                        plurk.logout()
                        connector.cleanOauthToken()
                    }
                }
                ForEach(self.plurk.plurks.plurks, id: \.self) { _plurk in
                    PlurkPostView(post: _plurk)
                        .environmentObject(self.plurk)
                        .padding()
                }
            }
        }
        .navigationTitle("My Plurks")
        .onAppear(perform: { self.tokenInsert() })
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

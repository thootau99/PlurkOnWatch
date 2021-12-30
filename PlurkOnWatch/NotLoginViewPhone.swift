//
//  ContentView.swift
//  PlurkOnWatch
//
//  Created by Burke Khoo on 2021/12/4.
//

import SwiftUI

struct NotLoginView: View {
    
    @ObservedObject var connector = WatchConnector()
    @EnvironmentObject var plurk: PlurkConnector
    var body: some View {
        VStack {
            HStack {
                Text("Login Status: \(String(self.plurk.loginSuccess))")
                Button("login") {
                    Task {
                        self.plurk.login() {
                            var tokens : Array<Message> = []
                            let token: Message = Message(key: "oauthToken", value: "\(self.plurk._OAuthSwift.client.credential.oauthToken),\(self.plurk._OAuthSwift.client.credential.oauthTokenSecret)")
                            tokens.append(token)
                            self.connector.send(messages: tokens)
                        }
                    }
                }
            }
            Text("\(self.connector.receivedMessage)")
                .padding()
        }
        
    }
}

struct NotLoginView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

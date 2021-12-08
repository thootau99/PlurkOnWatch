//
//  ContentView.swift
//  PlurkOnWatch
//
//  Created by Burke Khoo on 2021/12/4.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var connector = WatchConnector()
    @EnvironmentObject var plurk: PlurkConnector_Phone
    var body: some View {
        VStack {
            HStack {
                Text("Login Status: \(String(self.plurk.loginSuccess))")
                Button("login") {
                    Task {
                        try await self.plurk.login() {
                            var tokens : Array<Message> = []
                            let token: Message = Message(key: "oauthToken", value: "\(self.plurk._OAuthSwift.client.credential.oauthToken),\(self.plurk._OAuthSwift.client.credential.oauthTokenSecret)")
                            tokens.append(token)
                            print(tokens)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

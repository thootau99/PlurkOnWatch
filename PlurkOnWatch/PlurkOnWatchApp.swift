//
//  PlurkOnWatchApp.swift
//  PlurkOnWatch
//
//  Created by Burke Khoo on 2021/12/4.
//

import SwiftUI
import OAuthSwift
@main
struct PlurkOnWatchApp: App {
    @ObservedObject var plurk = PlurkConnector()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(plurk)
                .onOpenURL(perform: {url in
                    OAuthSwift.handle(url: url)
                })
        }
    }
}

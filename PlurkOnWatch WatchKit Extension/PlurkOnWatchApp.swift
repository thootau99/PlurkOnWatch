//
//  PlurkOnWatchApp.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/4.
//

import SwiftUI

@main
struct PlurkOnWatchApp: App {
    @StateObject var plurk : PlurkConnector = PlurkConnector()
    @StateObject var connector : PhoneConnector = PhoneConnector()
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                if connector.oauthToken.isEmpty && connector.oauthTokenSecret.isEmpty  {
                    NotLoginView()
                        .environmentObject(connector)
                        .environmentObject(plurk)
                } else {
                    MainView()
                        .environmentObject(connector)
                        .environmentObject(plurk)
                }
                
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

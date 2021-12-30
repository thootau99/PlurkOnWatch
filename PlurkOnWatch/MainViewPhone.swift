//
//  MainViewPhone.swift
//  PlurkOnWatch
//
//  Created by Burke Khoo on 2021/12/16.
//

import SwiftUI

struct MainViewPhone : View {
    @ObservedObject var connector = WatchConnector()
    @EnvironmentObject var plurk: PlurkConnector
    var body: some View {
        TabView{
            NotLoginView().tabItem {
                NavigationLink(destination:
                                NotLoginView()
                                .environmentObject(connector)
                                .environmentObject(plurk)
                ) {
                    Text("Login") }.tag(1)
            }
        }
    }
}

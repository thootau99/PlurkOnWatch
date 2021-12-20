//
//  MainView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/5.
//

import SwiftUI
import SwiftSoup

struct PlurkPostView : View {
    @EnvironmentObject var plurk: PlurkConnectorWatch
    var post : PlurkPost
    let columns = Array(repeating: GridItem(), count: 2)
    @State private var imageURL: String?
    var body: some View {
        NavigationLink(destination: {
            PlurkDetailView(plurk_id: post.plurk_id ?? 0).environmentObject(plurk) }) {
            VStack {
                Text(post.display_name ?? "")
                Text(post.content ?? "")
                LazyVGrid(columns: columns) {
                    ForEach(post.photos, id: \.self) { photo in
                        AsyncImage(url: URL(string: photo)) {phase in
                            switch phase {
                            case .empty:
                                Color.purple.opacity(0.1)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                
                            case .failure(_):
                                Image(systemName: "exclamationmark.icloud")
                                    .resizable()
                                    .scaledToFit()
                                    .aspectRatio(0.90, contentMode: .fill)
                            @unknown default:
                                Image(systemName: "exclamationmark.icloud")
                            }
                        }
                            .frame(width: 36)
                    }
                }
                .padding()
            }
            .frame(alignment: .top)
        }
    }
    
}

struct MainView: View {
    @EnvironmentObject var connector : PhoneConnector
    @EnvironmentObject var plurk: PlurkConnectorWatch
    @State var plurks: GetPlurkResponse = GetPlurkResponse(plurks: [], plurk_users: [:])
    @State var onlyme: Bool = false

    private func tokenInsert() async {
        if (plurk._OAuthSwift.client.credential.oauthToken.isEmpty || plurk._OAuthSwift.client.credential.oauthTokenSecret.isEmpty) {
            plurk.login(token: connector.oauthToken, tokenSecret: connector.oauthTokenSecret)
        }
        
        plurk.getPlurks(me: false).done {_plurks in
            self.plurks = _plurks
        }
    }
    
    var body: some View {
        List {
            NavigationLink {
                MyProfileView()
                    .environmentObject(plurk)
            } label: {
                HStack {
                    Text("me")
                }
            }
            Button("Only my plurk") {
                onlyme = true
                self.plurks = GetPlurkResponse(plurks: [], plurk_users: [:])
                plurk.getPlurks(me: onlyme).done {_plurks in
                    self.plurks = _plurks
                }
            }
            Button("All plurk") {
                onlyme = false
                self.plurks = GetPlurkResponse(plurks: [], plurk_users: [:])
                plurk.getPlurks(me: onlyme).done {_plurks in
                    self.plurks = _plurks
                }
            }
            Button("Logout") {
                plurk.logout()
                connector.cleanOauthToken()
            }
            ForEach(self.plurks.plurks, id: \.self) { _plurk in
                PlurkPostView(post: _plurk)
                    .environmentObject(self.plurk)
                    .padding()
                    .overlay(Text(String(_plurk.response_count!)).offset(x: 0, y: -10), alignment: Alignment.topTrailing)
            }
            
            
            VStack {
                Button("Get more plurk") {
                    plurk.getPlurks(me: onlyme).done {_plurks in
                        self.plurks = _plurks
                    }
                }
            }.onAppear(perform: { plurk.getPlurks(me: onlyme).done {_plurks in
                self.plurks = _plurks
            } })
        }
        .navigationTitle("My Plurks")
        
        .onAppear {
            Task.init {
                await self.tokenInsert()
            }
        }
        .onPreferenceChange(ViewOffsetKey.self) { print("offset >> \($0)") }
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

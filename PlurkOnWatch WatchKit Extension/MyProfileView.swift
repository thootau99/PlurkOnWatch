//
//  MyProfileView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/5.
//

import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var plurk: PlurkConnectorWatch
    @State var me : ProfileResponse = ProfileResponse(fans_count: 0, friends_count: 0, user_info: Profile())
    var body: some View {
        HStack {
            VStack {
                Text(self.me.user_info.display_name ?? "")
                    .font(.title2)
                Text(self.me.user_info.nick_name ?? "")
                    .font(.title3)
                Text(self.me.user_info.about ?? "")
                    .font(.body)
            }
        }
        .onAppear {
            plurk.getMyProfile().done { profile in
                self.me = profile
            }
        }
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}

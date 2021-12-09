//
//  MyProfileView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/5.
//

import SwiftUI

struct MyProfileView: View {
    @EnvironmentObject var plurk: PlurkConnectorWatch
    
    var body: some View {
        HStack {
            VStack {
                Text(self.plurk.me.user_info.display_name ?? "")
                    .font(.title2)
                Text(self.plurk.me.user_info.nick_name ?? "")
                    .font(.title3)
                Text(self.plurk.me.user_info.about ?? "")
                    .font(.body)
            }
        }
        .onAppear(perform: { plurk.getMyProfile() })
    }
}

struct MyProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MyProfileView()
    }
}

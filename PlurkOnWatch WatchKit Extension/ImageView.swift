//
//  ImageView.swift
//  PlurkOnWatch WatchKit Extension
//
//  Created by Burke Khoo on 2021/12/16.
//

import SwiftUI

struct ImageView: View {
    var imageURL: String?
    var body: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) {phase in
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
            
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        ImageView(imageURL: "https://i.imgflip.com/3pnet2.png")
    }
}

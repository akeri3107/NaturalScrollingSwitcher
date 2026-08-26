//
//  CreditsView.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import SwiftUI

struct CreditsView: View {

    var body: some View {
        VStack(spacing: 12) {

            Text("Natural Scrolling Switcher")
                .font(.title2)
                .fontWeight(.semibold)

            Text("A macOS utility that automatically switches Natural Scrolling depending on the connected input device.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("Created by Akeri")
                .font(.body)

            Button("Close") {
                NSApplication.shared.keyWindow?.close()
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

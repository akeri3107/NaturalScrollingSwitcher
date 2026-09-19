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

            Text(L10n.appName)
                .font(.title2)
                .fontWeight(.semibold)

            Text(L10n.aboutDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text(L10n.aboutCreator)
                .font(.body)

            Button(L10n.buttonClose) {
                NSApplication.shared.keyWindow?.close()
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

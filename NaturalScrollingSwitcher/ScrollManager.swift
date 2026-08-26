//
//  ScrollManager.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import Darwin

final class ScrollManager {

    private let frameworkPath =
        "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/Versions/A/PreferencePanesSupport"

    func setNaturalScrolling(_ enabled: Bool) {

        guard let framework = dlopen(
            frameworkPath,
            RTLD_NOW
        ) else {
            print("Failed to load PreferencePanesSupport.framework")
            return
        }

        defer {
            dlclose(framework)
        }

        typealias SetSwipeScrollDirection = @convention(c) (Bool) -> Void

        guard let symbol = dlsym(
            framework,
            "setSwipeScrollDirection"
        ) else {
            print("Failed to find setSwipeScrollDirection")
            return
        }

        let setSwipeScrollDirection =
            unsafeBitCast(
                symbol,
                to: SetSwipeScrollDirection.self
            )

        setSwipeScrollDirection(enabled)

        print("Natural Scrolling → \(enabled ? "ON" : "OFF")")
    }
}

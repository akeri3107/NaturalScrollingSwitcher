//
//  MenuBarIcon.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import AppKit

let menuBarIcon: NSImage = {
    let size = NSSize(width: 32, height: 18)

    let image = NSImage(size: size)
    image.lockFocus()

    let arrowConfig = NSImage.SymbolConfiguration(
        pointSize: 7,
        weight: .bold
    )

    let mouseConfig = NSImage.SymbolConfiguration(
        pointSize: 12,
        weight: .medium
    )

    guard
        let upArrow = NSImage(
            systemSymbolName: "arrow.up",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(arrowConfig),

        let mouse = NSImage(
            systemSymbolName: "computermouse",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(mouseConfig),

        let downArrow = NSImage(
            systemSymbolName: "arrow.down",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(arrowConfig)
    else {
        image.unlockFocus()
        return image
    }

    upArrow.draw(
        in: NSRect(x: 0, y: 1, width: 7, height: 16),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    mouse.draw(
        in: NSRect(x: 9, y: 1, width: 12, height: 16),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    downArrow.draw(
        in: NSRect(x: 23, y: 1, width: 7, height: 16),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    image.unlockFocus()

    image.isTemplate = true

    return image
}()

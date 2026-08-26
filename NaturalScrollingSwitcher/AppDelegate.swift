//
//  AppDelegate.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    let monitor = ScrollMonitor()
    let loginItemManager = LoginItemManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }
}

//
//  ScrollMonitor.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import Combine

enum NaturalScrollingMode: Equatable {
    case on
    case off
    case automatic
}

final class ScrollMonitor: ObservableObject {

    private let mouseDetector: MouseDetector
    private let scrollManager: ScrollManager

    private var timer: Timer?
    private var lastMouseState: Bool?

    @Published private(set) var mouseConnected = false
    @Published private(set) var naturalScrollingEnabled = true

    @Published var naturalScrollingMode: NaturalScrollingMode {
        didSet {
            switch naturalScrollingMode {

            case .on:
                UserDefaults.standard.set(
                    "on",
                    forKey: "naturalScrollingMode"
                )

                setNaturalScrolling(true)

            case .off:
                UserDefaults.standard.set(
                    "off",
                    forKey: "naturalScrollingMode"
                )

                setNaturalScrolling(false)

            case .automatic:
                UserDefaults.standard.set(
                    "automatic",
                    forKey: "naturalScrollingMode"
                )

                applyAutomaticModeImmediately()
            }
        }
    }

    init(
        mouseDetector: MouseDetector = MouseDetector(),
        scrollManager: ScrollManager = ScrollManager()
    ) {
        self.mouseDetector = mouseDetector
        self.scrollManager = scrollManager

        let savedMode =
            UserDefaults.standard.string(
                forKey: "naturalScrollingMode"
            ) ?? "automatic"

        switch savedMode {
        case "on":
            self.naturalScrollingMode = .on

        case "off":
            self.naturalScrollingMode = .off

        default:
            self.naturalScrollingMode = .automatic
        }
    }

    func start() {
        print("================================")
        print("NaturalScrollingSwitcher started")
        print("================================")

        checkMouseState()

        timer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.checkMouseState()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        print("NaturalScrollingSwitcher stopped")
    }

    private func checkMouseState() {

        let mouseConnected = mouseDetector.isMouseConnected()

        DispatchQueue.main.async {
            self.mouseConnected = mouseConnected
        }

        // Auto 모드가 아니면 마우스 상태만 표시하고
        // Natural Scrolling은 자동으로 변경하지 않는다.
        guard naturalScrollingMode == .automatic else {
            return
        }

        if lastMouseState == nil || lastMouseState != mouseConnected {

            print("--------------------------------")
            print("Mouse state changed")
            print("Mouse connected: \(mouseConnected)")
            print("--------------------------------")

            let naturalScrolling = !mouseConnected

            scrollManager.setNaturalScrolling(naturalScrolling)

            DispatchQueue.main.async {
                self.naturalScrollingEnabled = naturalScrolling
            }

            lastMouseState = mouseConnected
        }
    }

    func setMode(_ mode: NaturalScrollingMode) {
        naturalScrollingMode = mode
    }

    func setNaturalScrolling(_ enabled: Bool) {

        scrollManager.setNaturalScrolling(enabled)

        DispatchQueue.main.async {
            self.naturalScrollingEnabled = enabled
        }

        print("--------------------------------")
        print("Manual Natural Scrolling change")
        print("Natural Scrolling: \(enabled)")
        print("--------------------------------")
    }

    private func applyAutomaticModeImmediately() {

        let mouseConnected = mouseDetector.isMouseConnected()
        let naturalScrolling = !mouseConnected

        scrollManager.setNaturalScrolling(naturalScrolling)

        DispatchQueue.main.async {
            self.mouseConnected = mouseConnected
            self.naturalScrollingEnabled = naturalScrolling
        }

        lastMouseState = mouseConnected

        print("--------------------------------")
        print("Automatic mode applied")
        print("Mouse connected: \(mouseConnected)")
        print("Natural Scrolling: \(naturalScrolling)")
        print("--------------------------------")
    }
}

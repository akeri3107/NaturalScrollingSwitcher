import SwiftUI

@main
enum NSSApplication {
    @MainActor static func main() {
        if AppRelauncher.runHelperIfRequested() { return }
        // Resolve before AppDelegate constructs the policy store or any UI.
        _ = L10n.language
        NaturalScrollingSwitcherApp.main()
    }
}

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlass() -> some View {
        // TODO: Add .glassEffect(.regular.interactive, in: .capsule) for macOS 26+ when SDK is available
        self
            .background(.ultraThinMaterial, in: Capsule())
    }
}

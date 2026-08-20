import SwiftUI

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

extension View {
    /// Applies native Liquid Glass when available; falls back to ultraThinMaterial otherwise.
    @ViewBuilder
    func leonGlassSurface() -> some View {
        leonGlassSurface(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    func leonGlassSurface<S: Shape>(_ shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }

    @ViewBuilder
    func leonGlassInteractive() -> some View {
        leonGlassInteractive(Capsule())
    }

    @ViewBuilder
    func leonGlassInteractive<S: Shape>(_ shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: shape)
        } else {
            self.background(.ultraThinMaterial, in: shape)
        }
    }
}

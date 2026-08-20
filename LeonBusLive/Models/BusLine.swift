import Foundation
import SwiftUI

/// Urban bus line. Mock data is demonstration-only — not an official ALESA feed.
struct BusLine: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let number: String
    let name: String
    /// Hex RGB without `#`, e.g. `"E53935"`.
    let colorHex: String
    let origin: String
    let destination: String
    let stopIDs: [String]
    /// Approximate headway in minutes when operating.
    let frequencyMinutes: Int
    let isInService: Bool
    /// Marks dataset provenance; always true for the built-in demo provider.
    let isDemoData: Bool

    var displayTitle: String { "Línea \(number)" }

    var routeSummary: String { "\(origin) ↔ \(destination)" }

    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

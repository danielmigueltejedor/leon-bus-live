import Foundation

/// Bus stop. Coordinates are approximate and for demonstration only.
struct BusStop: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let code: String
    let name: String
    let address: String
    let coordinate: Coordinates
    let lineIDs: [String]
    let isDemoData: Bool
}

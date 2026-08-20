import Foundation

enum FavoriteKind: String, Codable, Hashable, Sendable {
    case stop
    case line
}

struct FavoriteItem: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let kind: FavoriteKind
    let referenceID: String
    var alias: String?
    var sortIndex: Int
    var createdAt: Date

    static func stop(_ stopID: String, alias: String? = nil, sortIndex: Int = 0) -> FavoriteItem {
        FavoriteItem(
            id: "stop-\(stopID)",
            kind: .stop,
            referenceID: stopID,
            alias: alias,
            sortIndex: sortIndex,
            createdAt: .now
        )
    }

    static func line(_ lineID: String, sortIndex: Int = 0) -> FavoriteItem {
        FavoriteItem(
            id: "line-\(lineID)",
            kind: .line,
            referenceID: lineID,
            alias: nil,
            sortIndex: sortIndex,
            createdAt: .now
        )
    }
}

enum FavoriteAliasSuggestion: String, CaseIterable, Identifiable, Sendable {
    case casa = "Casa"
    case trabajo = "Trabajo"
    case universidad = "Universidad"
    case centro = "Centro"
    case hospital = "Hospital"

    var id: String { rawValue }
}

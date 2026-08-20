import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .symbolEffect(.bounce, value: isFavorite)
                .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
    }
}

#Preview {
    FavoriteButton(isFavorite: true) {}
}

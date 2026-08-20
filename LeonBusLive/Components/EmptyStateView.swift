import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var message: String? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            if let message {
                Text(message)
            }
        }
    }
}

struct LoadingView: View {
    var message: String = "Cargando…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.08).ignoresSafeArea()
            ProgressView(message)
                .padding(24)
                .leonGlassSurface()
        }
        .accessibilityElement(children: .combine)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(.primary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .leonGlassSurface(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel(message)
    }
}

#Preview("Empty") {
    EmptyStateView(title: "Sin favoritos", systemImage: "star", message: "Guarda paradas o líneas para verlas aquí.")
}

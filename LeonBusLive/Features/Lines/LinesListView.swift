import SwiftUI

struct LinesListView: View {
    @Environment(AppModel.self) private var appModel
    @State private var lines: [BusLine] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                ErrorBanner(message: errorMessage)
                    .listRowBackground(Color.clear)
            }
            ForEach(lines) { line in
                NavigationLink(value: AppRoute.line(line.id)) {
                    HStack(spacing: 14) {
                        LineBadge(line: line)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(line.displayTitle)
                                .font(.headline)
                            Text(line.routeSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(line.isInService ? "En servicio · cada \(line.frequencyMinutes) min" : "Fuera de servicio")
                                .font(.caption)
                                .foregroundStyle(line.isInService ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.orange))
                        }
                        Spacer()
                        if appModel.favoritesStore.isFavorite(lineID: line.id) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .accessibilityLabel("Favorita")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Líneas")
        .task {
            do {
                lines = try await appModel.provider.lines()
                    .sorted { $0.number.localizedStandardCompare($1.number) == .orderedAscending }
            } catch {
                errorMessage = (error as? TransitError)?.errorDescription ?? "No se pudieron cargar las líneas."
            }
        }
    }
}

#Preview {
    NavigationStack {
        LinesListView()
    }
    .environment(AppModel())
}

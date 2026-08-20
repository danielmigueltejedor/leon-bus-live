import SwiftUI

struct RealtimeStatusBadge: View {
    let quality: ArrivalDataQuality

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
            Text(quality.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(quality.title)
    }

    private var indicatorColor: Color {
        switch quality {
        case .realtime: return .green
        case .estimated: return .orange
        case .scheduled: return .secondary
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        RealtimeStatusBadge(quality: .realtime)
        RealtimeStatusBadge(quality: .estimated)
        RealtimeStatusBadge(quality: .scheduled)
    }
    .padding()
}

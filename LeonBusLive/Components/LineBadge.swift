import SwiftUI

struct LineBadge: View {
    let line: BusLine
    var compact: Bool = false

    var body: some View {
        Text(line.number)
            .font(compact ? .caption.weight(.bold) : .subheadline.weight(.bold))
            .foregroundStyle(.white)
            .monospacedDigit()
            .frame(minWidth: compact ? 28 : 34, minHeight: compact ? 28 : 34)
            .padding(.horizontal, compact ? 4 : 6)
            .background(line.color, in: RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous))
            .accessibilityLabel("Línea \(line.number)")
    }
}

#Preview {
    LineBadge(line: LeonDemoCatalog.lines[0])
        .padding()
}

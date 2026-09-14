import SwiftUI

struct MetalPlate<Content: View>: View {
    var emphasized: Bool = false
    var padded: Bool = true
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padded ? 14 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: KerningMath.plateCorner, style: .circular)
                    .stroke(emphasized ? Palette.primary : Palette.accent.opacity(0.38), lineWidth: emphasized ? 1.6 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: KerningMath.plateCorner, style: .circular))
    }
}

struct EmptyPlate: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        MetalPlate {
            VStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Palette.primary)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Palette.primary)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(Palette.accent.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

struct KerningPreview: View {
    let text: String
    let gaps: [String: Double]
    var fontSize: Double = KerningMath.defaultFontSize
    var compact: Bool = false
    var highlightPair: String? = nil
    var markedPairs: Set<String> = []

    private var track: Double {
        gaps[KerningMath.trackKey] ?? 0
    }

    var body: some View {
        let sample = text.isEmpty ? " " : text
        HStack(spacing: 0) {
            ForEach(Array(sample.enumerated()), id: \.offset) { index, character in
                let active = isActive(index: index, in: sample)
                let marked = isMarked(index: index, in: sample)
                Text(String(character))
                    .font(.system(size: compact ? min(fontSize, 22) : fontSize, weight: .semibold, design: .serif))
                    .foregroundColor(active ? Palette.background : Palette.primary)
                    .padding(.horizontal, active ? 2 : 0)
                    .background(active ? Palette.primary : Color.clear)
                    .overlay(alignment: .bottom) {
                        if marked && active == false {
                            Rectangle()
                                .fill(Palette.accent)
                                .frame(height: 2)
                                .offset(y: 3)
                        }
                    }
                    .kerning(0)
                    .tracking(track)
                    .padding(.trailing, trailingGap(after: index, in: sample))
            }
        }
        .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
        .padding(.bottom, (highlightPair == nil && markedPairs.isEmpty) ? 0 : 4)
        .lineLimit(compact ? 1 : 4)
        .minimumScaleFactor(compact ? 0.55 : 0.7)
    }

    private func trailingGap(after index: Int, in sample: String) -> CGFloat {
        let pair = KerningMath.pairGap(after: index, in: sample, gaps: gaps)
        let extraTrack = index + 1 < sample.count ? CGFloat(track) : 0
        return pair + extraTrack
    }

    private func isActive(index: Int, in sample: String) -> Bool {
        guard let highlightPair else { return false }
        if highlightPair == KerningMath.trackKey {
            return sample != " "
        }
        return belongs(index: index, in: sample, to: highlightPair)
    }

    private func isMarked(index: Int, in sample: String) -> Bool {
        markedPairs.contains { belongs(index: index, in: sample, to: $0) }
    }

    private func belongs(index: Int, in sample: String, to pair: String) -> Bool {
        if let current = KerningMath.pair(at: index, in: sample), current == pair {
            return true
        }
        if let previous = KerningMath.pair(at: index - 1, in: sample), previous == pair {
            return true
        }
        return false
    }
}

struct MetalChip: View {
    let title: String
    var selected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(selected ? Palette.background : Palette.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(selected ? Palette.primary : Palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .circular)
                        .stroke(Palette.accent.opacity(selected ? 0 : 0.45), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
        }
        .buttonStyle(.plain)
    }
}

struct NoticeSnack: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Palette.primary)
            Spacer(minLength: 8)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(Palette.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Palette.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
            }
        }
        .padding(12)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .circular)
                .stroke(Palette.primary, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct UndoSnack: View {
    let title: String
    let undo: () -> Void

    var body: some View {
        NoticeSnack(title: title, actionTitle: "Undo", action: undo)
    }
}

struct MonoMetric: View {
    let value: Double

    var body: some View {
        Text(KerningMath.formatted(value))
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(Palette.primary)
    }
}

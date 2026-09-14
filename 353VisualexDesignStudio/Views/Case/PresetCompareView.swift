import SwiftUI

struct PresetCompareView: View {
    @EnvironmentObject private var store: TypeStore
    @State private var leftId: UUID?
    @State private var rightId: UUID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                if store.presets.count < 2 {
                    EmptyPlate(
                        symbol: "rectangle.split.2x1",
                        title: "Need Two Slugs",
                        detail: "Save at least two presets, then pull them onto one plate."
                    )
                } else {
                    pickerPlate(title: "LEFT", selection: $leftId)
                    pickerPlate(title: "RIGHT", selection: $rightId)
                    if let left, let right {
                        comparePlate(left)
                        comparePlate(right)
                        deltaPlate(left: left, right: right)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("COMPARE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
        }
        .onAppear {
            if leftId == nil {
                leftId = store.presets.first?.id
            }
            if rightId == nil {
                rightId = store.presets.dropFirst().first?.id ?? store.presets.first?.id
            }
        }
    }

    private var left: KerningPreset? {
        store.presets.first(where: { $0.id == leftId })
    }

    private var right: KerningPreset? {
        store.presets.first(where: { $0.id == rightId })
    }

    private func pickerPlate(title: String, selection: Binding<UUID?>) -> some View {
        MetalPlate {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundColor(Palette.accent)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.presets) { preset in
                            MetalChip(title: preset.name, selected: selection.wrappedValue == preset.id) {
                                selection.wrappedValue = preset.id
                            }
                        }
                    }
                }
            }
        }
    }

    private func comparePlate(_ preset: KerningPreset) -> some View {
        MetalPlate(emphasized: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(preset.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Text(preset.projectTitle.isEmpty ? "No project" : preset.projectTitle)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Palette.accent.opacity(0.8))
                }
                KerningPreview(
                    text: preset.sampleText,
                    gaps: preset.pairGaps,
                    fontSize: 28
                )
                Text(KerningMath.readout(preset.pairGaps))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Palette.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func deltaPlate(left: KerningPreset, right: KerningPreset) -> some View {
        MetalPlate {
            VStack(alignment: .leading, spacing: 8) {
                Text("DELTA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundColor(Palette.accent)
                deltaLine("TRACKING", left.tracking - right.tracking)
                ForEach(deltaKeys(left: left, right: right), id: \.self) { key in
                    deltaLine(key, (left.pairGaps[key] ?? 0) - (right.pairGaps[key] ?? 0))
                }
            }
        }
    }

    private func deltaKeys(left: KerningPreset, right: KerningPreset) -> [String] {
        var keys = KerningMath.pairKeys
        var seen = Set(keys)
        let extras = Set(left.pairGaps.keys).union(right.pairGaps.keys)
            .filter { $0 != KerningMath.trackKey && seen.contains($0) == false }
            .sorted()
        for key in extras {
            let delta = (left.pairGaps[key] ?? 0) - (right.pairGaps[key] ?? 0)
            if delta != 0 {
                keys.append(key)
                seen.insert(key)
            }
        }
        return keys
    }

    private func deltaLine(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(Palette.accent)
            Spacer()
            Text(KerningMath.formatted(value))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Palette.primary)
        }
    }
}

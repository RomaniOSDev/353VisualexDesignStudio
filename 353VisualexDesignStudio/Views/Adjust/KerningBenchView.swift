import SwiftUI
import UIKit

struct KerningBenchView: View {
    @EnvironmentObject private var store: TypeStore
    @State private var showSave = false
    @State private var showFullProof = false
    @State private var activePair: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                if store.presets.isEmpty {
                    EmptyPlate(
                        symbol: "textformat.size.larger",
                        title: "No Kerning Presets Yet",
                        detail: "Set the sample, pull pair sliders, then save a slug to the case."
                    )
                }

                if store.tutorialShown == false {
                    tipPlate
                }

                MetalPlate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SAMPLE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.6)
                            .foregroundColor(Palette.accent)
                        TextField("Type a lockup", text: draftText)
                            .font(.system(size: 17, weight: .medium, design: .serif))
                            .foregroundColor(Palette.primary)
                            .tint(Palette.primary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(KerningMath.sampleLibrary, id: \.self) { sample in
                                    MetalChip(
                                        title: sample,
                                        selected: store.lastEditedText == sample
                                    ) {
                                        store.setDraftText(sample)
                                    }
                                }
                            }
                        }
                    }
                }

                MetalPlate(emphasized: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("LIVE PROOF")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.6)
                                .foregroundColor(Palette.accent)
                            Spacer()
                            Button {
                                showFullProof = true
                            } label: {
                                Text("FULL")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(Palette.background)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Palette.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Fullscreen proof")
                        }
                        KerningPreview(
                            text: store.lastEditedText,
                            gaps: store.draftGaps,
                            fontSize: store.defaultFontSize,
                            highlightPair: activePair,
                            markedPairs: markedPairs
                        )
                        .padding(.vertical, 8)
                        Text(store.lastEditedText.isEmpty ? " " : store.lastEditedText)
                            .font(.system(size: store.defaultFontSize, weight: .semibold, design: .serif))
                            .foregroundColor(Palette.accent)
                            .tracking(store.draftGaps[KerningMath.trackKey] ?? 0)
                            .frame(maxWidth: .infinity)
                            .minimumScaleFactor(0.6)
                            .lineLimit(3)
                    }
                }

                fontSizePlate

                ForEach(KerningMath.sliderPairs(for: store.lastEditedText), id: \.self) { key in
                    pairSlider(key: key, label: "PAIR \(key)")
                }
                pairSlider(key: KerningMath.trackKey, label: "TRACKING")

                Button {
                    showSave = true
                } label: {
                    Text("Save Preset")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Palette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Palette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("KERNING")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFullProof = true
                } label: {
                    MetalSlug(mark: "FS")
                }
                .accessibilityLabel("Fullscreen proof")
            }
        }
        .sheet(isPresented: $showSave) {
            SavePresetSheet()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showFullProof) {
            FullProofView(highlightPair: activePair)
                .environmentObject(store)
        }
    }

    private var draftText: Binding<String> {
        Binding(
            get: { store.lastEditedText },
            set: { store.setDraftText($0) }
        )
    }

    private var markedPairs: Set<String> {
        Set(
            store.draftGaps.compactMap { key, value in
                if key == KerningMath.trackKey || value == 0 {
                    return nil
                }
                return key
            }
        )
    }

    private var tipPlate: some View {
        MetalPlate {
            HStack(alignment: .top, spacing: 10) {
                Text("Sliders follow pairs in the sample. Tracking moves every letter. Tap a chip to load a lockup.")
                    .font(.system(size: 13))
                    .foregroundColor(Palette.primary)
                Button {
                    store.dismissTutorial()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Palette.background)
                        .frame(width: 22, height: 22)
                        .background(Palette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Hide tip")
            }
        }
    }

    private var fontSizePlate: some View {
        MetalPlate {
            HStack(spacing: 12) {
                Image(systemName: "textformat.size.larger")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Palette.primary)
                Text("SIZE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundColor(Palette.accent)
                Spacer()
                stepButton("−") {
                    store.bumpFontSize(-2)
                }
                Text("\(Int(store.defaultFontSize.rounded()))")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Palette.primary)
                    .frame(minWidth: 36)
                stepButton("+") {
                    store.bumpFontSize(2)
                }
            }
        }
    }

    private func pairSlider(key: String, label: String) -> some View {
        let value = store.draftGaps[key] ?? 0
        return MetalPlate(emphasized: activePair == key) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Palette.accent)
                    Spacer()
                    MonoMetric(value: value)
                }
                HStack(spacing: 10) {
                    stepButton("−") {
                        bumpGap(key: key, delta: -KerningMath.gapStep)
                    }
                    Slider(
                        value: Binding(
                            get: { store.draftGaps[key] ?? 0 },
                            set: { writeGap(key: key, value: $0) }
                        ),
                        in: KerningMath.gapRange,
                        step: KerningMath.gapStep
                    ) { editing in
                        activePair = editing ? key : nil
                    }
                    .tint(Palette.primary)
                    stepButton("+") {
                        bumpGap(key: key, delta: KerningMath.gapStep)
                    }
                }
            }
        }
    }

    private func stepButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Palette.primary)
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .circular)
                        .stroke(Palette.accent.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func bumpGap(key: String, delta: Double) {
        activePair = key
        writeGap(key: key, value: (store.draftGaps[key] ?? 0) + delta)
    }

    private func writeGap(key: String, value: Double) {
        let old = store.draftGaps[key] ?? 0
        let next = KerningMath.snapGap(value)
        if KerningMath.crossedZero(from: old, to: next) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        store.setDraftGap(key: key, value: next)
    }
}

private struct FullProofView: View {
    @EnvironmentObject private var store: TypeStore
    @Environment(\.dismiss) private var dismiss
    var highlightPair: String?

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            VStack(spacing: 24) {
                HStack {
                    Text("PROOF")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Palette.primary)
                    Spacer()
                    Button("Close") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.accent)
                }
                Spacer()
                KerningPreview(
                    text: store.lastEditedText,
                    gaps: store.draftGaps,
                    fontSize: min(store.defaultFontSize + 24, KerningMath.fontSizeRange.upperBound),
                    highlightPair: highlightPair,
                    markedPairs: markedPairs
                )
                .padding(.horizontal, 8)
                Text(store.lastEditedText.isEmpty ? " " : store.lastEditedText)
                    .font(.system(size: min(store.defaultFontSize + 10, 48), weight: .semibold, design: .serif))
                    .foregroundColor(Palette.accent)
                    .tracking(store.draftGaps[KerningMath.trackKey] ?? 0)
                    .minimumScaleFactor(0.5)
                    .lineLimit(4)
                    .multilineTextAlignment(.center)
                Spacer()
                Text("Tap to close")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Palette.accent.opacity(0.7))
            }
            .padding(24)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { dismiss() })
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    private var markedPairs: Set<String> {
        Set(
            store.draftGaps.compactMap { key, value in
                if key == KerningMath.trackKey || value == 0 {
                    return nil
                }
                return key
            }
        )
    }
}

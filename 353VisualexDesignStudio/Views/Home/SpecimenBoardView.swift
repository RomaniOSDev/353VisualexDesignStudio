import SwiftUI

struct SpecimenBoardView: View {
    @EnvironmentObject private var store: TypeStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                TypeBanner(imageName: "BannerKerning", kicker: "SPECIMEN", title: "Letter stations")

                Text("Pull a slug. Kerning, case, proof, or compare.")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.accent.opacity(0.8))

                NavigationLink {
                    KerningBenchView()
                } label: {
                    stationCard(
                        letter: "K",
                        title: "KERNING",
                        detail: "Live pair bench with sliders",
                        metric: store.presets.isEmpty ? "No slugs yet" : "\(store.presets.count) in case"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PresetCaseView()
                } label: {
                    stationCard(
                        letter: "P",
                        title: "PRESETS",
                        detail: "Apply a stored metal case",
                        metric: store.presets.isEmpty ? "Empty case" : "\(store.presets.count) stored"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PresetProofView()
                } label: {
                    stationCard(
                        letter: "S",
                        title: "STATS",
                        detail: "Usage, pair, and tracking charts",
                        metric: proofMetric
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    PresetCompareView()
                } label: {
                    stationCard(
                        letter: "C",
                        title: "COMPARE",
                        detail: "Two slugs on one plate",
                        metric: store.presets.count < 2 ? "Need two slugs" : "\(store.presets.count) ready"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .padding(.bottom, 28)
        }
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SPECIMEN")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    TypeSettingsView()
                } label: {
                    MetalSlug(mark: "Aa")
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    private var proofMetric: String {
        let total = store.presets.reduce(0) { $0 + $1.usageCount }
        if store.presets.isEmpty { return "No proof yet" }
        return "\(total) pulls"
    }

    private func stationCard(letter: String, title: String, detail: String, metric: String) -> some View {
        MetalPlate(emphasized: true) {
            HStack(alignment: .center, spacing: 16) {
                Text(letter)
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .foregroundColor(Palette.primary)
                    .frame(width: 72, alignment: .center)

                Rectangle()
                    .fill(Palette.primary)
                    .frame(width: 2, height: 72)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Palette.accent)
                    Text(detail)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Palette.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(metric)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Palette.accent.opacity(0.8))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

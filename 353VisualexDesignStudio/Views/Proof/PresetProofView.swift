import Charts
import SwiftUI

struct PresetProofView: View {
    @EnvironmentObject private var store: TypeStore
    @State private var sort: ProofSort = .recent
    @State private var expandedId: UUID?
    @State private var editing: KerningPreset?

    var body: some View {
        VStack(spacing: 0) {
            List {
                bannerSection
                if rows.isEmpty {
                    emptySection
                } else {
                    summarySection
                    usageChartSection
                    pairChartSection
                    trackingChartSection
                    if projectSlices.count > 1 {
                        projectChartSection
                    }
                    sortSection
                    insightSection
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("STATS")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
        }
        .sheet(item: $editing) { preset in
            PresetEditSheet(preset: preset)
                .environmentObject(store)
        }
        .safeAreaInset(edge: .bottom) {
            if store.pendingUndo != nil {
                UndoSnack(title: "Preset removed") {
                    store.undoRemove()
                }
            }
        }
        .onDisappear {
            store.discardUndo()
        }
    }

    private var rows: [PresetInsight] {
        store.sortedInsights(sort)
    }

    private var chartRows: [PresetInsight] {
        Array(rows.prefix(8))
    }

    private var maxUsage: Double {
        max(Double(rows.map(\.usageCount).max() ?? 1), 1)
    }

    private var totalPulls: Int {
        store.presets.reduce(0) { $0 + $1.usageCount }
    }

    private var averageTracking: Double {
        guard store.presets.isEmpty == false else { return 0 }
        return store.presets.map(\.tracking).reduce(0, +) / Double(store.presets.count)
    }

    private var averagePairGap: Double {
        guard store.presets.isEmpty == false else { return 0 }
        return store.presets.map(\.averagePairGap).reduce(0, +) / Double(store.presets.count)
    }

    private var pairAverages: [ChartDatum] {
        KerningMath.pairKeys.map { key in
            let values = store.presets.map { $0.pairGaps[key] ?? 0 }
            let average = values.reduce(0, +) / Double(max(values.count, 1))
            return ChartDatum(id: key, label: key, value: average)
        }
    }

    private var trackingPoints: [ChartDatum] {
        chartRows.map { insight in
            ChartDatum(id: insight.id.uuidString, label: insight.name, value: insight.tracking)
        }
    }

    private var usagePoints: [ChartDatum] {
        chartRows.map { insight in
            ChartDatum(id: insight.id.uuidString, label: insight.name, value: Double(insight.usageCount))
        }
    }

    private var projectSlices: [ChartDatum] {
        var counts: [String: Int] = [:]
        for preset in store.presets {
            let key = preset.projectTitle.isEmpty ? "Unfiled" : preset.projectTitle
            counts[key, default: 0] += 1
        }
        return counts
            .map { ChartDatum(id: $0.key, label: $0.key, value: Double($0.value)) }
            .sorted { $0.value > $1.value }
    }

    private var bannerSection: some View {
        Section {
            TypeBanner(imageName: "BannerInsights", kicker: "PROOF", title: "Case statistics")
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 8) {
                metricTile("PRESETS", "\(store.presets.count)")
                metricTile("PULLS", "\(totalPulls)")
                metricTile("AVG TR", KerningMath.formatted(averageTracking))
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            MetalPlate {
                HStack {
                    Text("AVG PAIR")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Palette.accent)
                    Spacer()
                    Text(KerningMath.formatted(averagePairGap))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.primary)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var usageChartSection: some View {
        Section {
            chartPlate(title: "USAGE", caption: rows.count > 8 ? "Top 8 by current sort" : "Pulls per slug") {
                Chart(usagePoints) { point in
                    BarMark(
                        x: .value("Pulls", point.value),
                        y: .value("Preset", point.label)
                    )
                    .foregroundStyle(Palette.primary)
                    .cornerRadius(3)
                }
                .chartXAxis { chartAxis }
                .chartYAxis { nameAxis }
                .frame(height: chartHeight(for: usagePoints.count))
            }
        }
    }

    private var pairChartSection: some View {
        Section {
            chartPlate(title: "PAIR PROFILE", caption: "Mean gap across the case") {
                Chart(pairAverages) { point in
                    BarMark(
                        x: .value("Pair", point.label),
                        y: .value("Gap", point.value)
                    )
                    .foregroundStyle(Palette.accent)
                    .cornerRadius(3)
                }
                .chartYScale(domain: KerningMath.gapRange)
                .chartXAxis { nameAxis }
                .chartYAxis { chartAxis }
                .frame(height: 176)
            }
        }
    }

    private var trackingChartSection: some View {
        Section {
            chartPlate(title: "TRACKING", caption: "Overall letterspacing per slug") {
                Chart {
                    ForEach(trackingPoints) { point in
                        BarMark(
                            x: .value("Tracking", point.value),
                            y: .value("Preset", point.label)
                        )
                        .foregroundStyle(point.value >= 0 ? Palette.primary : Palette.accent)
                        .cornerRadius(3)
                    }
                    RuleMark(x: .value("Zero", 0))
                        .foregroundStyle(Palette.accent.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
                .chartXScale(domain: KerningMath.gapRange)
                .chartXAxis { chartAxis }
                .chartYAxis { nameAxis }
                .frame(height: chartHeight(for: trackingPoints.count))
            }
        }
    }

    private var projectChartSection: some View {
        Section {
            chartPlate(title: "PROJECTS", caption: "How the case is filed") {
                Chart(projectSlices) { slice in
                    BarMark(
                        x: .value("Count", slice.value),
                        y: .value("Project", slice.label)
                    )
                    .foregroundStyle(Palette.accent)
                    .cornerRadius(3)
                }
                .chartXAxis { chartAxis }
                .chartYAxis { nameAxis }
                .chartXScale(domain: 0...(max(projectSlices.map(\.value).max() ?? 1, 1)))
                .frame(height: chartHeight(for: projectSlices.count))
            }
        }
    }

    private var sortSection: some View {
        Section {
            MetalPlate {
                HStack(spacing: 8) {
                    ForEach(ProofSort.allCases) { option in
                        Button {
                            sort = option
                        } label: {
                            Text(option.title)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(sort == option ? Palette.background : Palette.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(sort == option ? Palette.primary : Palette.background.opacity(0.35))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .circular)
                                        .stroke(Palette.primary.opacity(sort == option ? 0 : 0.45), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var emptySection: some View {
        Section {
            EmptyPlate(
                symbol: "chart.bar.xaxis",
                title: "No Stats Yet",
                detail: "Save a slug from the kerning bench. Charts fill in as the case grows."
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var insightSection: some View {
        Section {
            ForEach(rows) { insight in
                insightRow(insight)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let preset = store.presets.first(where: { $0.id == insight.id }) {
                                store.removePreset(preset)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editing = store.presets.first(where: { $0.id == insight.id })
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(Palette.accent)
                    }
            }
        }
    }

    private func insightRow(_ insight: PresetInsight) -> some View {
        MetalPlate(emphasized: expandedId == insight.id) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    expandedId = expandedId == insight.id ? nil : insight.id
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(insight.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Palette.primary)
                            Spacer()
                            Text("\(insight.usageCount)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Palette.primary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6, style: .circular)
                                    .fill(Palette.background)
                                RoundedRectangle(cornerRadius: 6, style: .circular)
                                    .fill(Palette.primary)
                                    .frame(width: barWidth(in: geo.size.width, count: insight.usageCount))
                            }
                        }
                        .frame(height: 10)
                    }
                }
                .buttonStyle(.plain)

                if expandedId == insight.id {
                    statsBlock(insight)
                }
            }
        }
    }

    private func statsBlock(_ insight: PresetInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Palette.primary.opacity(0.35))
                .frame(height: 1)
            statLine("PROJECT", insight.projectTitle.isEmpty ? "—" : insight.projectTitle)
            statLine("TRACKING", KerningMath.formatted(insight.tracking))
            statLine("AVG PAIR", KerningMath.formatted(insight.averagePairGap))
            statLine("LAST PULL", shortDate(insight.lastUsedDate))
            HStack(spacing: 8) {
                Button {
                    editing = store.presets.first(where: { $0.id == insight.id })
                } label: {
                    Text("Rename")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Palette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                }
                .buttonStyle(.plain)
                Button {
                    if let preset = store.presets.first(where: { $0.id == insight.id }) {
                        store.removePreset(preset)
                        if expandedId == insight.id {
                            expandedId = nil
                        }
                    }
                } label: {
                    Text("Delete")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .circular)
                                .stroke(Palette.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func metricTile(_ label: String, _ value: String) -> some View {
        MetalPlate {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(Palette.accent)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Palette.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }

    private func chartPlate<ChartBody: View>(title: String, caption: String, @ViewBuilder content: () -> ChartBody) -> some View {
        let chart = content()
        return MetalPlate {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundColor(Palette.accent)
                    Text(caption)
                        .font(.system(size: 12))
                        .foregroundColor(Palette.accent.opacity(0.78))
                }
                chart
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var chartAxis: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
            AxisGridLine()
                .foregroundStyle(Palette.accent.opacity(0.22))
            AxisTick()
                .foregroundStyle(Palette.accent.opacity(0.4))
            AxisValueLabel()
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.accent)
        }
    }

    private var nameAxis: some AxisContent {
        AxisMarks { _ in
            AxisValueLabel()
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.primary)
        }
    }

    private func chartHeight(for count: Int) -> CGFloat {
        max(132, CGFloat(max(count, 1)) * 28 + 18)
    }

    private func statLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(Palette.accent)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(Palette.primary)
        }
    }

    private func barWidth(in total: CGFloat, count: Int) -> CGFloat {
        let ratio = CGFloat(Double(count) / maxUsage)
        return max(6, total * max(0, min(1, ratio)))
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ChartDatum: Identifiable {
    var id: String
    var label: String
    var value: Double
}

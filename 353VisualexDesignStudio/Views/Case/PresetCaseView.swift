import SwiftUI

struct PresetCaseView: View {
    @EnvironmentObject private var store: TypeStore
    @State private var editing: KerningPreset?
    @State private var appliedName: String = ""
    @State private var query: String = ""
    @State private var projectFilter: String?

    var body: some View {
        VStack(spacing: 0) {
            List {
                bannerSection
                if store.presets.isEmpty {
                    emptySection
                } else {
                    searchSection
                    if projectFilters.isEmpty == false {
                        projectSection
                    }
                    if visiblePresets.isEmpty {
                        matchEmptySection
                    } else {
                        presetSection
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .environment(\.defaultMinListRowHeight, 1)
        }
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("PRESETS")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 10) {
                    if store.presets.count >= 2 {
                        NavigationLink {
                            PresetCompareView()
                        } label: {
                            Text("VS")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(Palette.primary)
                        }
                    }
                    if store.presets.isEmpty == false {
                        EditButton()
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(Palette.primary)
                    }
                }
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if appliedName.isEmpty == false {
                NoticeSnack(title: "\(appliedName) loaded on the bench")
            }
        }
        .onChange(of: store.pendingUndo) { pending in
            if pending != nil {
                appliedName = ""
            }
        }
        .onDisappear {
            store.discardUndo()
        }
    }

    private var visiblePresets: [KerningPreset] {
        store.presets.filter { preset in
            matchesQuery(preset) && matchesProject(preset)
        }
    }

    private var projectFilters: [String] {
        var seen = Set<String>()
        var titles: [String] = []
        if store.presets.contains(where: { $0.projectTitle.isEmpty }) {
            titles.append("Unfiled")
        }
        for preset in store.presets {
            let title = preset.projectTitle
            guard title.isEmpty == false else { continue }
            let key = title.lowercased()
            if seen.contains(key) == false {
                seen.insert(key)
                titles.append(title)
            }
        }
        return titles
    }

    private var bannerSection: some View {
        Section {
            TypeBanner(imageName: "BannerPresets", kicker: "CASE", title: "Stored pair slugs")
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }

    private var searchSection: some View {
        Section {
            MetalPlate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SEARCH")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundColor(Palette.accent)
                    TextField("Name, project, or sample", text: $query)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Palette.primary)
                        .tint(Palette.primary)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var projectSection: some View {
        Section {
            MetalPlate {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PROJECT")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundColor(Palette.accent)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            MetalChip(title: "All", selected: projectFilter == nil) {
                                projectFilter = nil
                            }
                            ForEach(projectFilters, id: \.self) { title in
                                MetalChip(title: title, selected: projectFilter == title) {
                                    projectFilter = title
                                }
                            }
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var emptySection: some View {
        Section {
            EmptyPlate(
                symbol: "text.badge.plus",
                title: "No Presets Yet",
                detail: "Save a slug from the kerning bench. This case stays ready."
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var matchEmptySection: some View {
        Section {
            EmptyPlate(
                symbol: "line.3.horizontal.decrease",
                title: "No Match",
                detail: "Clear the search or pick another project chip."
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var presetSection: some View {
        Section {
            ForEach(visiblePresets) { preset in
                presetRow(preset)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            store.duplicatePreset(preset)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(Palette.primary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.removePreset(preset)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            editing = preset
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Palette.accent)
                    }
            }
            .onDelete(perform: deleteOffsets)
        }
    }

    private func presetRow(_ preset: KerningPreset) -> some View {
        MetalPlate(emphasized: store.lastUsedPresetId == preset.id) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Button {
                        store.applyPreset(preset)
                        appliedName = preset.name
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Palette.primary)
                            Text(preset.projectTitle.isEmpty ? "No project" : preset.projectTitle)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(Palette.accent.opacity(0.8))
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button {
                        store.duplicatePreset(preset)
                    } label: {
                        MetalSlug(mark: "Cp")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Duplicate \(preset.name)")
                    Button {
                        editing = preset
                    } label: {
                        MetalSlug(mark: "Ed")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit \(preset.name)")
                }

                KerningPreview(
                    text: preset.sampleText,
                    gaps: preset.pairGaps,
                    fontSize: 20,
                    compact: true
                )

                Text(KerningMath.readout(preset.pairGaps))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Palette.accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private func matchesQuery(_ preset: KerningPreset) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return true }
        return preset.name.localizedCaseInsensitiveContains(needle)
            || preset.projectTitle.localizedCaseInsensitiveContains(needle)
            || preset.sampleText.localizedCaseInsensitiveContains(needle)
    }

    private func matchesProject(_ preset: KerningPreset) -> Bool {
        guard let projectFilter else { return true }
        if projectFilter == "Unfiled" {
            return preset.projectTitle.isEmpty
        }
        return preset.projectTitle.compare(projectFilter, options: .caseInsensitive) == .orderedSame
    }

    private func deleteOffsets(_ offsets: IndexSet) {
        let targets = offsets.compactMap { index -> KerningPreset? in
            guard visiblePresets.indices.contains(index) else { return nil }
            return visiblePresets[index]
        }
        for preset in targets {
            store.removePreset(preset)
        }
    }
}

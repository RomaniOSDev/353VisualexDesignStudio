import Combine
import Foundation

@MainActor
final class TypeStore: ObservableObject {
    @Published var presets: [KerningPreset] = []
    @Published var lastEditedText: String = KerningMath.defaultText
    @Published var defaultFontSize: Double = KerningMath.defaultFontSize
    @Published var lastUsedPresetId: UUID?
    @Published var tutorialShown: Bool = false
    @Published var projectTitles: [String] = []
    @Published var draftGaps: [String: Double] = KerningMath.defaultGaps()
    @Published var pendingUndo: KerningPreset?

    var insights: [PresetInsight] {
        presets.map(PresetInsight.init)
    }

    private let defaults: UserDefaults
    private var bag = Set<AnyCancellable>()

    private enum Key {
        static let presets = "type.presets"
        static let lastEditedText = "type.lastEditedText"
        static let defaultFontSize = "type.defaultFontSize"
        static let lastUsedPresetId = "type.lastUsedPresetId"
        static let tutorialShown = "type.tutorialShown"
        static let projectTitles = "type.projectTitles"
        static let draftGaps = "type.draftGaps"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadAll()
        NotificationCenter.default.publisher(for: Notification.Name("dataReset"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadAll()
            }
            .store(in: &bag)
    }

    func setDraftText(_ text: String) {
        lastEditedText = text
        persist()
    }

    func setDraftGap(key: String, value: Double) {
        draftGaps[key] = KerningMath.clampGap(value)
        persist()
    }

    func setFontSize(_ size: Double) {
        defaultFontSize = KerningMath.clampFontSize(size)
        persist()
    }

    func bumpFontSize(_ delta: Double) {
        setFontSize(defaultFontSize + delta)
    }

    func dismissTutorial() {
        tutorialShown = true
        persist()
    }

    func nameConflict(_ raw: String, ignoring id: UUID?) -> String? {
        let name = normalized(raw)
        if name.isEmpty {
            return "Enter a preset name."
        }
        let taken = presets.contains { preset in
            if let id, preset.id == id { return false }
            return preset.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        if taken {
            return "That name is already in the case."
        }
        return nil
    }

    func savePreset(name: String, projectTitle: String) -> String? {
        if let conflict = nameConflict(name, ignoring: nil) {
            return conflict
        }
        let preset = KerningPreset(
            name: normalized(name),
            sampleText: lastEditedText,
            pairGaps: KerningMath.clamped(draftGaps),
            lastUsedDate: Date(),
            usageCount: 1,
            projectTitle: normalized(projectTitle)
        )
        presets.insert(preset, at: 0)
        lastUsedPresetId = preset.id
        rememberProject(preset.projectTitle)
        persist()
        return nil
    }

    func updatePresetFromBench(id: UUID, name: String, projectTitle: String) -> String? {
        if let conflict = nameConflict(name, ignoring: id) {
            return conflict
        }
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return "That preset is no longer in the case."
        }
        presets[index].name = normalized(name)
        presets[index].projectTitle = normalized(projectTitle)
        presets[index].sampleText = lastEditedText
        presets[index].pairGaps = KerningMath.clamped(draftGaps)
        presets[index].lastUsedDate = Date()
        lastUsedPresetId = id
        rememberProject(presets[index].projectTitle)
        persist()
        return nil
    }

    func renamePreset(id: UUID, name: String, projectTitle: String) -> String? {
        if let conflict = nameConflict(name, ignoring: id) {
            return conflict
        }
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            return "That preset is no longer in the case."
        }
        presets[index].name = normalized(name)
        presets[index].projectTitle = normalized(projectTitle)
        rememberProject(presets[index].projectTitle)
        persist()
        return nil
    }

    func duplicatePreset(_ preset: KerningPreset) {
        let copy = KerningPreset(
            name: uniqueCopyName(preset.name),
            sampleText: preset.sampleText,
            pairGaps: KerningMath.clamped(preset.pairGaps),
            lastUsedDate: Date(),
            usageCount: 0,
            projectTitle: preset.projectTitle
        )
        presets.insert(copy, at: 0)
        rememberProject(copy.projectTitle)
        persist()
    }

    func applyPreset(_ preset: KerningPreset) {
        lastEditedText = preset.sampleText
        draftGaps = KerningMath.clamped(preset.pairGaps)
        lastUsedPresetId = preset.id
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index].usageCount += 1
            presets[index].lastUsedDate = Date()
        }
        persist()
    }

    func removePreset(_ preset: KerningPreset) {
        presets.removeAll { $0.id == preset.id }
        if lastUsedPresetId == preset.id {
            lastUsedPresetId = nil
        }
        pendingUndo = preset
        persist()
    }

    func undoRemove() {
        guard let pendingUndo else { return }
        if presets.contains(where: { $0.id == pendingUndo.id }) == false {
            presets.insert(pendingUndo, at: 0)
        }
        rememberProject(pendingUndo.projectTitle)
        self.pendingUndo = nil
        persist()
    }

    func discardUndo() {
        pendingUndo = nil
    }

    func sortedInsights(_ sort: ProofSort) -> [PresetInsight] {
        switch sort {
        case .recent:
            return insights.sorted { $0.lastUsedDate > $1.lastUsedDate }
        case .frequency:
            return insights.sorted {
                if $0.usageCount == $1.usageCount {
                    return $0.lastUsedDate > $1.lastUsedDate
                }
                return $0.usageCount > $1.usageCount
            }
        }
    }

    func resetAllData() {
        presets = []
        lastEditedText = KerningMath.defaultText
        defaultFontSize = KerningMath.defaultFontSize
        lastUsedPresetId = nil
        tutorialShown = false
        projectTitles = []
        draftGaps = KerningMath.defaultGaps()
        pendingUndo = nil
        defaults.removeObject(forKey: Key.presets)
        defaults.removeObject(forKey: Key.lastEditedText)
        defaults.removeObject(forKey: Key.defaultFontSize)
        defaults.removeObject(forKey: Key.lastUsedPresetId)
        defaults.removeObject(forKey: Key.tutorialShown)
        defaults.removeObject(forKey: Key.projectTitles)
        defaults.removeObject(forKey: Key.draftGaps)
        NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
    }

    func loadAll() {
        presets = decode([KerningPreset].self, key: Key.presets) ?? []
        presets = presets.map { preset in
            var copy = preset
            copy.pairGaps = KerningMath.clamped(preset.pairGaps)
            return copy
        }
        if let text = defaults.string(forKey: Key.lastEditedText) {
            lastEditedText = text
        } else {
            lastEditedText = KerningMath.defaultText
        }
        if defaults.object(forKey: Key.defaultFontSize) != nil {
            defaultFontSize = KerningMath.clampFontSize(defaults.double(forKey: Key.defaultFontSize))
        } else {
            defaultFontSize = KerningMath.defaultFontSize
        }
        if let raw = defaults.string(forKey: Key.lastUsedPresetId) {
            lastUsedPresetId = UUID(uuidString: raw)
        } else {
            lastUsedPresetId = nil
        }
        tutorialShown = defaults.bool(forKey: Key.tutorialShown)
        projectTitles = decode([String].self, key: Key.projectTitles) ?? []
        draftGaps = KerningMath.clamped(decode([String: Double].self, key: Key.draftGaps) ?? KerningMath.defaultGaps())
        pendingUndo = nil
        for preset in presets {
            rememberProject(preset.projectTitle)
        }
    }

    private func persist() {
        encode(presets, key: Key.presets)
        defaults.set(lastEditedText, forKey: Key.lastEditedText)
        defaults.set(defaultFontSize, forKey: Key.defaultFontSize)
        if let lastUsedPresetId {
            defaults.set(lastUsedPresetId.uuidString, forKey: Key.lastUsedPresetId)
        } else {
            defaults.removeObject(forKey: Key.lastUsedPresetId)
        }
        defaults.set(tutorialShown, forKey: Key.tutorialShown)
        encode(projectTitles, key: Key.projectTitles)
        encode(KerningMath.clamped(draftGaps), key: Key.draftGaps)
    }

    private func uniqueCopyName(_ raw: String) -> String {
        let base = normalized(raw)
        let seed = base.isEmpty ? "Preset copy" : "\(base) copy"
        if nameConflict(seed, ignoring: nil) == nil {
            return seed
        }
        var index = 2
        while true {
            let candidate = "\(seed) \(index)"
            if nameConflict(candidate, ignoring: nil) == nil {
                return candidate
            }
            index += 1
        }
    }

    private func rememberProject(_ title: String) {
        let trimmed = normalized(title)
        guard trimmed.isEmpty == false else { return }
        if projectTitles.contains(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) == false {
            projectTitles.insert(trimmed, at: 0)
        }
    }

    private func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(type, from: data)
    }
}

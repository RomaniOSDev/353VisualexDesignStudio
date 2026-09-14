import Foundation

struct KerningPreset: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var sampleText: String
    var pairGaps: [String: Double]
    var lastUsedDate: Date
    var usageCount: Int
    var projectTitle: String

    init(
        id: UUID = UUID(),
        name: String,
        sampleText: String,
        pairGaps: [String: Double],
        lastUsedDate: Date = Date(),
        usageCount: Int = 0,
        projectTitle: String
    ) {
        self.id = id
        self.name = name
        self.sampleText = sampleText
        self.pairGaps = KerningMath.clamped(pairGaps)
        self.lastUsedDate = lastUsedDate
        self.usageCount = max(0, usageCount)
        self.projectTitle = projectTitle
    }

    var tracking: Double {
        pairGaps[KerningMath.trackKey] ?? 0
    }

    var averagePairGap: Double {
        let values = pairGaps.compactMap { key, value -> Double? in
            key == KerningMath.trackKey ? nil : value
        }
        guard values.isEmpty == false else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

struct PresetInsight: Identifiable, Equatable {
    var id: UUID
    var name: String
    var projectTitle: String
    var sampleText: String
    var usageCount: Int
    var lastUsedDate: Date
    var tracking: Double
    var averagePairGap: Double
    var pairGaps: [String: Double]

    init(preset: KerningPreset) {
        id = preset.id
        name = preset.name
        projectTitle = preset.projectTitle
        sampleText = preset.sampleText
        usageCount = preset.usageCount
        lastUsedDate = preset.lastUsedDate
        tracking = preset.tracking
        averagePairGap = preset.averagePairGap
        pairGaps = preset.pairGaps
    }
}

enum ProofSort: String, CaseIterable, Identifiable {
    case recent
    case frequency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Recent"
        case .frequency: return "Frequency"
        }
    }
}

enum KerningMath {
    static let pairKeys = ["AV", "To", "WA", "LT"]
    static let trackKey = "TRACK"
    static let gapRange: ClosedRange<Double> = -12...24
    static let gapStep = 0.5
    static let maxPairSliders = 12
    static let fontSizeRange: ClosedRange<Double> = 16...72
    static let defaultFontSize = 28.0
    static let defaultText = "AV To WA LT"
    static let plateCorner: CGFloat = 7
    static let sampleLibrary = [
        "AV To WA LT",
        "YEAR",
        "WATER",
        "LATIN",
        "TYPE",
        "WAVE",
        "ATLAS",
        "TAVERN"
    ]

    static func defaultGaps() -> [String: Double] {
        var gaps: [String: Double] = [trackKey: 0]
        for key in pairKeys {
            gaps[key] = 0
        }
        return gaps
    }

    static func clampGap(_ value: Double) -> Double {
        min(max(value, gapRange.lowerBound), gapRange.upperBound)
    }

    static func clampFontSize(_ value: Double) -> Double {
        min(max(value, fontSizeRange.lowerBound), fontSizeRange.upperBound)
    }

    static func clamped(_ gaps: [String: Double]) -> [String: Double] {
        var result = defaultGaps()
        for (key, value) in gaps {
            result[key] = clampGap(value)
        }
        return result
    }

    static func pairGap(after index: Int, in text: String, gaps: [String: Double]) -> CGFloat {
        let chars = Array(text)
        guard index + 1 < chars.count else { return 0 }
        let pair = String(chars[index]) + String(chars[index + 1])
        return CGFloat(gaps[pair] ?? 0)
    }

    static func pair(at index: Int, in text: String) -> String? {
        let chars = Array(text)
        guard index >= 0, index + 1 < chars.count else { return nil }
        let first = chars[index]
        let second = chars[index + 1]
        if first.isWhitespace || second.isWhitespace {
            return nil
        }
        return String(first) + String(second)
    }

    static func pairs(in text: String) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        let chars = Array(text)
        guard chars.count > 1 else { return [] }
        for index in 0..<(chars.count - 1) {
            guard let pair = pair(at: index, in: text) else { continue }
            if seen.contains(pair) == false {
                seen.insert(pair)
                result.append(pair)
            }
        }
        return result
    }

    static func sliderPairs(for text: String) -> [String] {
        var keys: [String] = []
        var seen = Set<String>()
        for key in pairKeys {
            keys.append(key)
            seen.insert(key)
        }
        for key in pairs(in: text) {
            if keys.count >= maxPairSliders {
                break
            }
            if seen.contains(key) {
                continue
            }
            keys.append(key)
            seen.insert(key)
        }
        return keys
    }

    static func snapGap(_ value: Double) -> Double {
        clampGap((value / gapStep).rounded() * gapStep)
    }

    static func crossedZero(from old: Double, to new: Double) -> Bool {
        if old == new { return false }
        if new == 0 { return true }
        return (old < 0 && new > 0) || (old > 0 && new < 0)
    }

    static func formatted(_ value: Double) -> String {
        String(format: "%+.1f", value)
    }

    static func readout(_ gaps: [String: Double]) -> String {
        var parts = pairKeys.map { key in
            "\(key) \(formatted(gaps[key] ?? 0))"
        }
        let extras = gaps.keys
            .filter { $0 != trackKey && pairKeys.contains($0) == false }
            .sorted()
        for key in extras {
            let value = gaps[key] ?? 0
            if value != 0 {
                parts.append("\(key) \(formatted(value))")
            }
        }
        parts.append("TR \(formatted(gaps[trackKey] ?? 0))")
        return parts.joined(separator: "  ")
    }
}

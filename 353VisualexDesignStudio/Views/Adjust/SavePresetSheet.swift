import SwiftUI

struct SavePresetSheet: View {
    @EnvironmentObject private var store: TypeStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var projectTitle: String = ""
    @State private var errorText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Name must be unique. Gaps stay inside −12…24.")
                        .font(.system(size: 13))
                        .foregroundColor(Palette.accent.opacity(0.8))

                    fieldPlate(title: "PRESET NAME", text: $name, placeholder: "Tight Headline")
                    fieldPlate(title: "PROJECT TITLE", text: $projectTitle, placeholder: "Poster lockup")

                    if store.projectTitles.isEmpty == false {
                        Text("RECENT PROJECTS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.6)
                            .foregroundColor(Palette.accent)
                        FlexibleTitleRow(titles: store.projectTitles) { title in
                            projectTitle = title
                        }
                    }

                    if errorText.isEmpty == false {
                        Text(errorText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Palette.primary)
                    }

                    Button {
                        commitNew()
                    } label: {
                        metalAction("Save New")
                    }
                    .buttonStyle(.plain)

                    if let current = currentPreset {
                        Button {
                            commitUpdate(current.id)
                        } label: {
                            metalAction("Update \(current.name)")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
            .studioBackdrop()
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Palette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SAVE PRESET")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundColor(Palette.primary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear {
                if let current = currentPreset {
                    name = current.name
                    projectTitle = current.projectTitle
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Palette.primary)
        .dismissKeyboardOnTap()
    }

    private var currentPreset: KerningPreset? {
        guard let id = store.lastUsedPresetId else { return nil }
        return store.presets.first(where: { $0.id == id })
    }

    private func commitNew() {
        if let error = store.savePreset(name: name, projectTitle: projectTitle) {
            errorText = error
            return
        }
        dismiss()
    }

    private func commitUpdate(_ id: UUID) {
        if let error = store.updatePresetFromBench(id: id, name: name, projectTitle: projectTitle) {
            errorText = error
            return
        }
        dismiss()
    }

    private func fieldPlate(title: String, text: Binding<String>, placeholder: String) -> some View {
        MetalPlate {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundColor(Palette.accent)
                TextField(placeholder, text: text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Palette.primary)
                    .tint(Palette.primary)
            }
        }
    }

    private func metalAction(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Palette.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Palette.primary)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
    }
}

private struct FlexibleTitleRow: View {
    let titles: [String]
    let pick: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(titles, id: \.self) { title in
                    Button {
                        pick(title)
                    } label: {
                        Text(title)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(Palette.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Palette.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .circular)
                                    .stroke(Palette.accent.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

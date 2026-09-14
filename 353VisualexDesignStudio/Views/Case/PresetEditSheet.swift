import SwiftUI

struct PresetEditSheet: View {
    @EnvironmentObject private var store: TypeStore
    @Environment(\.dismiss) private var dismiss

    let preset: KerningPreset
    @State private var name: String = ""
    @State private var projectTitle: String = ""
    @State private var errorText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Names stay unique across the case.")
                        .font(.system(size: 13))
                        .foregroundColor(Palette.accent.opacity(0.8))

                    MetalPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRESET NAME")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.6)
                                .foregroundColor(Palette.accent)
                            TextField("Name", text: $name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Palette.primary)
                                .tint(Palette.primary)
                        }
                    }

                    MetalPlate {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PROJECT TITLE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1.6)
                                .foregroundColor(Palette.accent)
                            TextField("Project", text: $projectTitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Palette.primary)
                                .tint(Palette.primary)
                        }
                    }

                    if errorText.isEmpty == false {
                        Text(errorText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Palette.primary)
                    }

                    Button {
                        if let error = store.renamePreset(id: preset.id, name: name, projectTitle: projectTitle) {
                            errorText = error
                            return
                        }
                        dismiss()
                    } label: {
                        Text("Save Name")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Palette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Palette.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                    }
                    .buttonStyle(.plain)
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
                    Text("EDIT PRESET")
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
                name = preset.name
                projectTitle = preset.projectTitle
            }
        }
        .preferredColorScheme(.dark)
        .tint(Palette.primary)
        .dismissKeyboardOnTap()
    }
}

import SwiftUI
import UIKit

struct TypeSettingsView: View {
    @EnvironmentObject private var store: TypeStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Plate actions. Nothing leaves the device except the links below.")
                    .font(.system(size: 13))
                    .foregroundColor(Palette.accent.opacity(0.8))

                actionPlate(title: "Rate Us", detail: "Open the App Store review prompt.") {
                    AppLinks.rateApp()
                }
                actionPlate(title: "Privacy", detail: "Read the privacy policy.") {
                    open(AppLinks.privacy)
                }
                actionPlate(title: "Terms", detail: "Read the terms of use.") {
                    open(AppLinks.terms)
                }
                actionPlate(title: "Reset All Data", detail: "Clears presets, draft, and proof counts.", danger: true) {
                    confirmReset = true
                }
            }
            .padding(16)
        }
        .studioBackdrop()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SETTINGS")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(Palette.primary)
            }
        }
        .alert("Reset All Data", isPresented: $confirmReset) {
            Button("Reset", role: .destructive) {
                store.resetAllData()
                dismiss()
            }
            Button("Keep Data", role: .cancel) { }
        } message: {
            Text("This clears every preset, the live draft, font size, and proof stats.")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            dismiss()
        }
    }

    private func actionPlate(title: String, detail: String, danger: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            MetalPlate {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Palette.primary)
                        Text(detail)
                            .font(.system(size: 13))
                            .foregroundColor(Palette.accent.opacity(0.78))
                    }
                    Spacer()
                    Text(danger ? "CLR" : "GO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(Palette.background)
                        .frame(width: 34, height: 24)
                        .background(Palette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .circular))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func open(_ link: AppLinks) {
        if let url = URL(string: link.rawValue) {
            UIApplication.shared.open(url)
        }
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var store = TypeStore()

    var body: some View {
        NavigationStack {
            SpecimenBoardView()
        }
        .environmentObject(store)
        .tint(Palette.primary)
        .preferredColorScheme(.dark)
        .dismissKeyboardOnTap()
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            store.loadAll()
        }
    }
}

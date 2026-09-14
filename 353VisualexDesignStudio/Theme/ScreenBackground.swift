import SwiftUI
import UIKit

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("BgStudio")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.22)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func studioBackdrop() -> some View {
        modifier(ScreenBackground())
    }

    func dismissKeyboardOnTap() -> some View {
        background(WindowKeyboardDismiss())
    }
}

private struct WindowKeyboardDismiss: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> Host {
        let host = Host()
        host.coordinator = context.coordinator
        host.isUserInteractionEnabled = false
        host.backgroundColor = .clear
        return host
    }

    func updateUIView(_ uiView: Host, context: Context) {
        uiView.coordinator = context.coordinator
        context.coordinator.install(from: uiView)
    }

    static func dismantleUIView(_ uiView: Host, coordinator: Coordinator) {
        coordinator.detach()
        uiView.coordinator = nil
    }

    final class Host: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.install(from: self)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var attachedWindow: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func install(from view: UIView) {
            guard let window = view.window else {
                detach()
                return
            }
            if attachedWindow === window, recognizer != nil {
                return
            }
            detach()
            let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            attachedWindow = window
            recognizer = tap
        }

        func detach() {
            if let recognizer {
                recognizer.view?.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            attachedWindow = nil
        }

        @objc private func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var node = touch.view
            while let current = node {
                if current is UITextField || current is UITextView {
                    return false
                }
                node = current.superview
            }
            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

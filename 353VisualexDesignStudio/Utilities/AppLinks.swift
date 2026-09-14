import StoreKit
import UIKit

enum AppLinks: String {
    case privacy = "https://visualex353designstudio.site/privacy/465"
    case terms = "https://visualex353designstudio.site/terms/465"

    static func rateApp() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { scene in
            scene as? UIWindowScene
        }
        let windowScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive
        }) ?? scenes.first
        if let windowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

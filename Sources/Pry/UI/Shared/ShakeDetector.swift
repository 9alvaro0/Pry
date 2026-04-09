import SwiftUI
import UIKit

// MARK: - View Extension

extension View {
    func onShake(enabled: Bool, action: @escaping () -> Void) -> some View {
        modifier(ShakeDetectorModifier(enabled: enabled, action: action))
    }
}

// MARK: - Modifier

private struct ShakeDetectorModifier: ViewModifier {
    package let enabled: Bool
    package let action: () -> Void

    package func body(content: Content) -> some View {
        if enabled {
            content
                .background(ShakeDetectorView(action: action))
        } else {
            content
        }
    }
}

// MARK: - UIKit Bridge

private struct ShakeDetectorView: UIViewControllerRepresentable {
    package let action: () -> Void

    func makeUIViewController(context: Context) -> ShakeDetectorController {
        ShakeDetectorController(action: action)
    }

    func updateUIViewController(_ uiViewController: ShakeDetectorController, context: Context) {}
}

final class ShakeDetectorController: UIViewController {
    package let action: () -> Void

    package init(action: @escaping () -> Void) {
        self.action = action
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            action()
        }
    }
}

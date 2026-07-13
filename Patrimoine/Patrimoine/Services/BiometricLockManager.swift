import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class BiometricLockManager {
    private(set) var isUnlocked = false
    private(set) var isAuthenticating = false
    private(set) var lastError: String?

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            if !newValue { isUnlocked = true }
        }
    }

    private static let enabledKey = "patrimoine.biometric.enabled"

    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .none
        }
    }

    var isAvailable: Bool {
        biometricType != .none
    }

    func lock() {
        guard isEnabled else {
            isUnlocked = true
            return
        }
        isUnlocked = false
    }

    func unlockIfNeeded() async {
        guard isEnabled else {
            isUnlocked = true
            return
        }
        guard !isUnlocked else { return }
        await authenticate()
    }

    func authenticate() async {
        guard isEnabled else {
            isUnlocked = true
            return
        }

        isAuthenticating = true
        lastError = nil
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Annuler"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Déverrouillez Patrimoine pour accéder à vos comptes."
            )
            isUnlocked = success
            if !success {
                lastError = "Authentification échouée."
            }
        } catch {
            lastError = error.localizedDescription
            isUnlocked = false
        }
    }
}

enum BiometricType {
    case faceID, touchID, opticID, none

    var label: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Code"
        }
    }

    var icon: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        }
    }
}

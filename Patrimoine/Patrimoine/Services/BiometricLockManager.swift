import Foundation
import LocalAuthentication
import Observation

@MainActor
@Observable
final class BiometricLockManager {
    private(set) var isUnlocked = true
    private(set) var isAuthenticating = false
    private(set) var lastError: String?

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            isUnlocked = true
            if newValue {
                hasUnlockedOnce = true
            }
        }
    }

    private static let enabledKey = "patrimoine.biometric.enabled"
    private var hasUnlockedOnce = false

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
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func lock() {
        guard isEnabled, hasUnlockedOnce else { return }
        isUnlocked = false
    }

    func authenticate() async {
        guard isEnabled else {
            isUnlocked = true
            return
        }

        guard isAvailable else {
            isUnlocked = true
            isEnabled = false
            return
        }

        isAuthenticating = true
        lastError = nil
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Annuler"

        let policy: LAPolicy = biometricType != .none
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: "Déverrouillez Patrimoine pour accéder à vos comptes."
            )
            isUnlocked = success
            if success {
                hasUnlockedOnce = true
            } else {
                lastError = "Authentification échouée."
            }
        } catch let error as LAError where error.code == .userCancel || error.code == .systemCancel {
            isUnlocked = false
            lastError = nil
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

import SwiftUI

struct LockScreenView: View {
    let biometricType: BiometricType
    let isAuthenticating: Bool
    let errorMessage: String?
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.accent)

                VStack(spacing: 8) {
                    Text("Patrimoine")
                        .font(AppTypography.title())
                    Text("Vos données financières sont protégées.")
                        .font(AppTypography.body())
                        .foregroundStyle(AppColors.secondaryText)
                }

                Button(action: onUnlock) {
                    HStack(spacing: 10) {
                        if isAuthenticating {
                            ProgressView()
                        } else {
                            Image(systemName: biometricType.icon)
                                .font(.title2)
                        }
                        Text(unlockLabel)
                            .font(AppTypography.headline())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppColors.accent)
                    .clipShape(Capsule())
                }
                .disabled(isAuthenticating)

                if let errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.negative)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
    }

    private var unlockLabel: String {
        biometricType == .none ? "Déverrouiller" : "Déverrouiller avec \(biometricType.label)"
    }
}

struct BiometricLockModifier: ViewModifier {
    @Environment(BiometricLockManager.self) private var lockManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var didScheduleLaunchAuth = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if lockManager.isEnabled && !lockManager.isUnlocked {
                LockScreenView(
                    biometricType: lockManager.biometricType,
                    isAuthenticating: lockManager.isAuthenticating,
                    errorMessage: lockManager.lastError
                ) {
                    Task { await lockManager.authenticate() }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: lockManager.isUnlocked)
        .onAppear {
            lockManager.prepareForLaunch()
            scheduleLaunchAuthentication()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                lockManager.lock()
            case .active:
                if lockManager.isEnabled && !lockManager.isUnlocked {
                    Task { await lockManager.authenticate() }
                }
            default:
                break
            }
        }
    }

    private func scheduleLaunchAuthentication() {
        guard !didScheduleLaunchAuth, lockManager.isEnabled else { return }
        didScheduleLaunchAuth = true
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard lockManager.isEnabled else { return }
            lockManager.lock()
            await lockManager.authenticate()
        }
    }
}

extension View {
    func biometricLock() -> some View {
        modifier(BiometricLockModifier())
    }
}

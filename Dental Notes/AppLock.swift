import LocalAuthentication
import Combine
import SwiftUI
import SwiftData

@MainActor
final class AppLockViewModel: ObservableObject {
    @Published private(set) var isUnlocked = false
    @Published private(set) var isAuthenticating = false
    @Published private(set) var errorMessage: String?

    func lock(skipIfAuthenticating: Bool = true) {
        if skipIfAuthenticating && isAuthenticating {
            return
        }

        isUnlocked = false
    }

    func authenticateIfNeeded() {
        guard !isUnlocked else { return }
        authenticate()
    }

    func authenticate() {
        guard !isAuthenticating else { return }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"

        var authError: NSError?
        let canAuthenticate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError)

        guard canAuthenticate else {
            errorMessage = authError?.localizedDescription ?? "Device authentication is not available."
            return
        }

        isAuthenticating = true
        errorMessage = nil

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock My Dental Companion"
        ) { [weak self] success, error in
            Task { [weak self, success, error] in
                guard let self else { return }
                await MainActor.run {
                    self.handleAuthenticationResult(success: success, error: error)
                }
            }
        }
    }

    @MainActor
    private func handleAuthenticationResult(success: Bool, error: Error?) {
        isAuthenticating = false

        if success {
            isUnlocked = true
            errorMessage = nil
            return
        }

        isUnlocked = false

        if let laError = error as? LAError,
           laError.code == .userCancel || laError.code == .systemCancel || laError.code == .appCancel {
            errorMessage = nil
        } else {
            errorMessage = error?.localizedDescription ?? "Authentication failed."
        }
    }
}

struct AppLockGateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var session: AppSessionViewModel
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    @StateObject private var appLock = AppLockViewModel()

    var body: some View {
        Group {
            if appLock.isUnlocked {
                UnlockedRootView()
            } else {
                LockScreenView(
                    isAuthenticating: appLock.isAuthenticating,
                    errorMessage: appLock.errorMessage,
                    onUnlockTapped: appLock.authenticate
                )
            }
        }
        .onAppear {
            navigationCoordinator.restorePendingRouteIfNeeded()
            appLock.authenticateIfNeeded()
        }
        .task {
            await session.bootstrapIfNeeded(modelContext: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                navigationCoordinator.restorePendingRouteIfNeeded()
                appLock.authenticateIfNeeded()
                Task { @MainActor in
                    await session.bootstrapIfNeeded(modelContext: modelContext)
                }
            case .inactive, .background:
                appLock.lock()
            @unknown default:
                appLock.lock()
            }
        }
    }
}

private struct UnlockedRootView: View {
    @EnvironmentObject private var session: AppSessionViewModel
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator

    var body: some View {
        Group {
            if session.mode.isServer && !session.isAuthenticated {
                ServerAuthenticationView()
            } else {
                ContentView()
            }
        }
        .onAppear {
            navigationCoordinator.restorePendingRouteIfNeeded()
        }
    }
}

private struct LockScreenView: View {
    let isAuthenticating: Bool
    let errorMessage: String?
    let onUnlockTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 52))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text("My Dental Companion Locked")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Authenticate with Face ID, Touch ID, or passcode to continue.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                onUnlockTapped()
            } label: {
                if isAuthenticating {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Authenticating…")
                    }
                } else {
                    Text("Unlock")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isAuthenticating)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AppLockGateView()
        .modelContainer(for: [NoteEntity.self, FollowupEntity.self], inMemory: true)
        .environmentObject(AppSessionViewModel())
        .environmentObject(AppNavigationCoordinator())
}

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
            localizedReason: "Unlock Dental Notes"
        ) { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                self.isAuthenticating = false

                if success {
                    self.isUnlocked = true
                    self.errorMessage = nil
                    return
                }

                self.isUnlocked = false

                if let laError = error as? LAError,
                   laError.code == .userCancel || laError.code == .systemCancel || laError.code == .appCancel {
                    self.errorMessage = nil
                } else {
                    self.errorMessage = error?.localizedDescription ?? "Authentication failed."
                }
            }
        }
    }
}

struct AppLockGateView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLock = AppLockViewModel()

    var body: some View {
        Group {
            if appLock.isUnlocked {
                ContentView()
            } else {
                LockScreenView(
                    isAuthenticating: appLock.isAuthenticating,
                    errorMessage: appLock.errorMessage,
                    onUnlockTapped: appLock.authenticate
                )
            }
        }
        .onAppear {
            appLock.authenticateIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                appLock.authenticateIfNeeded()
            case .inactive, .background:
                appLock.lock()
            @unknown default:
                appLock.lock()
            }
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
                Text("Dental Notes Locked")
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
}

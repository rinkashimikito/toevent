import SwiftUI

struct AddAccountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAuthenticating = false
    @State private var error: String?

    let onAccountAdded: (CalendarAccount) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Calendar Account")
                .font(.headline)

            if let error = error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            VStack(spacing: 12) {
                providerButton(for: .google)
                providerButton(for: .outlook)
            }
            .disabled(isAuthenticating)

            if isAuthenticating {
                ProgressView()
            }

            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(20)
        .frame(width: 300)
    }

    private func providerButton(for provider: CalendarProviderType) -> some View {
        Button {
            authenticate(with: provider)
        } label: {
            HStack {
                Image(systemName: provider.symbolName)
                Text(provider.displayName)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private func authenticate(with provider: CalendarProviderType) {
        isAuthenticating = true
        error = nil

        Task { @MainActor in
            do {
                guard let window = NSApp.keyWindow else {
                    throw AuthError.invalidResponse
                }
                let credentials = try await AuthService.shared.startOAuthFlow(
                    for: provider,
                    presentingWindow: window
                )
                let account = CalendarAccount(
                    id: credentials.accountId,
                    providerType: provider,
                    email: "Connected Account",
                    displayName: provider.displayName
                )
                await MainActor.run {
                    onAccountAdded(account)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isAuthenticating = false
                }
            }
        }
    }
}

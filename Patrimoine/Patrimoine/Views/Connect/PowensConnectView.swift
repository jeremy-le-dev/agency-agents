import AuthenticationServices
import SwiftUI

struct PowensConnectView: UIViewControllerRepresentable {
    let url: URL
    let callbackScheme: String
    let onComplete: (Result<URL, Error>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground
        DispatchQueue.main.async {
            context.coordinator.start(from: controller)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, callbackScheme: callbackScheme, onComplete: onComplete)
    }

    final class Coordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
        private let url: URL
        private let callbackScheme: String
        private let onComplete: (Result<URL, Error>) -> Void
        private var session: ASWebAuthenticationSession?

        init(url: URL, callbackScheme: String, onComplete: @escaping (Result<URL, Error>) -> Void) {
            self.url = url
            self.callbackScheme = callbackScheme
            self.onComplete = onComplete
        }

        func start(from controller: UIViewController) {
            session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                guard let self else { return }
                if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                    self.onComplete(.failure(PowensError.userCancelled))
                    return
                }
                if let error {
                    self.onComplete(.failure(error))
                    return
                }
                if let callbackURL {
                    self.onComplete(.success(callbackURL))
                } else {
                    self.onComplete(.failure(PowensError.invalidResponse))
                }
            }
            session?.presentationContextProvider = self
            session?.prefersEphemeralWebBrowserSession = false
            session?.start()
        }

        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}

struct PowensConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    let connectURL: URL
    let onResult: (Result<Int?, Error>) -> Void

    @State private var powensService = PowensService()

    var body: some View {
        PowensConnectView(
            url: connectURL,
            callbackScheme: "patrimoine"
        ) { result in
            switch result {
            case .success(let url):
                do {
                    let connectionId = try powensService.handleCallback(url: url)
                    onResult(.success(connectionId))
                } catch {
                    onResult(.failure(error))
                }
            case .failure(let error):
                onResult(.failure(error))
            }
            dismiss()
        }
        .ignoresSafeArea()
    }
}

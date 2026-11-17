import AuthenticationServices
import BackgroundTasks
import Foundation
import Security
import SwiftUI
import UIKit

struct DietumAccountSession: Codable, Hashable, Sendable {
    var email: String?
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= .now.addingTimeInterval(60)
    }
}

enum AccountSetupState: Equatable {
    case needsChoice
    case skipped
    case signedIn(email: String?)
    case working
    case failed(String)
}

enum AccountError: Error, Equatable {
    case configurationMissing
    case cancelled
    case invalidCallback
    case authorizationFailed
    case tokenExchangeFailed
    case backupFailed

    var message: String {
        switch self {
        case .configurationMissing:
            return "Google Drive is not configured for this build yet. Add the OAuth client settings first."
        case .cancelled:
            return "Sign-in was cancelled."
        case .invalidCallback:
            return "Google returned an invalid sign-in callback."
        case .authorizationFailed:
            return "Google sign-in could not be completed."
        case .tokenExchangeFailed:
            return "Google sign-in succeeded, but the token could not be stored."
        case .backupFailed:
            return "The weekly backup could not be uploaded to Google Drive."
        }
    }
}

protocol AccountSessionStoring: Sendable {
    func load() -> DietumAccountSession?
    func save(_ session: DietumAccountSession) throws
    func clear()
    var setupWasCompleted: Bool { get }
    func markSetupCompleted()
}

final class KeychainAccountSessionStore: AccountSessionStoring, @unchecked Sendable {
    private let service = "com.kbnawalakha.Dietum.account"
    private let account = "google-drive-session"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var setupWasCompleted: Bool {
        defaults.bool(forKey: "dietum.account.setup-completed")
    }

    func markSetupCompleted() {
        defaults.set(true, forKey: "dietum.account.setup-completed")
    }

    func load() -> DietumAccountSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return try? JSONDecoder().decode(DietumAccountSession.self, from: data)
    }

    func save(_ session: DietumAccountSession) throws {
        let data = try JSONEncoder().encode(session)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let values: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, values as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
                throw AccountError.tokenExchangeFailed
            }
        } else if updateStatus != errSecSuccess {
            throw AccountError.tokenExchangeFailed
        }
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct GoogleDriveConfiguration: Sendable {
    let clientID: String
    let redirectURI: String

    init(info: [String: Any] = Bundle.main.infoDictionary ?? [:]) {
        clientID = info["GoogleOAuthClientID"] as? String ?? ""
        redirectURI = info["GoogleOAuthRedirectURI"] as? String ?? ""
    }

    var isConfigured: Bool {
        isRealValue(clientID) && isRealValue(redirectURI) && callbackScheme != nil
    }

    var callbackScheme: String? {
        URL(string: redirectURI)?.scheme
    }

    private func isRealValue(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("$(")
    }
}

@MainActor
final class GoogleDriveAccountService: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let configuration: GoogleDriveConfiguration
    private var authenticationSession: ASWebAuthenticationSession?

    init(configuration: GoogleDriveConfiguration = GoogleDriveConfiguration()) {
        self.configuration = configuration
    }

    func signIn() async throws -> DietumAccountSession {
        guard configuration.isConfigured, let callbackScheme = configuration.callbackScheme else {
            throw AccountError.configurationMissing
        }

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile https://www.googleapis.com/auth/drive.appdata"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let authorizationURL = components?.url else {
            throw AccountError.configurationMissing
        }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: callbackScheme
            ) { [weak self] url, error in
                self?.authenticationSession = nil
                if let error {
                    continuation.resume(throwing: (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue ? AccountError.cancelled : AccountError.authorizationFailed)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AccountError.invalidCallback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.authenticationSession = session
            guard session.start() else {
                self.authenticationSession = nil
                continuation.resume(throwing: AccountError.authorizationFailed)
                return
            }
        }

        guard let callbackComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = callbackComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AccountError.invalidCallback
        }

        return try await exchange(code: code)
    }

    func uploadBackup(session: DietumAccountSession, data: Data) async throws -> DietumAccountSession {
        var activeSession = session
        if activeSession.isExpired, let refreshToken = activeSession.refreshToken {
            activeSession = try await refreshAccessToken(refreshToken: refreshToken, session: activeSession)
        }

        let boundary = "DietumBoundary-\(UUID().uuidString)"
        let metadata = "{\"name\":\"dietum-weekly-backup-\(Self.fileDate.string(from: .now)).json\",\"parents\":[\"appDataFolder\"]}"
        var body = Data()
        body.append(Data("--\(boundary)\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n\(metadata)\r\n".utf8))
        body.append(Data("--\(boundary)\r\nContent-Type: application/json\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))

        var request = URLRequest(url: URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("Bearer \(activeSession.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AccountError.backupFailed
        }
        return activeSession
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    private func exchange(code: String) async throws -> DietumAccountSession {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncoded([
            "code": code,
            "client_id": configuration.clientID,
            "redirect_uri": configuration.redirectURI,
            "grant_type": "authorization_code"
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AccountError.tokenExchangeFailed
        }

        let token = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        return DietumAccountSession(
            email: nil,
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: token.expiresIn.map { .now.addingTimeInterval(TimeInterval($0)) }
        )
    }

    private func refreshAccessToken(refreshToken: String, session: DietumAccountSession) async throws -> DietumAccountSession {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncoded([
            "client_id": configuration.clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AccountError.tokenExchangeFailed
        }

        let token = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        return DietumAccountSession(
            email: session.email,
            accessToken: token.accessToken,
            refreshToken: token.refreshToken ?? refreshToken,
            expiresAt: token.expiresIn.map { .now.addingTimeInterval(TimeInterval($0)) }
        )
    }

    private func formEncoded(_ values: [String: String]) -> Data {
        values
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()
    }

    private struct GoogleTokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }
    }

    private static let fileDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()
}

@MainActor
final class AccountViewModel: ObservableObject {
    @Published private(set) var state: AccountSetupState
    @Published private(set) var lastBackupDate: Date?

    private let sessionStore: any AccountSessionStoring
    private let accountService: GoogleDriveAccountService
    private let snapshotProvider: any MealExportSnapshotProviding

    init(
        sessionStore: any AccountSessionStoring = KeychainAccountSessionStore(),
        accountService: GoogleDriveAccountService = GoogleDriveAccountService(),
        snapshotProvider: any MealExportSnapshotProviding = SwiftDataMealExportSnapshotProvider()
    ) {
        self.sessionStore = sessionStore
        self.accountService = accountService
        self.snapshotProvider = snapshotProvider
        if let session = sessionStore.load() {
            state = .signedIn(email: session.email)
        } else if sessionStore.setupWasCompleted {
            state = .skipped
        } else {
            state = .needsChoice
        }
    }

    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    var configurationMessage: String {
        GoogleDriveConfiguration().isConfigured
            ? "Sign in to authorize private app-data backups in Google Drive."
            : "Add GoogleOAuthClientID and GoogleOAuthRedirectURI to enable sign-in for this build."
    }

    func skipLogin() {
        sessionStore.markSetupCompleted()
        state = .skipped
    }

    func signIn() async {
        state = .working
        do {
            let session = try await accountService.signIn()
            try sessionStore.save(session)
            sessionStore.markSetupCompleted()
            WeeklyBackupScheduler.schedule()
            state = .signedIn(email: session.email)
        } catch let error as AccountError {
            state = .failed(error.message)
        } catch {
            state = .failed(AccountError.authorizationFailed.message)
        }
    }

    func backupNow() async {
        state = .working
        if await performScheduledBackup() {
            lastBackupDate = .now
            state = .signedIn(email: sessionStore.load()?.email)
        } else {
            state = .failed(AccountError.backupFailed.message)
        }
    }

    func performScheduledBackup() async -> Bool {
        guard let session = sessionStore.load() else { return false }

        do {
            let snapshot = try await snapshotProvider.loadSnapshot()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            let refreshedSession = try await accountService.uploadBackup(session: session, data: data)
            try sessionStore.save(refreshedSession)
            WeeklyBackupScheduler.schedule()
            return true
        } catch {
            return false
        }
    }

    func signOut() {
        sessionStore.clear()
        sessionStore.markSetupCompleted()
        state = .skipped
    }
}

struct AccountView: View {
    @StateObject private var viewModel: AccountViewModel
    private let onComplete: () -> Void

    init(viewModel: AccountViewModel, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    AppHeroCard(
                        eyebrow: "Optional account",
                        title: "Keep Dietum local, or add a private weekly backup.",
                        message: "You can skip sign-in and use Dietum entirely on this device. Sign-in only enables private app-data backups in your Google Drive."
                    )

                    AppSurfaceCard {
                        VStack(alignment: .leading, spacing: AppSpacing.item) {
                            Text(viewModel.configurationMessage)
                                .font(.subheadline)
                                .foregroundStyle(AppPalette.textSecondary)

                            if case .failed(let message) = viewModel.state {
                                Text(message)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.red)
                            }

                            Button {
                                Task { await viewModel.signIn() }
                            } label: {
                                Label("Continue with Google", systemImage: "person.crop.circle.badge.checkmark")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.appProminent)
                            .disabled(viewModel.state == .working)

                            Button("Skip for now") {
                                viewModel.skipLogin()
                                onComplete()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .disabled(viewModel.state == .working)
                        }
                    }

                    if viewModel.isSignedIn {
                        AppSurfaceCard {
                            VStack(alignment: .leading, spacing: AppSpacing.item) {
                                AppSectionHeader(
                                    title: "Weekly backup",
                                    message: "Backups use Drive's private app-data area and are only uploaded after you authorize Google."
                                )

                                Button {
                                    Task { await viewModel.backupNow() }
                                } label: {
                                    Label("Back up now", systemImage: "icloud.and.arrow.up")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.appProminent)
                                .disabled(viewModel.state == .working)

                                Button("Sign out and keep local data") {
                                    viewModel.signOut()
                                }
                                .frame(maxWidth: .infinity, alignment: .center)

                                Button("Continue to Dietum") {
                                    onComplete()
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.vertical, AppSpacing.screen)
            }
            .navigationTitle("Account & Backup")
            .appScreenBackground()
        }
    }
}

enum WeeklyBackupScheduler {
    static let taskIdentifier = "com.kbnawalakha.Dietum.weekly-backup"

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }
}

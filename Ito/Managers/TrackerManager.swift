import Combine
import Foundation
import AuthenticationServices

public class TrackerManager: ObservableObject {
    public static let shared = TrackerManager()
    
    @Published public private(set) var anilistToken: String? = nil
    @Published public private(set) var anilistUsername: String? = nil
    
    private let tokenKey = "anilist_access_token"
    private let usernameKey = "anilist_username"
    
    // Replace this with your actual AniList Client ID
    private let clientId = "36931"
    // The custom scheme configured in Info.plist (e.g., ito://anilist-auth)
    private let callbackScheme = "ito"
    
    private init() {
        self.anilistToken = UserDefaults.standard.string(forKey: tokenKey)
        self.anilistUsername = UserDefaults.standard.string(forKey: usernameKey)
    }
    
    public var isAnilistAuthenticated: Bool {
        return anilistToken != nil
    }
    
    @MainActor
    public func authenticateWithAnilist() async throws {
        let authURLString = "https://anilist.co/api/v2/oauth/authorize?client_id=\(clientId)&response_type=token"
        guard let url = URL(string: authURLString) else {
            throw URLError(.badURL)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                
                // AniList implicit grant returns the token in the URL fragment:
                // ito://anilist-auth#access_token=...&token_type=Bearer&expires_in=31536000
                guard let fragment = callbackURL.fragment else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }
                
                let params = fragment.components(separatedBy: "&").reduce(into: [String: String]()) { result, param in
                    let pair = param.components(separatedBy: "=")
                    if pair.count == 2 {
                        result[pair[0]] = pair[1]
                    }
                }
                
                guard let token = params["access_token"] else {
                    continuation.resume(throwing: URLError(.userAuthenticationRequired))
                    return
                }
                
                DispatchQueue.main.async {
                    self.anilistToken = token
                    UserDefaults.standard.set(token, forKey: self.tokenKey)
                }
                
                // Fetch the username
                Task {
                    do {
                        try await self.fetchAnilistViewer(token: token)
                    } catch {
                        print("Failed to fetch viewer: \(error)")
                    }
                }
                
                continuation.resume()
            }
            
            session.presentationContextProvider = AuthPresentationContext.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    public func logoutAnilist() {
        self.anilistToken = nil
        self.anilistUsername = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
    }
    
    private func fetchAnilistViewer(token: String) async throws {
        let query = """
        query {
            Viewer {
                name
            }
        }
        """
        
        let body: [String: Any] = ["query": query]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataDict = json["data"] as? [String: Any],
           let viewer = dataDict["Viewer"] as? [String: Any],
           let name = viewer["name"] as? String {
            
            await MainActor.run {
                self.anilistUsername = name
                UserDefaults.standard.set(name, forKey: self.usernameKey)
            }
        } else {
            throw URLError(.cannotParseResponse)
        }
    }
}

class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationContext()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Fallback for getting the key window
        return UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first ?? ASPresentationAnchor()
    }
}

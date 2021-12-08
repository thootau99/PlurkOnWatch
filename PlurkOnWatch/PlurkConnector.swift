import Foundation
import OAuthSwift
import KeychainAccess
import DotEnv

struct PlurkPost : Codable, Hashable {
    var owner_id : Int?
    var user_id : Int?
    var content : String?
    var display_name : String?
    var plurk_id : Int?
}

struct GetPlurkResponse : Codable {
    var plurks: [PlurkPost]
}

class PlurkConnector_Phone : ObservableObject {
    @Published var loginSuccess = false
    @Published var plurks : GetPlurkResponse = GetPlurkResponse(plurks: [])
    let _OAuthSwift : OAuth1Swift
    init() {
        do {
            var fileURL: String = ""
            if let url = Bundle.main.url(forResource: ".env", withExtension: "") {
                fileURL = url.absoluteString
                fileURL = fileURL.replacingOccurrences(of: "file://", with: "")
            }
            let env = try DotEnv.read(path: fileURL)
            env.load()
        } catch {
            print("read env error \(error)")
        }
        
        if let consumerKey = ProcessInfo.processInfo.environment["CONSUMER_KEY"],
           let consumerSecret = ProcessInfo.processInfo.environment["CONSUMER_SECRET"] {
            self._OAuthSwift = OAuth1Swift(
                consumerKey:    consumerKey,
                consumerSecret: consumerSecret,
                requestTokenUrl: "https://www.plurk.com/OAuth/request_token",
                authorizeUrl:    "https://www.plurk.com/m/authorize",
                accessTokenUrl:  "https://www.plurk.com/OAuth/access_token"
            )
            let keychain = Keychain(service: "org.thootau.plurkwatch")
            guard let token = try? keychain.get("oauthToken"),
                  let tokenSecret = try? keychain.get("oauthTokenSecret") else { return }
            self._OAuthSwift.client.credential.oauthToken = token
            self._OAuthSwift.client.credential.oauthTokenSecret = tokenSecret
            testToken() { fail in
                if fail {
                    self._OAuthSwift.client.credential.oauthToken = ""
                    self._OAuthSwift.client.credential.oauthTokenSecret = ""
                    keychain["oauthToken"] = ""
                    keychain["oauthTokenSecret"] = ""
                } else {
                    self.loginSuccess = true
                }
            }
        } else {
            // if .env not exist, fall here
            self._OAuthSwift = OAuth1Swift(
                consumerKey:    "",
                consumerSecret: "",
                requestTokenUrl: "https://www.plurk.com/OAuth/request_token",
                authorizeUrl:    "https://www.plurk.com/m/authorize",
                accessTokenUrl:  "https://www.plurk.com/OAuth/access_token"
            )
        }
    }
    
    func testToken(fail: @escaping (Bool) -> ()) {
        let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Profile/getOwnProfile") {(result) in
            switch result {
            case .success( _):
                    fail(false)
            case .failure(_):
                    fail(true)
            }
        }
    }
    
    func login(completion: @escaping () -> ()) throws {
        let keychain = Keychain(service: "org.thootau.plurkwatch")
        guard let token = try? keychain.get("oauthToken"),
              let tokenSecret = try? keychain.get("oauthTokenSecret") else {
              _OAuthSwift.authorize(
                withCallbackURL: "watch-plurk://oauth-callback/plurk") { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        self.loginSuccess = true
                        self._OAuthSwift.client.credential.oauthToken = credential.oauthToken
                        self._OAuthSwift.client.credential.oauthTokenSecret = credential.oauthTokenSecret
                        keychain["oauthToken"] = credential.oauthToken as String
                        keychain["oauthTokenSecret"] = credential.oauthTokenSecret as String
                        self.loginSuccess = true
                        _ = completion()
                        
                        
                    case .failure(let error):
                      print(error.localizedDescription)
                    }
                }
            return
        }
        self._OAuthSwift.client.credential.oauthToken = token
        self._OAuthSwift.client.credential.oauthTokenSecret = tokenSecret
        testToken() { fail in
            if fail {
                self._OAuthSwift.client.credential.oauthToken = ""
                self._OAuthSwift.client.credential.oauthTokenSecret = ""
                keychain["oauthToken"] = ""
                keychain["oauthTokenSecret"] = ""
                self._OAuthSwift.authorize(
                  withCallbackURL: "watch-plurk://oauth-callback/plurk") { result in
                      switch result {
                      case .success(let (credential, _, _)):
                          self.loginSuccess = true
                          self._OAuthSwift.client.credential.oauthToken = credential.oauthToken
                          self._OAuthSwift.client.credential.oauthTokenSecret = credential.oauthTokenSecret
                          keychain["oauthToken"] = credential.oauthToken as String
                          keychain["oauthTokenSecret"] = credential.oauthTokenSecret as String
                          self.loginSuccess = true
                          _ = completion()
                          
                          
                      case .failure(let error):
                        print(error.localizedDescription)
                      }
                  }
            } else {
                self.loginSuccess = true
                _ = completion()
            }
        }
        
    }
}




import Foundation
import OAuthSwift
import SwiftSoup
import KeychainAccess
import DotEnv

struct Profile: Codable, Hashable {
    var avatar_medium : String?
    var about : String?
    var display_name : String?
    var nick_name : String?
}

struct ProfileResponse: Codable, Hashable {
    var fans_count: Int?
    var friends_count: Int?
    var user_info: Profile
}

struct PlurkPost : Codable, Hashable {
    var owner_id : Int
    var user_id : Int?
    var content : String?
    var display_name: String?
    var response_count: Int?
    var plurk_id : Int?
}

struct PlurkUser : Codable, Hashable {
    var id : Int?
    var display_name: String?
}


struct GetPlurkResponse : Codable {
    var plurks: [PlurkPost]
    var plurk_users: [String: PlurkUser]
}

struct Response: Codable, Hashable {
    var user_id : Int
    var content : String?
    var display_name: String?
    var response_count: Int?
    var plurk_id : Int?
}

struct GetResponse: Codable {
    var responses: [Response]
    var friends: [String: PlurkUser]
}


class PlurkConnector : ObservableObject {
    @Published var loginSuccess = false
    @Published var plurks : GetPlurkResponse = GetPlurkResponse(plurks: [], plurk_users: [:])
    @Published var plurk_response : GetResponse = GetResponse(responses: [], friends: [:])

    @Published var me : ProfileResponse = ProfileResponse(fans_count: 0, friends_count: 0, user_info: Profile())
    let _OAuthSwift : OAuth1Swift
    init() {
        do {
            var fileURL: String = ""
            if let url = Bundle.main.url(forResource: ".env", withExtension: "") {
                fileURL = url.absoluteString
                fileURL = fileURL.replacingOccurrences(of: "file://", with: "")
                fileURL = fileURL.replacingOccurrences(of: "%20", with: " ")
            }
            print(fileURL)
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
    
    func login(token: String, tokenSecret: String) {
        self._OAuthSwift.client.credential.oauthToken = token
        self._OAuthSwift.client.credential.oauthTokenSecret = tokenSecret
        let keychain = Keychain(service: "org.thootau.plurkwatch")
        keychain["oauthToken"] = self._OAuthSwift.client.credential.oauthToken
        keychain["oauthTokenSecret"] = self._OAuthSwift.client.credential.oauthTokenSecret
        loginSuccess = true
        return
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
    
    
    func getMyProfile() {
        let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Profile/getOwnProfile") {(result) in
            switch result {
                case .success(let response):
                    let decoder = JSONDecoder()
                    do {
                        let data = response.string?.data(using: .utf8)
                        let meResult = try decoder.decode(ProfileResponse.self, from: data!)
                        self.me = meResult
                    } catch {
                        print("ERROR IN JSON PARSING")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    func getPlurks() {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date()).ISO8601Format()
        let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Timeline/getPlurks", parameters: [:]) {(result) in
            switch result {
                case .success(let response):
                    let decoder = JSONDecoder()
                    do {
                        let data = response.string?.data(using: .utf8)
                        var plurkResult = try decoder.decode(GetPlurkResponse.self, from: data!)
                        var plurkExecuted: [PlurkPost] = []
                        
                        
                        for var plurk in plurkResult.plurks {
                            // なまえをだいにゅうする
                            plurk.display_name = plurkResult.plurk_users["\(plurk.owner_id)"]?.display_name
                        
                            do {
                                let contentParsed = try SwiftSoup.parse(plurk.content ?? "")
                                plurk.content = try contentParsed.text()
                            }
                            print(plurk)
                            plurkExecuted.append(plurk)
                        }
                        plurkResult.plurks = plurkExecuted
                        self.plurks = plurkResult
                    } catch {
                        print("ERROR IN JSON PARSING")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    func getMyPlurks() {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date()).ISO8601Format()
        let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Timeline/getPlurks", parameters: ["filter": "my"]) {(result) in
            switch result {
                case .success(let response):
                    let decoder = JSONDecoder()
                    do {
                        let data = response.string?.data(using: .utf8)
                        var plurkResult = try decoder.decode(GetPlurkResponse.self, from: data!)
                        var plurkExecuted: [PlurkPost] = []
                        
                        
                        for var plurk in plurkResult.plurks {
                            // なまえをだいにゅうする
                            plurk.display_name = plurkResult.plurk_users["\(plurk.owner_id)"]?.display_name
                            
                            do {
                                let contentParsed = try SwiftSoup.parse(plurk.content ?? "")
                                plurk.content = try contentParsed.text()
                            }
                            plurkExecuted.append(plurk)
                        }
                        plurkResult.plurks = plurkExecuted
                        self.plurks = plurkResult
                    } catch {
                        print("ERROR IN JSON PARSING")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    func getPlurkResponses(plurk_id: Int) {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date()).ISO8601Format()
        let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Responses/getById", parameters: ["plurk_id": String(plurk_id)]) {(result) in
            switch result {
                case .success(let response):
                    let decoder = JSONDecoder()
                    do {
                        let data = response.string?.data(using: .utf8)
                        var plurkResult = try decoder.decode(GetResponse.self, from: data!)
                        var plurkExecuted: [Response] = []
                        
                        
                        for var plurk in plurkResult.responses {
                            // なまえをだいにゅうする
                            plurk.display_name = plurkResult.friends["\(plurk.user_id)"]?.display_name
                            
                            do {
                                let contentParsed = try SwiftSoup.parse(plurk.content ?? "")
                                plurk.content = try contentParsed.text()
                            }
                            plurkExecuted.append(plurk)
                        }
                        plurkResult.responses = plurkExecuted
                        print(plurkResult)
                        self.plurk_response = plurkResult
                    } catch {
                        print("ERROR IN JSON PARSING")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    func postPlurk(plurk_id : Int?, content: String, qualifier: String) {
        guard let checkPlurkId : Int = plurk_id else {
            let _ = _OAuthSwift.client.post("https://www.plurk.com/APP/Timeline/plurkAdd", parameters: ["content": content, "qualifier": qualifier]) {result in
                switch result {
                    case .success(let response):
                        print(response.string as Any)
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
            return
        }
        let _ = _OAuthSwift.client.post("https://www.plurk.com/APP/Responses/responseAdd", parameters: ["plurk_id": checkPlurkId, "content": content, "qualifier": qualifier]) {result in
            switch result {
                case .success(let response):
                    print(response.string as Any)
                    
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
    
    func logout() {
        let keychain = Keychain(service: "org.thootau.plurkwatch")
        self._OAuthSwift.client.credential.oauthToken = ""
        self._OAuthSwift.client.credential.oauthTokenSecret = ""
        keychain["oauthToken"] = ""
        keychain["oauthTokenSecret"] = ""
        self.loginSuccess = false
    }
    
}




import Foundation
import OAuthSwift
import SwiftSoup
import KeychainAccess
import DotEnv
import PromiseKit

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

struct PlurkPost : Codable, Hashable, Identifiable {
    
    let id: UUID = UUID()
    var photos: [String] = []
    
    var owner_id : Int
    var user_id : Int?
    var content : String?
    var display_name: String?
    var response_count: Int?
    var posted: String?
    var plurk_id : Int?
    
    private enum CodingKeys : String, CodingKey { case owner_id, user_id, content, display_name, response_count, posted, plurk_id }
}

struct PlurkUser : Codable, Hashable {
    var id : Int?
    var display_name: String?
}


struct GetPlurkResponse : Codable, Hashable {
    
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
    @Published var lastPlurkTime: String = ""
    @Published var plurks: GetPlurkResponse = GetPlurkResponse(plurks: [], plurk_users: [:])
    let dateFormatter = DateFormatter()
    let _OAuthSwift : OAuth1Swift
    init() {
        self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
        do {
            var fileURL: String = ""
            if let url = Bundle.main.url(forResource: ".env", withExtension: "") {
                fileURL = url.absoluteString
                fileURL = fileURL.replacingOccurrences(of: "file://", with: "")
                fileURL = fileURL.replacingOccurrences(of: "%20", with: " ")
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
    func getMyProfile() -> Promise<ProfileResponse> {
        return Promise<ProfileResponse> { seal in
            var me : ProfileResponse = ProfileResponse(fans_count: 0, friends_count: 0, user_info: Profile())
            let _ = _OAuthSwift.client.get("https://www.plurk.com/APP/Profile/getOwnProfile") {(result) in
                switch result {
                    case .success(let response):
                        let decoder = JSONDecoder()
                        do {
                            let data = response.string?.data(using: .utf8)
                            let meResult = try decoder.decode(ProfileResponse.self, from: data!)
                            seal.fulfill(meResult)
                        } catch {
                            print("ERROR IN JSON PARSING")
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }
    }
    
    func getPlurks(me: Bool) -> Promise<GetPlurkResponse> {
        return Promise<GetPlurkResponse> { seal in
            var parameters = OAuthSwift.Parameters()
            if me {
                parameters["filter"] = "me"
            }
            parameters["offset"] = lastPlurkTime.isEmpty ? "" : lastPlurkTime
            self._OAuthSwift.client.get("https://www.plurk.com/APP/Timeline/getPlurks", parameters: parameters) {(result) in
                    switch result {
                        case .success(let response):
                            let decoder = JSONDecoder()
                            do {
                                let data = response.string?.data(using: .utf8)
                                var plurkResult = try decoder.decode(GetPlurkResponse.self, from: data!)
                                var plurkExecuted: [PlurkPost] = []
                                for var (index, plurk) in plurkResult.plurks.enumerated() {
                                    // なまえをだいにゅうする
                                    plurk.display_name = plurkResult.plurk_users["\(plurk.owner_id)"]?.display_name
                                    
                                    do {
                                        let contentParsed = try SwiftSoup.parse(plurk.content ?? "")
                                        plurk.content = try contentParsed.text()
                                        for imageLink: Element in try contentParsed.select("img").array() {
                                            let imageSrc: String = try imageLink.attr("src")
                                            plurk.photos.append(imageSrc)
                                        }
                                    }
                                    plurkExecuted.append(plurk)
                                    if index == plurkResult.plurks.count - 1 {
                                        if let time = plurk.posted {
                                            let date = self.dateFormatter.date(from: time)
                                            if let ISO8601Date = date?.ISO8601Format() {
                                                self.lastPlurkTime = ISO8601Date
                                            }
                                        }
                                    }
                                }
                                plurkResult.plurks = plurkExecuted
                                self.plurks.plurks += plurkExecuted
                                seal.fulfill(self.plurks)
                                print("got!")
                            } catch {
                                print("ERROR IN JSON PARSING")
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                    }
                }
            }
    }
    
    func getPlurkResponses(plurk_id: Int) -> Promise<GetResponse> {
        return Promise<GetResponse> {seal in
            var plurkResponse : GetResponse = GetResponse(responses: [], friends: [:])

            self._OAuthSwift.client.get("https://www.plurk.com/APP/Responses/getById", parameters: ["plurk_id": String(plurk_id)]) {(result) in
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
                            seal.fulfill(plurkResult)
                        } catch {
                            print("ERROR IN JSON PARSING")
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
        }

    }
    
    func postPlurk(plurk_id : Int?, content: String, qualifier: String) {
        guard let checkPlurkId : Int = plurk_id else {
            let _ = self._OAuthSwift.client.post("https://www.plurk.com/APP/Timeline/plurkAdd", parameters: ["content": content, "qualifier": qualifier]) {result in
                switch result {
                    case .success(let response):
                        print(response.string as Any)
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }
            return
        }
        let _ = self._OAuthSwift.client.post("https://www.plurk.com/APP/Responses/responseAdd", parameters: ["plurk_id": checkPlurkId, "content": content, "qualifier": qualifier]) {result in
            
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




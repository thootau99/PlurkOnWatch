import WatchConnectivity
import SwiftUI
import KeychainAccess

class PhoneConnector: NSObject, ObservableObject, WCSessionDelegate {
    @Published var oauthToken: String = ""
    @Published var oauthTokenSecret: String = ""
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        let keychain = Keychain(service: "org.thootau.plurkwatch")
        guard let token = try? keychain.get("oauthToken"),
              let tokenSecret = try? keychain.get("oauthTokenSecret") else { return }
        oauthToken = token
        oauthToken = tokenSecret
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith state= \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("didReceiveMessage: \(message)")
        
        DispatchQueue.main.async {
            guard let token = message["oauthToken"] else {
                return
            }
            print(message)
            let tokenSplit = "\(token)".split(separator: ",")
            self.oauthToken = String(tokenSplit[0])
            self.oauthTokenSecret = String(tokenSplit[1])
        }
    }
    
    func cleanOauthToken() {
        self.oauthToken = ""
        self.oauthTokenSecret = ""
    }
    
    func send() {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["PHONE_COUNT": 0], replyHandler: nil) { error in
                print(error)
            }
        }
    }
    
    
}

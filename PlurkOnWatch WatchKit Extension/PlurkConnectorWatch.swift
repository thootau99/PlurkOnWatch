import Foundation
import OAuthSwift
import SwiftSoup
import KeychainAccess
import DotEnv

class PlurkConnectorWatch : PlurkConnector  {
    func login(token: String, tokenSecret: String) {
        self._OAuthSwift.client.credential.oauthToken = token
        self._OAuthSwift.client.credential.oauthTokenSecret = tokenSecret
        let keychain = Keychain(service: "org.thootau.plurkwatch")
        keychain["oauthToken"] = self._OAuthSwift.client.credential.oauthToken
        keychain["oauthTokenSecret"] = self._OAuthSwift.client.credential.oauthTokenSecret
        loginSuccess = true
        return
    }
}




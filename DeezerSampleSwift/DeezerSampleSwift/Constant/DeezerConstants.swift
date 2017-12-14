import Foundation

typealias DeezerObjectListRequest = (_ objectList: DZRObjectList? ,_ error: Error?) -> Void

struct DeezerConstant {

    // Key saved in Keychain
    struct KeyChain {
       static let deezerTokenKey = "DeezerTokenKey"
       static let deezerExpirationDateKey = "DeezerExpirationDateKey"
       static let deezerUserIdKey = "DeezerUserIdKey"
    }
    
    struct AppKey {
        //CHANGE THE VALUE WITH YOUR APP ID
        static let appId = "100041"
    }
    
}

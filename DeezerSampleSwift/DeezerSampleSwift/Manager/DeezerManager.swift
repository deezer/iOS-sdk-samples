import Foundation
import UIKit

typealias LoginResult = ((_ result: ResultLogin) -> ())

// MARK: - DeezerManager manages the request to DeezerSDK

class DeezerManager: NSObject {
    
    // Needed to handle every types of request from DeezerSDK
    var deezerConnect: DeezerConnect?

    // .diconnected / .connected
    var sessionState: SessionState {
        if let connect = deezerConnect {
            return connect.isSessionValid() ? .connected : .disconnected
        }
        return .disconnected
    }
    
    // Set a function or callback to this property if you want to get the result after login
    var loginResult: LoginResult?
    
    static let sharedInstance : DeezerManager = {
        let instance = DeezerManager()
        instance.startDeezer()
        return instance
    }()
    
    func startDeezer() {
        deezerConnect = DeezerConnect.init(appId: DeezerConstant.AppKey.appId, andDelegate: self)
        DZRRequestManager.default().dzrConnect = deezerConnect
        self.retrieveTokenAndExpirationDate()
    }
    
    
    /**
     *   Authorizations:
     *      - DeezerConnectPermissionBasicAccess
     *      - DeezerConnectPermissionEmail
     *      - DeezerConnectPermissionOfflineAccess
     *      - DeezerConnectPermissionManageLibrary
     *      - DeezerConnectPermissionDeleteLibrary
     *      - DeezerConnectPermissionListeningHistory
     **/
    
    func login() {
        deezerConnect?.authorize([DeezerConnectPermissionBasicAccess])
    }
    
    func logout() {
        deezerConnect?.logout()
    }
}

// MARK: - Token Handler inside the Keychain because it's sensitive data

extension DeezerManager {
    
    private func save(token: String, expirationDate: Date, userId: String) {
        _ = KeyChainManager.save(key: DeezerConstant.KeyChain.deezerTokenKey, data: token.data)
        _ = KeyChainManager.save(key: DeezerConstant.KeyChain.deezerExpirationDateKey, data: expirationDate.timeIntervalSince1970.data)
        _ = KeyChainManager.save(key: DeezerConstant.KeyChain.deezerUserIdKey, data: userId.data)
    }
    
    private func retrieveTokenAndExpirationDate() {
        if let accessToken = String(data: KeyChainManager.load(key: DeezerConstant.KeyChain.deezerTokenKey) ?? Data()),
            let expirationDate = Double(data: KeyChainManager.load(key: DeezerConstant.KeyChain.deezerExpirationDateKey) ?? Data()),
            let userId = String(data: KeyChainManager.load(key: DeezerConstant.KeyChain.deezerUserIdKey) ?? Data()),
            let deezerConnect = deezerConnect {
            deezerConnect.accessToken = accessToken
            deezerConnect.expirationDate = Date(timeIntervalSince1970: expirationDate)
            deezerConnect.userId = userId
        }
    }
    
    private func clearTokenAndExpirationDate() {
        KeyChainManager.delete(key: DeezerConstant.KeyChain.deezerUserIdKey)
        KeyChainManager.delete(key: DeezerConstant.KeyChain.deezerTokenKey)
        KeyChainManager.delete(key: DeezerConstant.KeyChain.deezerExpirationDateKey)
    }
}

// MARK: - DeezerSessionDelegate Methods

extension DeezerManager: DeezerSessionDelegate {
    
    func deezerDidLogin() {
        guard let deezerConnect = deezerConnect else {
            return
        }
        
        save(token: deezerConnect.accessToken, expirationDate: deezerConnect.expirationDate, userId: deezerConnect.userId)
        loginResult?(.success)
    }
    
    func deezerDidNotLogin(_ cancelled: Bool) {
        let deezerError: Error? = cancelled ? nil : NSError.instance(type: .noConnection)
        loginResult?(.error(error: deezerError))
    }
    
    func deezerDidLogout(){
        clearTokenAndExpirationDate()
        loginResult?(.logout)
    }
}

// MARK: - DZRObjectListData

extension DeezerManager {
    
    /**
     *   Get all objects of an DZRObjectList
     *
     *   - Parameters fromObjectList: the object containing all objects
     *   - Parameters callback: ([Any]?, Error?)
     **/
    
    func getData(fromObjectList: DZRObjectList, callback: @escaping (_ data: [Any]?, _ error: Error?) -> Void) {
        fromObjectList.allObjects(with: DZRRequestManager.default(), callback: callback)
    }
    
    /**
     *   Get a specific object with an identifier
     *
     *   - Parameters identifier: The string corresponding of the query
     *   - Parameters callback: (Any?, Error?)
     **/
    
    func getObject(identifier: String, callback: @escaping (_ object: Any?, _ error: Error?) -> Void) {
        DZRObject.object(withIdentifier: identifier, requestManager: DZRRequestManager.default(), callback: callback)
    }
    
}

// MARK: - DZRUser get data (Playlist / Album etc ...)

extension DeezerManager {
    
    /**
     *    Get object list of corresponding object for example:
     *      Playlist        ->      Tracks
     *      Album           ->      Tracks
     *      Artist          ->      Album
     *      Mix             ->      Tracks
     *
     *    - Parameters object: The object to get the object list
     *    - Parameters callback: The callback of the request DeezerObjectListRequest (DZRObjectList?, Error?)
     *
     **/
    
    func get(object: DZRObject, type: DeezerObjectType, callback: @escaping DeezerObjectListRequest) {
        object.value(forKey: type.rawValue, with: DZRRequestManager.default()) { (value, error) in
            guard let objectList = value as? DZRObjectList else {
                callback(nil, error)
                return
            }
            callback(objectList, nil)
        }
    }
    
    /**
     *   Get the current user connected
     *
     *   - Parameters callback: (DZRUser?, Error?)
     *
     **/
    
    func getMe(callback: @escaping (DZRUser?, Error?) -> ()) {
        DZRUser.object(withIdentifier: "me", requestManager: DZRRequestManager.default(), callback: { (user, error) in
                guard let user = user as? DZRUser else {
                    callback(nil, error)
                    return
                }
                callback(user, error)
            })
    }
}

// MARK: - Search for every kind of data

extension DeezerManager {
    
    /**
     *   Search a DeezerObjectList corresponding to the type and the query. (DZRAlbum / DZRPlaylist / DZRArtist / DZRTrack)
     *
     *   - Parameters type: The type corresponding to the search (default = track)
     *   - Parameters query: The string corresponding of the query
     *   - Parameters completion: The completion of the request DeezerObjectListRequest (DZRObjectList?, Error?)
     **/
    
    func search(type: DZRSearchType = .track, query: String, callback: @escaping DeezerObjectListRequest) {
        DZRObject.search(for: type, withQuery: query, requestManager: DZRRequestManager.default(), callback: callback)
    }
    
}

// MARK: - Track

extension DeezerManager {
    
    /**
     *   Get data of track like the artist / album etc ...
     *
     *   - Parameters track: The track corresponding
     *   - Parameters callback: ([AnyHashable : Any]?, Error?)
     *
     *   Example of the data you can with the corresponding key
     *      DZRPlayableObjectInfoReadable = isReadable
     *      DZRPlayableObjectInfoName = Title
     *      DZRPlayableObjectInfoCreator = Artist Name
     *      DZRPlayableObjectInfoSource = Album Title
     *      DZRPlayableObjectInfoDuration = Duration
     *      DZRPlayableObjectInfoAlternative = Alternative DZRTrack
     *      DZRPlayableObjectInfoAlternativeReadable = isReadable alternative DZRTrack
     **/
 
    func getData(track: DZRTrack, callback: @escaping ([AnyHashable : Any]?, Error?) -> ()) {
        track.playableInfos(with: DZRRequestManager.default()) { (data, error) in
            guard let data = data else {
                callback(nil, error)
                return
            }
            callback(data, nil)
        }
    }
    
    /**
     *   Get illustation of one track
     *
     *   - Parameters track: The track corresponding
     *   - Parameters completion: (UIImage?, Error?)
     **/
    
    func getIllustration(track: DZRTrack, callback: @escaping (UIImage?, Error?) -> ()) {
        track.illustration(with: DZRRequestManager.default(), callback: callback)
    }
    
}

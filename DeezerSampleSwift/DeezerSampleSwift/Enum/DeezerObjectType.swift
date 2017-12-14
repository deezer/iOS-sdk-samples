/**
 *  Enum to handle different kind of Deezer Object
 *  Differents cases possible:
 *      - playlist
 *      - album
 *      - artist
 *      - mix
 *      - track
 *      - all: this property is equals to track
 **/

enum DeezerObjectType : String {
    
    case playlist = "playlists"
    case album = "albums"
    case artist = "artists"
    case mix = "radios"
    case track = "tracks"
    case all = "all"
    
}

extension DeezerObjectType {
    
    /**
     *    Get object list of corresponding object for example:
     *      Playlist        ->      Tracks
     *      Album           ->      Tracks
     *      Artist          ->      Album
     *      Mix             ->      Tracks
     *
     *    - Parameters object: The object to get the object list, if the object is nil we are getting the favoris of the user
     *    - Parameters callback: The callback of the request DeezerObjectListRequest (DZRObjectList?, Error?)
     *
     **/
    
    func getObjectList(object: DZRObject?, callback: @escaping DeezerObjectListRequest) {
        if let object = object {
            DeezerManager.sharedInstance.get(object: object, type: self, callback: callback)
        } else {
            DeezerManager.sharedInstance.getMe(callback: { (user, error) in
                guard let user = user else {
                    callback(nil, error)
                    return
                }
                DeezerManager.sharedInstance.get(object: user, type: self, callback: callback)
            })
        }
    }
    
    /**
     *   Search Object list by string
     *
     *   - Parameters queryText: The string corresponding of the query
     *   - Parameters callback: The callback of the request DeezerObjectListRequest (DZRObjectList?, Error?)
     **/
    
    func searchObjectList(queryText: String, callback: @escaping DeezerObjectListRequest) {
        let type = getSearchType()
        DeezerManager.sharedInstance.search(type: type, query: queryText, callback: callback)
    }
    
    private func getSearchType() -> DZRSearchType {
        switch self {
        case .album:
            return DZRSearchType.album
        case .artist:
            return DZRSearchType.artist
        case .track, .all:
            return DZRSearchType.track
        case .playlist:
            return DZRSearchType.playlist
        case .mix:
            return DZRSearchType.radio
        }
    }
}

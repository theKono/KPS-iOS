//
//  KPSClient.swift
//  KPS
//


import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Moya

typealias NetworkProvider = MoyaProvider<CoreAPIService>



public final class KPSClient: NSObject {
    let apiKey: String
    let appId: String
    
    private let networkProvider: NetworkProvider
    private let customizeEndpoint = { (target: CoreAPIService) -> Endpoint in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        
        guard let sessionToken = KPSClient.sessionToken else {return defaultEndpoint}
        switch target {
        case .login(_, _, _):
            return defaultEndpoint
        default:
            return defaultEndpoint.adding(newHTTPHeaderFields: ["kps_session": sessionToken])
        }
    }
    /// The current user id from the Token.
    public internal(set) var currentUserId: String?

    /// Current session token
    static var sessionToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "kps_session")
        }
        set(newToken) {
            guard let token = newToken else {
                UserDefaults.standard.removeObject(forKey: "kps_session")
                return
            }
            UserDefaults.standard.set(token, forKey: "kps_session")
        }
    }
    
    public var isUserLoggedIn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        }
        
        set (newValue) {
            UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
        }
    }
    
    public weak var mediaContentDelegate: KPSClientMediaContentDelegate?
    
    public weak var analyticDelegate: KPSClientAnalyticDelegate?
    
    public lazy var mediaPlayer: AVQueuePlayer = createDefaultAVPlayer()
    
    internal let commandCenter = MPRemoteCommandCenter.shared()
    internal let nowPlayingCenter = MPNowPlayingInfoCenter.default()
    
    public var isMediaPlaying: Bool = false {
        didSet {
            if oldValue != isMediaPlaying {
                mediaContentDelegate?.kpsClient(client: self, playerIsPlaying: isMediaPlaying)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSCurrentPlayingStateChanged"), object: nil, userInfo: ["isMediaPlaying": isMediaPlaying])
            }
            if var currentInfo = nowPlayingCenter.nowPlayingInfo,
               let currentTime = mediaPlayer.currentItem?.currentTime() {
                currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime.seconds
                currentInfo[MPNowPlayingInfoPropertyPlaybackRate] = isMediaPlaying ? mediaPlayerRate : 0.0
                nowPlayingCenter.nowPlayingInfo = currentInfo
            }
        }
    }
    
    public var mediaPlayerRate: Float = 1.0 {
        didSet {
            if isMediaPlaying {
                mediaPlayer.playImmediately(atRate: mediaPlayerRate)
            }
            if var currentInfo = nowPlayingCenter.nowPlayingInfo,
               let currentTime = mediaPlayer.currentItem?.currentTime() {
                currentInfo[MPNowPlayingInfoPropertyPlaybackRate] = isMediaPlaying ? mediaPlayerRate : 0.0
                currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime.seconds
                nowPlayingCenter.nowPlayingInfo = currentInfo
            }
        }
    }
    
    public var currentTrack: Int = -1 {
        didSet {
            if currentTrack != -1 && currentTrack < mediaPlayList.count {
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSCurrentPlayingTrackUpdated"), object: nil, userInfo: nil)
            } 
            mediaContentDelegate?.kpsClient(client: self, playerCurrentTrack: currentTrack)
        }
    }
    
    public var currentSegment: Int = -1 {
        didSet {
            if self.currentTrack < self.mediaPlayList.count &&
                currentSegment < (self.currentPlayAudioContent?.content.count ?? 0) &&
                oldValue != currentSegment {
                self.mediaContentDelegate?.kpsClient(client: self, playerCurrentSegmentDidChange: currentSegment, paragraph: currentParagraph, highlightRange: currentHighlightRange)
            }
        }
    }


    
    public var currentParagraph: Int = -1 {
        didSet {
            if self.currentTrack < self.mediaPlayList.count &&
                currentParagraph < (self.currentPlayAudioContent?.paragraphContents.count ?? 0) &&
                oldValue != currentParagraph {
                self.mediaContentDelegate?.kpsClient(client: self, playerCurrentParagraphDidChange: currentParagraph, segment: currentSegment, highlightRange: currentHighlightRange)
            }
        }
    }
    
    public var currentHighlightRange: NSRange? {
        didSet {
            if self.currentTrack < self.mediaPlayList.count &&
                currentParagraph < (self.currentPlayAudioContent?.paragraphContents.count ?? 0) &&
                oldValue != currentHighlightRange {
                self.mediaContentDelegate?.kpsClient(client: self, playerHighlightRangeDidChange: currentHighlightRange, paragraph: currentParagraph, segment: currentSegment)
                
            }
        }
    }
    
    public var currentTime: TimeInterval = 0.0 {
        didSet {
            guard let currentItem = self.mediaPlayer.currentItem else {return}
            let duration = currentItem.duration
            
            guard duration.value > 0 && duration.timescale > 0 else {return}
                let totalTime   = TimeInterval(duration.value) / TimeInterval(duration.timescale)
            self.mediaContentDelegate?.kpsClient(client: self, playerPlayTimeDidChange: currentTime, totalTime: totalTime)

            if self.currentPlayRecord != nil && isMediaPlaying == true && currentTime > 0{
                
                let timeIndex: Int = Int(currentTime * 10)
                self.currentPlayRecord!.endTime = currentTime
                self.currentPlayRecord!.addPlayedTimeSlot(timeIndex)
            }
        }
    }
    
    public var currentPlayRecord: KPSPlayRecord?
    
    //MARK: get only variable
    public var isPlayListLoaded: Bool {
        return mediaPlayList.count > 0
    }
    
    public var currentPlayAudioContent: KPSAudioContent? {
        didSet {
            if oldValue?.id != currentPlayAudioContent?.id {
                currentSegment = -1
                currentParagraph = -1
                currentHighlightRange = nil
                mediaContentDelegate?.kpsClient(client: self, playerCurrentContent: currentPlayAudioContent)
                setNowPlayingInfo()
                if currentPlayRecord != nil {
                    
                    uploadPlayedRecord()
                }
                if currentPlayAudioContent != nil && currentPlayAudioContent?.error == nil {
                    currentPlayRecord = KPSPlayRecord(info: currentPlayAudioContent!, rate: mediaPlayerRate)
                } else {
                    
                }
            }
        }
    }
    
    
    internal var mediaPlayerState = MediaPlayerState.nonSetSource {
        didSet {
            if oldValue != mediaPlayerState {
                mediaContentDelegate?.kpsClient(client: self, playerStateDidChange: mediaPlayerState)
            }
        }
    }
    
    internal var mediaPlayList = [KPSContentMeta]() {
        didSet {
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } catch {
                print(error)
            }
        }
    }
    
    internal var mediaPlayCollectionId: String?
    
    internal var mediaPlayCollectionName: [String: String]?
    
    internal var mediaPlayCollectionImage: KPSImageResource?
    
    public static var config = Config(apiKey: "", appId: "")

    public static let shared = KPSClient(apiKey: KPSClient.config.apiKey, server: KPSClient.config.baseServer)
    
    
    init(apiKey: String, appId: String, networkProvider: NetworkProvider? = nil) {
        
        self.apiKey = apiKey
        self.appId = appId
        
        if let networkProvider = networkProvider {
            self.networkProvider = networkProvider
        } else {
            //self.networkProvider = NetworkProvider(plugins: [NetworkLoggerPlugin()])
            self.networkProvider = NetworkProvider(endpointClosure: self.customizeEndpoint)
            
        }
    }
    
    init(apiKey: String, server: Server) {
        
        self.apiKey = apiKey
        self.appId = server.appId
        self.networkProvider = NetworkProvider(endpointClosure: self.customizeEndpoint)

    }
    
    
    public func login(keyID: String, token: String, completion: @escaping (Result<LoginResponse, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<LoginResponse, MoyaError>) -> Void) = { result in
            
            switch result {
            case let .success(response):
                self.currentUserId = response.user.id
                KPSClient.sessionToken = response.kpsSession
                self.isUserLoggedIn = true
                completion(.success(response))
            case let .failure(error):
                self.isUserLoggedIn = false
                do {
                    let errorDescription = try error.response?.mapJSON()
                    print(errorDescription ?? "")
                    completion(.failure(error))
                } catch _ {
                    print("decode error")
                }
            }
        }
        request(target: .login(keyId: keyID, token: token, server: KPSClient.config.baseServer), completion: resultClosure)
    }
    
    public func logout(completion: ((Result<Moya.Response, MoyaError>) -> ())? = nil) {
        networkProvider.request(.logout(server: KPSClient.config.baseServer)) { result in
            switch result {
            case let .success(response):
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    self.isUserLoggedIn = false
                    self.mediaPlayerReset(isNeedClearPlayList: true)
                    KPSClient.sessionToken = nil
                    completion?(.success(response))
                } catch let error {
                    if let customError = error as? MoyaError {
                        completion?(.failure(customError))
                    } else {
                        completion?(.failure(.jsonMapping(response)))
                    }
                }
                
            case let .failure(error):
                completion?(.failure(error))
            }
        }
    }
    
    internal func setNowPlayingInfo() {
        
        guard let content = currentPlayAudioContent,
              let collectionImage = mediaPlayCollectionImage?.mainImageURL else { return }
        
        if content.error != nil {
            //try! AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            self.nowPlayingCenter.nowPlayingInfo = [:]
            
        } else {
        
            var info = [String: Any]()
            info[MPMediaItemPropertyTitle] = content.name["zh-TW"]
            info[MPMediaItemPropertyAlbumTitle] = mediaPlayCollectionName?["zh-TW"]
            info[MPMediaItemPropertyArtist] = content.firstAuthor["zh-TW"]
            info[MPMediaItemPropertyAlbumArtist] = content.firstAuthor["zh-TW"]
            info[MPMediaItemPropertyPlaybackDuration] = content.length
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
            info[MPNowPlayingInfoPropertyPlaybackRate] = mediaPlayerRate
            info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
            
                
            DispatchQueue.global().async { [weak self] in
                if let artworkUrl = URL(string: collectionImage),
                   let artworkData = try? Data(contentsOf: artworkUrl),
                   let artworkImage = UIImage(data: artworkData) {
                    if var currentInfo = self?.nowPlayingCenter.nowPlayingInfo {
                        currentInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }
                        self?.nowPlayingCenter.nowPlayingInfo = currentInfo
                    }
                }
            }
            self.nowPlayingCenter.nowPlayingInfo = info
        }
    }
    
    internal func enableRemoteCommand() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }
}

// MARK: Data Related API
extension KPSClient {
    
    public func fetchCollection(Id: String? = nil, isNeedParent: Bool = false, isNeedSiblings: Bool = false, completion: @escaping(Result<KPSCollection, MoyaError>) -> ()) {
        
        if let collectionId = Id {
            request(target: .fetchCollection(Id: collectionId, isNeedParent: isNeedParent, isNeedSiblings: isNeedSiblings, server: KPSClient.config.baseServer), completion: completion)

        } else {
            request(target: .fetchRootCollection(server: KPSClient.config.baseServer) , completion: completion)
            
        }
        
    }

    
}


// MARK: View Related API
extension KPSClient {
    
    
    
}


// MARK: - Utility function
extension KPSClient {
    internal func request<T: Decodable>(target: CoreAPIService, completion: @escaping (Result<T, MoyaError>) -> ()) {
        
        networkProvider.request(target) { result in
            switch result {
            case let .success(response):
                do {
                    //let filteredResponse = try response.filterSuccessfulStatusCodes()
                    let results = try JSONDecoder().decode(T.self, from: response.data)
                    
                    completion(.success(results))
                } catch let error {
                    if let customError = error as? MoyaError {
                        completion(.failure(customError))
                    } else {

                        do{
                            let json = try JSONSerialization.jsonObject(with: response.data, options: .mutableContainers)
                            let dic = json as! Dictionary<String, Any>
                            print(dic)
                        } catch _ {
                            
                        }
                        completion(.failure(.jsonMapping(response)))
                    }
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}


// MARK: - Config
extension KPSClient {
    /// A configuration for the shared Instance `Client`.
    public struct Config {
        let apiKey: String
        let appId: String
        var baseServer: Server
        
        /// Setup a configuration for the shared Instance `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: the KPS API key
        ///     - appId: the KPS project id
        ///     - server: the KPS backend server setting
        public init(apiKey: String = "", appId: String) {
            self.init(apiKey: apiKey,
                      appId: appId,
                      server: nil)
        }
        
        public init(apiKey: String, appId: String, server: Server?) {
            self.apiKey = apiKey
            self.appId = appId
            
            if let baseServer = server {
                self.baseServer = baseServer
            } else {
                self.baseServer = Server.prod()
            }
            self.baseServer.appId = appId
        }
    }
}


public struct Server {
    
    var appId: String = ""
    var baseUrl: URL
    var projectUrl: URL {
        return baseUrl.appendingPathComponent("/projects/\(appId)")
    }
    
    private init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }
    
    public static func develop() -> Server {
        return Server(
            baseUrl: URL(string: "https://kps-dev.thekono.com/api/v1")!
        )
    }
    
    public static func staging() -> Server {
        return Server(
            baseUrl: URL(string: "https://kps-stg.thekono.com/api/v1")!
        )
    }
    
    public static func prod() -> Server {
        return Server(
            baseUrl: URL(string: "https://kps.thekono.com/api/v1")!
        )
    }
    
}

/*
public enum Server {
    case develop(appId: String)
    case staging(appId: String)
    case prod(appId: String)

    var appId: String {
        switch self {
        case .develop(let appId), .staging(let appId), .prod(let appId):
            return appId
        }
    }
    var cloudStorage: String {
        return "https://storage.googleapis.com/"
    }
    var baseUrl: URL {
        switch self {
        case .develop(_):
            return URL(string: "https://kps-dev.thekono.com/api/v1")!
        case .staging(_):
            return URL(string: "https://kps-stg.thekono.com/api/v1")!
        case .prod(_):
            return URL(string: "https://kps.thekono.com/api/v1")!
        }
    }
    
    var projectUrl: URL {
        switch self {
        case .develop(let appId), .staging(let appId), .prod(let appId):
            return baseUrl.appendingPathComponent("/projects/\(appId)")
        }
    }
}
*/

public enum KPSContentError: Swift.Error {
    case needLogin
    case needPurchase
    case userBlocked
}

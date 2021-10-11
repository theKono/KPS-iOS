//
//  KPSClient.swift
//  KPS
//


import Foundation
import AVFoundation
import UIKit
import Moya

typealias NetworkProvider = MoyaProvider<CoreAPIService>



public final class KPSClient: NSObject {
    let apiKey: String
    let appId: String
    
    private let networkProvider: NetworkProvider
    
    /// The current user id from the Token.
    public internal(set) var currentUserId: String?

    /// Current session token
    var currentSessionToken: String?
    
    public var isUserLoggedIn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isUserLoggedIn")
        }
        
        set (newValue) {
            UserDefaults.standard.set(newValue, forKey: "isUserLoggedIn")
        }
    }
    
    public weak var mediaContentDelegate: KPSClientMediaContentDelegate?
    
    public lazy var mediaPlayer: AVQueuePlayer = {
        let player = AVQueuePlayer()
        
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: .main) { [weak self] time in
          guard let self = self else { return }
            
            if let currentItem = self.mediaPlayer.currentItem {
                let duration = currentItem.duration
                let currentTime = CMTimeGetSeconds(time)
                
                guard duration.value > 0 && duration.timescale > 0 else {return}
                let totalTime   = TimeInterval(duration.value) / TimeInterval(duration.timescale)
                
                let endTimes = self.mediaPlayList[self.currentTrack].content.filter({ sentence in
                    sentence.startTime > 0
                }).map { sentence in
                    return sentence.endTime
                }
                var left: Int = 0, right: Int = endTimes.count-1
                while left <= right {
                    var mid = left + (right-left) / 2
                    if endTimes[mid] > currentTime {
                        right = mid - 1
                    } else {
                        left = mid + 1
                    }
                }
                self.mediaContentDelegate?.kpsClient(client: self, playerPlayTimeDidChange: currentTime, totalTime: totalTime)
                self.currentSegment = left
            }
          
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

        player.addObserver(self, forKeyPath: "currentItem", options: [.initial, .new, .old], context: nil)
        
        player.actionAtItemEnd = .advance
        return player
    }()
    
    public var isMediaPlaying: Bool = false {
        didSet {
            if oldValue != isMediaPlaying {
                mediaContentDelegate?.kpsClient(client: self, playerIsPlaying: isMediaPlaying)
            }
        }
    }
    
    public var mediaPlayerRate: Float = 1.0 {
        didSet {
            if isMediaPlaying {
                mediaPlayer.playImmediately(atRate: mediaPlayerRate)
            }
        }
    }
    
    public var currentTrack: Int = -1 {
        didSet {
            if currentTrack != -1 && currentTrack < mediaPlayList.count {
                mediaContentDelegate?.kpsClient(client: self, playerCurrentContent: mediaPlayList[currentTrack])
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSCurrentPlayingTrackUpdated"), object: nil, userInfo: nil)
            } else {
                mediaContentDelegate?.kpsClient(client: self, playerCurrentContent: nil)
            }
            mediaContentDelegate?.kpsClient(client: self, playerCurrentTrack: currentTrack)
        }
    }
    
    public var currentSegment: Int = -1 {
        didSet {
            if self.currentTrack < self.mediaPlayList.count && currentSegment != -1 && currentSegment < self.mediaPlayList[self.currentTrack].content.count && oldValue != currentSegment {
                self.mediaContentDelegate?.kpsClient(client: self, playerCurrentSegment: currentSegment)
            }
        }
    }
    
    //MARK: get only variable
    public var isPlayListLoaded: Bool {
        return mediaPlayList.count > 0
    }
    
    public var currentPlayAudioContent: KPSAudioContent? {
        guard currentTrack >= 0 && currentTrack < mediaPlayList.count  else { return nil }
        return mediaPlayList[currentTrack]
    }
    
    
    internal var mediaPlayerState = MediaPlayerState.nonSetSource {
        didSet {
            if oldValue != mediaPlayerState {
                mediaContentDelegate?.kpsClient(client: self, playerStateDidChange: mediaPlayerState)
            }
        }
    }
    
    internal var mediaPlayList = [KPSAudioContent]() {
        didSet {
            
            for item in mediaPlayList {
                mediaPlayer.insert(getAVPlayerItem(source: item), after: nil)
            }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            } catch {
                print(error)
            }
            currentTrack = 0
        }
    }
    
    public static var config = Config(apiKey: "", appId: "")

    public static let shared = KPSClient(apiKey: KPSClient.config.apiKey, appId: KPSClient.config.appId)
    
    
    init(apiKey: String, appId: String, networkProvider: NetworkProvider? = nil) {
        
        self.apiKey = apiKey
        self.appId = appId
        
        if let networkProvider = networkProvider {
            self.networkProvider = networkProvider
        } else {
            //self.networkProvider = NetworkProvider(plugins: [NetworkLoggerPlugin()])
            self.networkProvider = NetworkProvider()
            
        }
    }
    
    public func login(keyID: String, token: String, completion: @escaping (Result<LoginResponse, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<LoginResponse, MoyaError>) -> Void) = { result in
            
            switch result {
            case let .success(response):
                self.currentUserId = response.user.id
                self.currentSessionToken = response.kpsSession
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
    
    public func logout(completion: @escaping(Result<Moya.Response, MoyaError>) -> ()) {
        networkProvider.request(.logout(server: KPSClient.config.baseServer)) { result in
            switch result {
            case let .success(response):
                do {
                    let _ = try response.filterSuccessfulStatusCodes()
                    self.isUserLoggedIn = false
                    completion(.success(response))
                } catch let error {
                    if let customError = error as? MoyaError {
                        completion(.failure(customError))
                    } else {
                        completion(.failure(.jsonMapping(response)))
                    }
                }
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
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
    
    public func fetchRootFolder(completion: @escaping(Result<KPSFolder, MoyaError>) -> ()) {
        request(target:.fetchRootFolder(server: KPSClient.config.baseServer) , completion: completion)
    }
    
    public func fetchFolder(folderId: String, completion: @escaping(Result<KPSFolder, MoyaError>) -> ()) {
        let resultClosure: ((Result<KPSFolder, MoyaError>) -> Void) = { result in
            
            switch result {
            case let .success(folder):
                var modifyFolder = folder
                var modifyContents = [KPSContent]()
                for data in folder.children {
                    var mutableData = data
                    mutableData.images = data.images.map {
                        var mutableImage = $0
                        mutableImage.config = KPSClient.config.baseServer
                        return mutableImage
                    }
                    modifyContents.append(mutableData)
                }
                modifyFolder.children = modifyContents
                completion(.success(modifyFolder))
            case let .failure(error):
                guard error.response != nil else { return }
                
                completion(.failure(error))
            }
        }
        request(target:.fetchFolder(folderId: folderId, server: KPSClient.config.baseServer) , completion: resultClosure)
    }
    
    public func fetchArticle(articleId: String, completion: @escaping(Result<KPSArticle, MoyaError>, Bool) -> ()) {
        
        let resultClosure: ((Result<KPSArticle, MoyaError>) -> Void) = { result in
            
            switch result {
            case let .success(response):
                var content = response
                content.images = response.images.map {
                    var mutableImage = $0
                    mutableImage.config = KPSClient.config.baseServer
                    return mutableImage
                }
                completion(.success(content), true)
                
            case let .failure(error):
                guard let response = error.response else { return }
                
                if response.statusCode == 403 {
                    do {
                        let previewContent = try JSONDecoder().decode(KPSArticle.self, from: response.data)
                        completion(.success(previewContent), false)
                    } catch {
                        print("decode error")
                    }
                }
                
                completion(.failure(error), false)
            }
        }
        request(target:.fetchArticle(articleId: articleId, server: KPSClient.config.baseServer), completion: resultClosure)
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
        let baseServer: Server
        
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
        
        init(apiKey: String, appId: String, server: Server?) {
            self.apiKey = apiKey
            self.appId = appId
            
            if let baseServer = server {
                self.baseServer = baseServer
            } else {
                self.baseServer = .staging(appId: appId, version: "1")
            }
        }
    }
}


enum Server {
    case develop(appId: String, version: String)
    case staging(appId: String, version: String)
    case prod(appId: String, version: String)

    var env: String {
        switch self {
        case .develop(_, _):
            return "dev"
        case .staging(_, _):
            return "dev"
        case .prod(_, _):
            return "dev"
        }
    }
    
    var cloudStorage: String {
        return "https://storage.googleapis.com/"
    }
    var baseUrl: URL {
        switch self {
        case .develop(_, let version):
            return URL(string: "https://kps-dev.thekono.com/api/v\(version)")!
        case .staging(_, let version):
            return URL(string: "https://kps-stg.thekono.com/api/v\(version)")!
        case .prod(_, let version):
            return URL(string: "https://kps-dev.thekono.com/api/v\(version)")!
        }
    }
    
    var projectUrl: URL {
        switch self {
        case .develop(let appId, _), .staging(let appId, _), .prod(let appId, _):
            return baseUrl.appendingPathComponent("/projects/\(appId)")
        }
    }
}

//
//  KPSClient+Media.swift
//  KPS
//


import AVFoundation
import MediaPlayer
import Moya

public enum MediaPlayerState {
    
    case nonSetSource
    case fetchingSource
    case sourceFetched
    case buffering
    case bufferFetched
    case playedToTheEnd
    case error
    
}


public protocol KPSClientMediaContentDelegate: class {
    
    func kpsClient(client: KPSClient, playerStateDidChange state: MediaPlayerState)
    func kpsClient(client: KPSClient, playerPlayTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
    func kpsClient(client: KPSClient, playerIsPlaying playing: Bool)
    func kpsClient(client: KPSClient, playerCurrentContent content: KPSAudioContent?)
    func kpsClient(client: KPSClient, playerCurrentTrack trackIndex: Int)
    func kpsClient(client: KPSClient, playerCurrentSegmentDidChange segmentIndex: Int, paragraph paragraphIndex: Int, highlightRange range: NSRange?)
    func kpsClient(client: KPSClient, playerCurrentParagraphDidChange paragraphIndex: Int, segment segmentIndex: Int, highlightRange range: NSRange?)
    func kpsClient(client: KPSClient, playerHighlightRangeDidChange range: NSRange?, paragraph paragraphIndex: Int, segment segmentIndex: Int)
}

public extension KPSClientMediaContentDelegate {
    func kpsClient(client: KPSClient, playerCurrentTrack trackIndex: Int) {}
    func kpsClient(client: KPSClient, playerCurrentSegmentDidChange segmentIndex: Int, paragraph paragraphIndex: Int, highlightRange range: NSRange?) {}
    func kpsClient(client: KPSClient, playerCurrentParagraphDidChange paragraphIndex: Int, segment segmentIndex: Int, highlightRange range: NSRange?) {}
    func kpsClient(client: KPSClient, playerHighlightRangeDidChange range: NSRange?, paragraph paragraphIndex: Int, segment segmentIndex: Int) {}

}

extension KPSClient {
    
    
    internal func createDefaultAVPlayer() -> AVQueuePlayer {
        
        let player = AVQueuePlayer()
        let monitorTime = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.addPeriodicTimeObserver(forInterval: monitorTime, queue: .main) { [weak self] time in
          guard let self = self else { return }
            
            if let currentItem = self.mediaPlayer.currentItem {
                let duration = currentItem.duration
                let currentTime = CMTimeGetSeconds(currentItem.currentTime())
                
                guard duration.value > 0 && duration.timescale > 0 else {return}
                let totalTime   = TimeInterval(duration.value) / TimeInterval(duration.timescale)
                self.currentTime = currentTime

                guard let timeFrames = self.currentPlayAudioContent?.timeFrames,
                      let paragraphContent = self.currentPlayAudioContent?.paragraphContents else { return }
                
                var highlightSegment: Int = -1
                var left: Int = 0, right: Int = timeFrames.count - 1
                while left <= right {
                    let mid = left + (right-left) / 2
                    if timeFrames[mid].endTime > currentTime {
                        right = mid - 1
                    } else {
                        left = mid + 1
                    }
                }
                if left < timeFrames.count && timeFrames[left].startTime < currentTime {
                    
                    self.currentSegment = timeFrames[left].mappingIdx
                    left = 0
                    right = paragraphContent.count - 1
                    while left <= right {
                        let mid = left + (right - left) / 2
                        if paragraphContent[mid].segmentIdx >= self.currentSegment {
                            right = mid - 1
                        } else {
                            left = mid + 1
                        }
                    }
                    if left < paragraphContent.count  {
                        self.currentParagraph = left
                        var hasFindMatchedRange: Bool = false
                        for rangeInfo in paragraphContent[left].partitionInfos {
                            if rangeInfo.startTime <= currentTime && rangeInfo.endTime > currentTime {
                                self.currentHighlightRange = rangeInfo.paragraphLocation
                                //print("current:\(currentTime) text:\(rangeInfo.text)")
                                hasFindMatchedRange = true
                                break
                            }
                        }
                        if !hasFindMatchedRange {
                            self.currentHighlightRange = nil
                        }
                                            
                    } else {
                        
                        self.currentParagraph = -1
                        self.currentHighlightRange = nil
                    }

                } else {
                    self.currentSegment = -1
                    self.currentParagraph = -1
                    self.currentHighlightRange = nil
                }
            }
        }
        player.addObserver(self, forKeyPath: "currentItem", options: [.initial, .new, .old], context: nil)
        player.actionAtItemEnd = .advance
        
        enableRemoteCommand()
        registerAudioPlayerNotification()
        setupRemoteCommandHandler()
        return player
    }
    
    internal func registerAudioPlayerNotification() {
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioRouteChanged), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    internal func setupRemoteCommandHandler() {
        commandCenter.playCommand.addTarget{ [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.mediaPlayerPlayAction()
            return .success
        }
        commandCenter.pauseCommand.addTarget{ [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.mediaPlayerPause()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget{ [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.mediaPlayerPlayPrev()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget{ [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.mediaPlayerPlayNext()
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget{ [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.mediaPlayerSeekTime(positionEvent.positionTime) { res  in
                
            }
            return .success
        }
    }
    
    
    /// Play all audio contents within given KPSCollection
    /// - Parameter collection: KPS content folder type node
    public func playAudioContents(from collection: KPSCollection) {

        mediaPlayList = collection.children
        mediaPlayCollectionId = collection.id
        mediaPlayCollectionName = collection.name
        mediaPlayCollectionImage = collection.images.first
        
    }
    
    public func getPlayList() -> [KPSContentMeta] {
        return mediaPlayList
    }
    
    public func fetchAudioContent(audioId: String, completion: @escaping(Result<KPSAudioContent, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<KPSAudioContent, MoyaError>) -> Void) = { [weak self] result in
            
            guard let weakSelf = self else { return }
            switch result {
            case let .success(response):
                var content = response
                content.collectionId = weakSelf.mediaPlayCollectionId
                content.collectionName = weakSelf.mediaPlayCollectionName
                completion(.success(content))
                
            case let .failure(error):
                guard let _ = error.response else { return }
                
                completion(.failure(error))
            }
        }
        request(target:.fetchAudio(audioId: audioId, server: KPSClient.config.baseServer), completion: resultClosure)
    }
    
    
    public func mediaPlayerPlay(targetTrack: Int? = nil, completion: ((Bool)->Void)? = nil) {
        
        guard mediaPlayList.count > 0 else {
            isMediaPlaying = false
            return
        }
        try! AVAudioSession.sharedInstance().setActive(true)
        
        
        if let targetTrack = targetTrack  {
            
            mediaPlayerReset()
            mediaPlayerState = .fetchingSource
            fetchAudioContent(audioId: mediaPlayList[targetTrack].id) { [weak self] result in
                guard let weakSelf = self else { return }
                if let track = try? result.get() {
                    weakSelf.currentTrack = targetTrack
                    weakSelf.currentTime = 0.0
                    weakSelf.currentPlayAudioContent = track
                    weakSelf.mediaPlayerState = .sourceFetched
                    weakSelf.mediaPlayer.removeAllItems()
                    if track.error == nil {
                        weakSelf.mediaPlayer.insert(weakSelf.getAVPlayerItem(source: track), after: nil)
                        weakSelf.mediaPlayerPlayAction()
                        completion?(true)
                    } else {
                        completion?(false)
                    }
                } else {
                    weakSelf.mediaPlayerState = .error
                    completion?(false)
                }
            }
            
        } else {
            if mediaPlayer.items().count > 0 {
                
                mediaPlayerPlayAction()
                completion?(true)
                
            } else if currentTrack < mediaPlayList.count && currentTrack >= 0 {
                
                mediaPlayerState = .fetchingSource
                fetchAudioContent(audioId: mediaPlayList[currentTrack].id) { [weak self] result in
                    guard let weakSelf = self else { return }
                    if let track = try? result.get() {
                        weakSelf.currentPlayAudioContent = track
                        weakSelf.mediaPlayer.removeAllItems()
                        weakSelf.mediaPlayerState = .sourceFetched
                        if track.error == nil {
                            weakSelf.mediaPlayer.insert(weakSelf.getAVPlayerItem(source: track), after: nil)
                            weakSelf.mediaPlayerPlayAction()
                            completion?(true)
                        }
                        else {
                            completion?(false)
                        }
                    } else {
                        weakSelf.mediaPlayerState = .error
                        completion?(false)
                    }
                }
            }
        }
    }

    
    
    internal func mediaPlayerPlayAction() {
        mediaPlayer.play()
        mediaPlayer.rate = mediaPlayerRate
        isMediaPlaying = true
    }
    
    public func mediaPlayerPlayNext(completion: ((Bool) -> Void)? = nil) {
        
        guard mediaPlayList.count > 0 else { return }
        
        if currentTrack + 1 >= mediaPlayList.count {
            mediaPlayerStop()
            completion?(true)
        } else {
            mediaPlayerPlay(targetTrack: currentTrack + 1, completion: completion)
        }
    }
    
    public func mediaPlayerPlayPrev(completion: ((Bool)->Void)? = nil) {
        
        guard mediaPlayList.count > 0 else { return }
        
        if currentTrack - 1 < 0 && isMediaPlaying {
            
            mediaPlayer.seek(to: CMTime.zero) { [weak self] _ in
                if var currentInfo = self?.nowPlayingCenter.nowPlayingInfo,
                   let currentTime = self?.mediaPlayer.currentItem?.currentTime(){
                    currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime.seconds
                    self?.nowPlayingCenter.nowPlayingInfo = currentInfo
                }
            }
            completion?(true)
            
        } else if currentTrack - 1 >= 0 {
            mediaPlayerPlay(targetTrack: currentTrack - 1, completion: completion)
        }
    }
    
    public func mediaPlayerPlayForward(_ seconds: TimeInterval = 10, completion: @escaping (Bool) -> Void) {
        
        guard mediaPlayer.currentItem != nil else { return }
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        
        mediaPlayerSeekTime(playerCurrentTime + seconds, completion: completion)
        
    }
    
    public func mediaPlayerPlayRewind(_ seconds: TimeInterval = 10, completion: @escaping (Bool) -> Void) {
        
        guard mediaPlayer.currentItem != nil else { return }
        
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        
        mediaPlayerSeekTime(playerCurrentTime - seconds, completion: completion)
    }
    
    public func mediaPlayerSeekParagraph(_ paragraphIndex: Int, location range: NSRange? = nil, completion: @escaping (Bool) -> Void) {
        
        guard mediaPlayer.currentItem != nil else { return }
        guard let contents = self.currentPlayAudioContent?.paragraphContents else { return }
        if contents.count > paragraphIndex {
            let targetParagraph = contents[paragraphIndex]
            
            if range == nil {
                mediaPlayerSeekTime(targetParagraph.startTime, completion: completion)

            } else {
                for partitionInfo in targetParagraph.partitionInfos {
                    if range!.location <= (partitionInfo.paragraphLocation.location + partitionInfo.paragraphLocation.length) {
                        mediaPlayerSeekTime(partitionInfo.startTime, completion: completion)
                        break
                    }
                }
            }
            currentParagraph = paragraphIndex
            currentHighlightRange = range
            print("currentParagraph: \(currentParagraph)  currentHighlightRange: \(currentHighlightRange)")
        }
    }
    
    public func mediaPlayerSeekSegment(_ segmentIndex: Int, completion: @escaping (Bool) -> Void) {
        
        guard mediaPlayer.currentItem != nil else { return }
        guard let content = self.currentPlayAudioContent?.content else { return }
        if content.count > segmentIndex {
            let targetPlayTime = content[segmentIndex].startTime
            currentSegment = segmentIndex
            mediaPlayerSeekTime(targetPlayTime, completion: completion)
        }
    }
    
    public func mediaPlayerSeekTime(_ time: TimeInterval, completion: @escaping (Bool) -> Void) {
        
        guard let duration = mediaPlayer.currentItem?.duration else { return }

        let newTime = min( max(0, time), CMTimeGetSeconds(duration) )

        let targetTime = CMTimeMakeWithSeconds(newTime, preferredTimescale: 1000)
        mediaPlayer.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] res in
            if var currentInfo = self?.nowPlayingCenter.nowPlayingInfo,
               let currentTime = self?.mediaPlayer.currentItem?.currentTime(){
                currentInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime.seconds
                self?.nowPlayingCenter.nowPlayingInfo = currentInfo
            }
            completion(res)
        }
    }
    
    public func mediaPlayerGetTrackOrder(_ targetID: String) -> Int {
        
        guard mediaPlayList.count > 0 else { return -1 }
        
        var targetTrackOrder = -1
        for (idx, item) in mediaPlayList.enumerated() {
            
            if targetID == item.id {
                targetTrackOrder = idx
                break
            }
        }

        return targetTrackOrder
    }
    
    public func mediaPlayerPause() {
        
        mediaPlayer.pause()
        isMediaPlaying = false
        
    }
    
    public func mediaPlayerStop() {
    
        // Define the stop action is reset to the first item within the play list
        mediaPlayer.pause()
        mediaPlayerPlay(targetTrack: 0) { _ in
            self.mediaPlayerPause()
        }
    }
    
    public func mediaPlayerReset(isNeedClearPlayList: Bool = false) {
        if isNeedClearPlayList {
            mediaPlayList.removeAll()
        }
        
        mediaPlayer.pause()
        mediaPlayer.removeAllItems()
        isMediaPlaying = false
        currentTrack = -1
        currentSegment = -1
        currentPlayAudioContent = nil
    }
    
    public func mediaPlayerChangeSpeed(rate: Double) {
        
        mediaPlayer.rate = Float(rate)
        
    }
    
    
    internal func getAVPlayerItem(source: KPSAudioContent) -> AVPlayerItem {
        let item = AVPlayerItem(url: source.streamingUrl!)
        item.audioTimePitchAlgorithm = .spectral
        return item
    }
    
    @objc internal func playerDidFinishPlaying(notification: NSNotification) {
    
        if (currentTrack + 1) == mediaPlayList.count {
            mediaPlayerStop()
        } else {
            mediaPlayerPlay(targetTrack: currentTrack + 1)
        }
    }
    
    @objc internal func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        switch type {
        case .began:
            mediaPlayerPause()
            
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                mediaPlayerPlayAction()
            }
            
        default: break
        }
    }
    
    @objc func audioRouteChanged(_ notification:Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                
                for output in previousRoute.outputs where (output.portType == AVAudioSession.Port.headphones || output.portType == AVAudioSession.Port.bluetoothA2DP) {
                    mediaPlayerPause()
                    break
                }
            }
        default: ()
        }
    }
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "currentItem"{
            if let oldItem = change?[NSKeyValueChangeKey.oldKey] as? AVPlayerItem {
                oldItem.removeObserver(self, forKeyPath: "status")
                oldItem.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                oldItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            }
            
            if let newItem = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem {
                
                newItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                newItem.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
                newItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
                
                let duration = newItem.duration
                let totalTime   = TimeInterval(duration.value) / TimeInterval(duration.timescale)
                mediaContentDelegate?.kpsClient(client: self, playerPlayTimeDidChange: 0.0, totalTime: totalTime)
                
            }
        } else {

            if let item = object as? AVPlayerItem, let keyPath = keyPath {
                
                switch keyPath {
                case "status":
                    if item.status == .failed {
                        mediaPlayerState = .error
                    } else if mediaPlayer.status == AVPlayer.Status.failed {
                        mediaPlayer = createDefaultAVPlayer()
                        mediaPlayerState = .error
                    } else if mediaPlayer.status == AVPlayer.Status.readyToPlay {
                        mediaPlayerState = .bufferFetched
                    }
                case "playbackBufferEmpty":
                    mediaPlayerState = .buffering
                case "playbackLikelyToKeepUp":
                    mediaPlayerState = .bufferFetched
                default:
                    break;
                }
                
            }
        }
    }
    
}

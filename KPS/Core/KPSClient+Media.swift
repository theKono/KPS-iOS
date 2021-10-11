//
//  KPSClient+Media.swift
//  KPS
//


import AVFoundation
import Moya

public enum MediaPlayerState {
    
    case nonSetSource
    case readyToPlay
    case buffering
    case playedToTheEnd
    case error
    
}


public protocol KPSClientMediaContentDelegate: class {
    
    func kpsClient(client: KPSClient, playerStateDidChange state: MediaPlayerState)
    func kpsClient(client: KPSClient, playerPlayTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
    func kpsClient(client: KPSClient, playerIsPlaying playing: Bool)
    func kpsClient(client: KPSClient, playerCurrentContent content:KPSAudioContent?)
    func kpsClient(client: KPSClient, playerCurrentTrack trackIndex: Int)
    func kpsClient(client: KPSClient, playerCurrentSegment segmentIndex: Int)
    
}

extension KPSClient {
    
    public func setupTestAudioFile() {
        
        let frameworkBundle = Bundle(for: KPSClient.self)
        
        if let url = frameworkBundle.resourceURL?.appendingPathComponent("KPS_iOS.bundle/IronBacon.mp3"),
           let url2 = frameworkBundle.resourceURL?.appendingPathComponent("KPS_iOS.bundle/WhatYouWant.mp3"){
            mediaPlayList = getPlayerItem(urls: [url, url2])
            
        } else {
            print("can't find the file")
        }
        
    }
    
    internal func getPlayerItem(urls: [URL]) -> [KPSAudioContent] {
        var playerList = [KPSAudioContent]()
        for url in urls {
            playerList.append(KPSAudioContent(url: url))
        }
        return playerList
    }
    
    public func playAudioContents(_ contents: [KPSAudioContent]) {

        mediaPlayList = contents
        
    }
    
    public func fetchAudioContent(audioId: String, collection: KPSContentMeta?, completion: @escaping(Result<KPSAudioContent, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<KPSAudioContent, MoyaError>) -> Void) = { result in
            
            switch result {
            case let .success(response):
                var content = response
                content.collectionId = collection?.id
                content.collectionName = collection?.name
                completion(.success(content))
                
            case let .failure(error):
                guard let _ = error.response else { return }
                
                completion(.failure(error))
            }
        }
        request(target:.fetchAudio(audioId: audioId, server: KPSClient.config.baseServer), completion: resultClosure)
    }
    /*
    public func fetchAudioContentWithFolder(_ folder: KPSFolder, completion: @escaping([KPSAudioContent]) -> ()) {
        
        let group = DispatchGroup()
        let audioContents = ThreadSafeArray<KPSAudioContent>()
        for child in folder.children {
            if child.type == "audio" {
                group.enter()
                fetchAudioContent(audioId: child.id, folderName: folder.name ?? "") { result in
                    defer { group.leave() }
                    
                    if let track = try? result.get() {
                        audioContents.append(track)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            let sortedResult = audioContents.sorted { $0.order < $1.order }
            completion(sortedResult.items())
        }
        */
    
    public func fetchAudioContentWithIds(_ audioIds: [String], collection: KPSContentMeta?,completion: @escaping([KPSAudioContent]) -> ()) {
            
            let group = DispatchGroup()
            let audioContents = ThreadSafeArray<KPSAudioContent>()
            for audioId in audioIds {
                
                group.enter()
                fetchAudioContent(audioId: audioId, collection: collection) { result in
                    defer { group.leave() }
                
                    if let track = try? result.get() {
                        audioContents.append(track)
                    }
                }
            }

            group.notify(queue: .main) {
                let sortedResult = audioContents.sorted { $0.order < $1.order }
                completion(sortedResult.items())
            }
    }
    
    public func mediaPlayerPlay() {
        
        guard mediaPlayList.count > 0 else {
            isMediaPlaying = false
            return
        }
        try! AVAudioSession.sharedInstance().setActive(true)
        
        mediaPlayer.play()
        mediaPlayer.rate = mediaPlayerRate
        isMediaPlaying = true
        
    }
    
    public func mediaPlayerPlayNext() {
        
        guard mediaPlayer.items().count > 0 else { return }
        
        if currentTrack + 1 >= mediaPlayList.count {
            mediaPlayerStop()
            
        } else {
            mediaPlayer.advanceToNextItem()
            currentTrack += 1
        }
    }
    
    public func mediaPlayerPlayPrev() {
        
        guard mediaPlayer.items().count > 0 else { return }
        
        if currentTrack - 1 < 0 && isMediaPlaying {
            
            mediaPlayer.seek(to: CMTime.zero)
            
        } else if currentTrack - 1 >= 0 {
            currentTrack -= 1
            let previousItem = getAVPlayerItem(source: mediaPlayList[currentTrack])
            let currentItem = getAVPlayerItem(source: mediaPlayList[currentTrack + 1])
            
            mediaPlayer.insert(previousItem, after: mediaPlayer.currentItem)
            mediaPlayer.insert(currentItem, after: previousItem)
            mediaPlayer.advanceToNextItem()
            
        }
    }
    
    public func mediaPlayerPlayForward(_ seconds: TimeInterval = 10) {
        
        guard mediaPlayer.currentItem != nil else { return }
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        
        mediaPlayerSeekTime(playerCurrentTime + seconds)
        
        
    }
    
    public func mediaPlayerPlayRewind(_ seconds: TimeInterval = 10) {
        
        guard mediaPlayer.currentItem != nil else { return }
        
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        
        mediaPlayerSeekTime(playerCurrentTime - seconds)
    }
    
    public func mediaPlayerSeekSegment(_ segmentIndex: Int) -> Bool {
        
        return true
    }
    
    public func mediaPlayerSeekTime(_ time: TimeInterval) {
        
        guard let duration = mediaPlayer.currentItem?.duration else { return }

        let newTime = min( max(0, time), CMTimeGetSeconds(duration) )
        
        let targetTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        mediaPlayer.seek(to: targetTime)
    }
    
    public func mediaPlayerSeekTrack(_ targetID: String) -> Bool {
        
        guard mediaPlayList.count > 0 else { return false }
        
        var targetTrackIndex = mediaPlayList.count
        for (idx, item) in mediaPlayList.enumerated() {
            
            if targetID == item.id {
                targetTrackIndex = idx
                break
            }
        }
        
        if targetTrackIndex == mediaPlayList.count {
            return false
        } else {
            
            mediaPlayer.removeAllItems()
            for idx in targetTrackIndex..<mediaPlayList.count {
                mediaPlayer.insert(getAVPlayerItem(source: mediaPlayList[idx]), after: nil)
            }
            currentTrack = targetTrackIndex
        }

        return true
    }
    
    public func mediaPlayerPause() {
        
        mediaPlayer.pause()
        isMediaPlaying = false
        
    }
    
    public func mediaPlayerStop() {
    
        mediaPlayerReset()
        for track in mediaPlayList {
            mediaPlayer.insert(getAVPlayerItem(source: track), after: nil)
        }
        currentTrack = 0
    }
    
    public func mediaPlayerReset(isNeedClearPlayList: Bool = false) {
        mediaPlayer.pause()
        mediaPlayer.removeAllItems()
        isMediaPlaying = false
        currentTrack = -1
        currentSegment = -1
        if isNeedClearPlayList {
            mediaPlayList.removeAll()
        }
    }
    
    public func mediaPlayerChangeSpeed(rate: Double) {
        
        mediaPlayer.rate = Float(rate)
        
    }
    
    
    internal func getAVPlayerItem(source: KPSAudioContent) -> AVPlayerItem {
        let item = AVPlayerItem(url: source.streamingUrl)
        item.audioTimePitchAlgorithm = .spectral
        return item
    }
    
    
    
    @objc func playerDidFinishPlaying(notification: NSNotification) {
        currentTrack += 1
        if currentTrack == mediaPlayList.count {
            mediaPlayerStop()
            
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
                    if item.status == .failed || mediaPlayer.status == AVPlayer.Status.failed {
                        mediaPlayerState = .error
                    } else if mediaPlayer.status == AVPlayer.Status.readyToPlay {
                        mediaPlayerState = .readyToPlay
                    }
                case "playbackBufferEmpty":
                    if let isBufferEmpty = mediaPlayer.currentItem?.isPlaybackBufferEmpty {
                        if isBufferEmpty {
                            mediaPlayerState = .buffering
                        }
                    }
                case "playbackLikelyToKeepUp":
                    mediaPlayerState = .readyToPlay
                default:
                    break;
                }
                
            }
        }
    }
    
}

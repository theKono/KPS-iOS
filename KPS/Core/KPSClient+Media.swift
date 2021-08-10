//
//  KPSClient+Media.swift
//  KPS
//


import AVFoundation

public enum MediaPlayerState {
    
    case nonSetSource
    case readyToPlay
    case buffering
    case playedToTheEnd
    case error
    
}

public struct KPSAudioContent {
    
    let url: URL
    
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
    
    public func setupRemoteAudioFile() {
        if let url:URL = URL(string: "https://storage.googleapis.com/kps_test/speech/playlist.m3u8"),
           let url2:URL = URL(string: "https://storage.googleapis.com/kps_test/music12/playlist.m3u8") {
            mediaPlayList = getPlayerItem(urls: [url, url2])
        }
    }
    
    
    internal func getPlayerItem(urls: [URL]) -> [KPSAudioContent] {
        var playerList = [KPSAudioContent]()
        for url in urls {
            playerList.append(KPSAudioContent(url: url))
        }
        return playerList
    }
    
    public func playURL(_ url: URL) {

        mediaPlayList = [KPSAudioContent(url: url)]
        
    }
    
    public func openAudioContent(_ resource: KPSContent) {
        
    }
    
    public func openAudioContentWithFolder(_ folder: KPSFolder) {
        
    }
    
    public func mediaPlayerPlay() -> Bool {
        
        if mediaPlayList.count == 0 {
            isMediaPlaying = false
            return false
        }

        mediaPlayer.play()
        isMediaPlaying = true
        
        return true
    }
    
    public func mediaPlayerPlayNext() -> Bool {
        
        if mediaPlayer.items().count == 0 {
            return false
        }
        
        
        if currentTrack + 1 >= mediaPlayList.count {
            mediaPlayerStop()
            
        } else {
            mediaPlayer.advanceToNextItem()
            currentTrack += 1
        }
        
        return true
    }
    
    public func mediaPlayerPlayPrev() -> Bool {
        
        if mediaPlayer.items().count == 0 {
            return false
        }
        
        if currentTrack - 1 < 0 && isMediaPlaying {
            
            mediaPlayer.seek(to: CMTime.zero)
            
        } else if currentTrack - 1 >= 0 {
            currentTrack -= 1
            let previousItem = getAVPlayerItem(source: mediaPlayList[currentTrack])
            let currentItem = getAVPlayerItem(source: mediaPlayList[currentTrack + 1])
            mediaPlayer.pause()
            mediaPlayer.insert(previousItem, after: mediaPlayer.currentItem)
            mediaPlayer.insert(currentItem, after: previousItem)
            mediaPlayer.advanceToNextItem()
            mediaPlayer.play()
        }
        
        return true
    }
    
    public func mediaPlayerPlayForward(_ seconds: TimeInterval)  -> Bool {
        
        if mediaPlayer.currentItem == nil {
            return false
        }
        
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        return mediaPlayerSeekTime(playerCurrentTime + seconds)
        
        
    }
    
    public func mediaPlayerPlayRewind(_ seconds: TimeInterval) -> Bool {
        
        if mediaPlayer.currentItem == nil {
            return false
        }
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        return mediaPlayerSeekTime(playerCurrentTime - seconds)
    }
    
    public func mediaPlayerSeekSegment(_ segmentIndex: Int) -> Bool {
        
        return true
    }
    
    public func mediaPlayerSeekTime(_ time: TimeInterval) -> Bool {
        
        guard let duration = mediaPlayer.currentItem?.duration else { return false }

        let newTime = min( max(0, time), CMTimeGetSeconds(duration) )
        
        let targetTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        mediaPlayer.seek(to: targetTime)
        
        return true
    }
    
    public func mediaPlayerSeekTrack(_ target: KPSAudioContent) -> Bool {
        
        guard mediaPlayList.count > 0 else { return false }
        
        var targetTrackIndex = mediaPlayList.count
        for (idx, item) in mediaPlayList.enumerated() {
            
            if target.url == item.url {
                targetTrackIndex = idx
                break
            }
        }
        
        if targetTrackIndex == mediaPlayList.count {
            return false
        } else {
            
            mediaPlayer.pause()
            mediaPlayer.removeAllItems()
            for idx in targetTrackIndex..<mediaPlayList.count {
                mediaPlayer.insert(getAVPlayerItem(source: mediaPlayList[idx]), after: nil)
            }
            currentTrack = targetTrackIndex
            _ = mediaPlayerPlay()
        }

        return true
    }
    
    public func mediaPlayerPause() {
        
        mediaPlayer.pause()
        isMediaPlaying = false
        
    }
    
    public func mediaPlayerStop() {
    
        mediaPlayer.seek(to: CMTime.zero)
        mediaPlayer.pause()
        mediaPlayer.removeAllItems()
        isMediaPlaying = false
        currentTrack = -1
    }
    
    public func mediaPlayerChangeSpeed(rate: Double) {
        
        mediaPlayer.rate = Float(rate)
        
    }
    
    
    internal func getAVPlayerItem(source: KPSAudioContent) -> AVPlayerItem {
        
        return AVPlayerItem(url: source.url)
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

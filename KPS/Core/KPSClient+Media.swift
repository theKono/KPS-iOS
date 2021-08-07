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


public protocol KPSClientMediaContentDelegate: class {
    
    func kpsClient(client: KPSClient, playerStateDidChange state: MediaPlayerState)
    func kpsClient(client: KPSClient, playerPlayTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval)
    func kpsClient(client: KPSClient, playerIsPlaying playing: Bool)
    func kpsClient(client: KPSClient, playerCurrentTrack trackIndex: Int)
    func kpsClient(client: KPSClient, playerCurrentSegment segmentIndex: Int)
    
}

extension KPSClient {
    
    public func setupTestAudioFile() {
        
        let frameworkBundle = Bundle(for: KPSClient.self)
        print(frameworkBundle)
        if let url = frameworkBundle.resourceURL?.appendingPathComponent("KPS_iOS.bundle/IronBacon.mp3"),
           let url2 = frameworkBundle.resourceURL?.appendingPathComponent("KPS_iOS.bundle/WhatYouWant.mp3"){
            mediaPlayList = getPlayerItem(urls: [url, url2])
            
        } else {
            print("can't find the file")
        }
        
    }
    
    fileprivate func getPlayerItem(urls: [URL]) -> [AVPlayerItem] {
        var playerList = [AVPlayerItem]()
        for url in urls {
            playerList.append(AVPlayerItem(url: url))
        }
        return playerList
    }
    
    public func playURL(_ url: URL) {

        mediaPlayList = [AVPlayerItem(url: url)]
        
    }
    
    public func playAudioContent(_ resource: KPSContent, segment: Int = 0) {
        
    }
    
    public func playAudioContentWithFolder(_ folder: KPSFolder, index: Int = 0) {
        
    }
    
    public func mediaPlayerPlay() {
        
        if mediaPlayer.items().count == 0 {
            setupTestAudioFile()
            currentTrack = 0
        }
        mediaPlayer.play()
        isMediaPlaying = true
    }
    
    public func mediaPlayerPlayNext() {
        
        if currentTrack + 1 >= mediaPlayList.count {
            mediaPlayerStop()
            currentTrack = -1
        } else {
            mediaPlayer.advanceToNextItem()
            currentTrack += 1
        }
    
    }
    
    public func mediaPlayerPlayPrev() {
        
        if currentTrack - 1 < 0 && isMediaPlaying {
            
            mediaPlayer.seek(to: CMTime.zero)
        } else if currentTrack - 1 >= 0 {
            currentTrack -= 1
            let previousItem = mediaPlayList[currentTrack]
            let currentItem = mediaPlayList[currentTrack + 1]
            mediaPlayer.insert(previousItem, after: mediaPlayer.currentItem)
            mediaPlayer.remove(currentItem)
            mediaPlayer.insert(currentItem, after: previousItem)
        }
    }
    
    public func mediaPlayerPlayForward(_ seconds: TimeInterval) {
        
        mediaPlayerSeek(seconds)
        
    }
    
    public func mediaPlayerPlayRewind(_ seconds: TimeInterval) {
        
        mediaPlayerSeek(-seconds)
    }
    
    public func mediaPlayerSeek(_ seconds: TimeInterval) {
        
        guard let duration = mediaPlayer.currentItem?.duration else { return }
        let playerCurrentTime = CMTimeGetSeconds(mediaPlayer.currentTime())
        let newTime = min( max(0, playerCurrentTime + seconds), CMTimeGetSeconds(duration) )

        let targetTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        mediaPlayer.seek(to: targetTime)

    }
    
    public func mediaPlayerPause() {
        
        mediaPlayer.pause()
        isMediaPlaying = false
        
    }
    
    public func mediaPlayerStop() {
    
        mediaPlayer.seek(to: CMTime.zero)
        mediaPlayer.pause()
        isMediaPlaying = false
    }
    
    public func mediaPlayerChangeSpeed(rate: Float) {
        
        mediaPlayer.rate = rate
        
    }
    
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        print("have played all items within the list")
        isMediaPlaying = false
        mediaPlayer.pause()
        mediaPlayer.removeAllItems()
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "currentItem" {
            
            /*
            if let oldItem = change?[NSKeyValueChangeKey.oldKey] as? AVPlayerItem {
            }

            if let newItem = change?[NSKeyValueChangeKey.newKey] as? AVPlayerItem {
            }
            */
        }
    }
    
}

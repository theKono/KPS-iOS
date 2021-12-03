//
//  KPSClientMediaContentDelegateMock.swift
//  KPSTests
//
//  Created by mingshing on 2021/8/8.
//

import Foundation
@testable import KPS

class KPSClientMediaContentDelegateMock: KPSClientMediaContentDelegate {
    
    private(set) var mediaState: MediaPlayerState?
    private(set) var mediaCurrentTime: TimeInterval?
    private(set) var mediaTotalTime: TimeInterval?
    private(set) var isMediaPlaying: Bool?
    private(set) var currentContent: KPSAudioContent?
    private(set) var mediaTrackIndex: Int?
    private(set) var mediaSegmentIndex: Int?
    
    
    func kpsClient(client: KPSClient, playerStateDidChange state: MediaPlayerState) {
        mediaState = state
    }
    
    func kpsClient(client: KPSClient, playerPlayTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        mediaCurrentTime = currentTime
        mediaTotalTime = totalTime
    }
    
    func kpsClient(client: KPSClient, playerIsPlaying playing: Bool) {
        isMediaPlaying = playing
    }
    
    func kpsClient(client: KPSClient, playerCurrentContent content: KPSAudioContent?) {
        currentContent = content
    }
    
    func kpsClient(client: KPSClient, playerCurrentTrack trackIndex: Int) {
        mediaTrackIndex = trackIndex
    }
    
    func kpsClient(client: KPSClient, playerCurrentSegment segmentIndex: Int) {
        mediaSegmentIndex = segmentIndex
    }
    
    
}

//
//  KPSClientMediaTests.swift
//  KPSTests
//
//  Created by mingshing on 2021/8/8.
//

import XCTest
import AVFoundation
@testable import KPS

class KPSClientMediaTests: XCTestCase {
    
    let appKey = "test_key"
    let appId = "test_id"
    let kpsAPIVersion = "test"
    
    var sut: KPSClient!
    var mockMediaDelegate = KPSClientMediaContentDelegateMock()
    
    override func setUp() {
        sut = KPSClient(apiKey: appKey, appId: appId)
        
        sut.mediaContentDelegate = mockMediaDelegate
    }
    
    override func tearDown() {
        sut.mediaPlayerStop()
    }
    
    func testFetchAudioContent() {
        
    }
    
    func testopenAudioContentWithFolder() {
        
    }
    
    func testClientMediaPlaySuccess() {
        
        let testAudioFiles = mockTestAudioFiles()
        sut.mediaPlayList = testAudioFiles
        sut.mediaPlayerPlay()
        XCTAssertTrue(sut.isMediaPlaying)
        XCTAssertEqual(sut.mediaPlayer.items().count, sut.mediaPlayList.count)
        
        XCTAssertEqual(mockMediaDelegate.isMediaPlaying, true)
        XCTAssertEqual(mockMediaDelegate.mediaTrackIndex, 0)
        XCTAssertNotNil(mockMediaDelegate.currentContent)
        XCTAssertEqual(mockMediaDelegate.currentContent?.streamingUrl, testAudioFiles[0].streamingUrl)
        
        eventually(timeout: 0.5) {
            XCTAssertEqual(self.mockMediaDelegate.mediaState, .readyToPlay)
            XCTAssertNotNil(self.mockMediaDelegate.mediaCurrentTime)
            XCTAssertNotNil(self.mockMediaDelegate.mediaTotalTime)
        }
    }
    
    func testClientMediaPlayFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlay()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    func testClientMediaPlayNextSuccess() {
        
        let testAudioFiles = mockTestAudioFiles()
        sut.mediaPlayList = testAudioFiles
        sut.mediaPlayerPlay()
        
        sut.mediaPlayerPlayNext()
        XCTAssertEqual(mockMediaDelegate.mediaTrackIndex, 1)
        XCTAssertNotNil(mockMediaDelegate.currentContent)
        XCTAssertEqual(mockMediaDelegate.currentContent?.streamingUrl, testAudioFiles[1].streamingUrl)
        
        for _ in 1..<testAudioFiles.count {
            sut.mediaPlayerPlayNext()
        }
        XCTAssertEqual(mockMediaDelegate.mediaTrackIndex, -1, "Reach the playlist end, the current track should be -1")
        XCTAssertNil(mockMediaDelegate.currentContent, "Current content should be nil")
        XCTAssertFalse(sut.isMediaPlaying, "Reach the playlist end, the media player should stop playing")
        
    }
    
    func testClientMediaPlayNextFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlayNext()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    
    func testClientMediaPlayPauseSuccess() {
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerSeekTime(10)
        sut.mediaPlayerPlay()
        
        sut.mediaPlayerPause()
        XCTAssertFalse(self.sut.isMediaPlaying)
        XCTAssertEqual(self.mockMediaDelegate.isMediaPlaying, false)
        
        eventually(timeout: 0.5) {
            let pauseTime = self.mockMediaDelegate.mediaCurrentTime

            self.eventually(timeout: 0.5) {
                XCTAssertEqual(self.mockMediaDelegate.mediaCurrentTime, pauseTime)
            }
        }
    }
    

    
    func testClientMediaPlayPreviousSuccess() {
        
        let testAudioFiles = mockTestAudioFiles()
        sut.mediaPlayList = testAudioFiles
        sut.mediaPlayerPlay()
        sut.mediaPlayerPlayNext()
        
        sut.mediaPlayerPlayPrev()
        XCTAssertEqual(mockMediaDelegate.mediaTrackIndex, 0)
        XCTAssertNotNil(mockMediaDelegate.currentContent)
        XCTAssertEqual(mockMediaDelegate.currentContent?.streamingUrl, testAudioFiles[0].streamingUrl)
        
        sut.mediaPlayerPlayPrev()
        XCTAssertEqual(mockMediaDelegate.mediaTrackIndex, 0)
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTime.zero)
        
    }
    
    func testClientMediaPlayPreviousFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlayPrev()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    func testClientMediaPlayForwardSuccess() {
        
        let baseTimeSec = 0.0
        let forwardTimeSec = 10.0
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        sut.mediaPlayerSeekTime(baseTimeSec)
        sut.mediaPlayerPlayForward(forwardTimeSec)
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((baseTimeSec + forwardTimeSec) * 1000 as Float64), timescale: 1000))
        
    }
    
    func testClientMediaPlayForwardFailWithCurrentEmpty() {
        
        
        sut.mediaPlayer.pause()
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerPlayForward(1)
        XCTAssert(true, "Play forward should not crash with empty state")
    }
    
    func testClientMediaPlayRewindSuccess() {
        
        let baseTimeSec = 20.0
        let rewindTimeSec = 10.0
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        sut.mediaPlayerSeekTime(baseTimeSec)
        sut.mediaPlayerPlayRewind(rewindTimeSec)
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((baseTimeSec - rewindTimeSec) * 1000 as Float64), timescale: 1000))
        
        
    }
    
    func testClientMediaPlayRewindFailWithCurrentEmpty() {
        
        sut.mediaPlayer.pause()
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerPlayRewind(1)
        XCTAssert(true, "Play rewind should not crash with empty state")
    }
    
    
    func testClientMediaPlaySeekTime() {
        
        let negativeTime = -1.0
        let normalTime = 1.0
        
        
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        
        sut.mediaPlayerSeekTime(normalTime)
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((normalTime) * 1000 as Float64), timescale: 1000))
        
        sut.mediaPlayerSeekTime(negativeTime)
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTime.zero)
        
    }
    
    func testClientMediaPlaySeekTrackSuccess() {
        
        sut.mediaPlayList = mockTestAudioFiles()
        let seekContent = sut.mediaPlayList.last
        
        XCTAssertTrue(sut.mediaPlayerSeekTrack(seekContent!.id))
        XCTAssertEqual(sut.currentTrack, sut.mediaPlayList.count - 1)
        XCTAssertTrue(sut.isMediaPlaying)

        sut.mediaPlayerPlayNext()
        XCTAssertEqual(sut.currentTrack, -1)
        
    }
    
    func testClientMediaPlaySeekTrackFailWithNotExist() {
        
        sut.mediaPlayList = mockTestAudioFiles()
        let seekContent = KPSAudioContent(url: URL(string: "test_url")!)
        
        XCTAssertFalse(sut.mediaPlayerSeekTrack(seekContent.id))
        
    }
    
    func testClientMediaPlaySeekTrackFailWithEmptyList() {
        
        sut.mediaPlayList.removeAll()
        let seekContent = KPSAudioContent(url: URL(string: "test_url")!)
        
        XCTAssertFalse(sut.mediaPlayerSeekTrack(seekContent.id))
        
    }
    
    func testClientMediaPlayPause() {
        
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        sut.mediaPlayerPause()
        
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    func testClientMediaPlayClear() {
        
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        sut.mediaPlayerReset(isNeedClearPlayList: true)
        
        XCTAssertEqual(sut.mediaPlayer.items().count, 0)
        XCTAssertFalse(sut.isMediaPlaying)
        XCTAssertNil(sut.mediaPlayer.currentItem)
        XCTAssertNil(mockMediaDelegate.currentContent)
        
    }
    
    func testClientMediaChangeSpeed() {
        
        let playerRate = 1.5
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerChangeSpeed(rate: playerRate)
        
        XCTAssertEqual(sut.mediaPlayer.rate, Float(playerRate))
        
    }
    
    
    func testClientMediaPlayFinishNotification() {
        
        sut.mediaPlayList = mockTestAudioFiles()
        sut.mediaPlayerPlay()
        var track = sut.currentTrack
        
        while track < sut.mediaPlayList.count - 1{
            NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
        
            XCTAssertEqual(sut.currentTrack, track + 1)
            track = sut.currentTrack
        }
        NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
        XCTAssertEqual(sut.currentTrack, -1)
        XCTAssertFalse(sut.isMediaPlaying)
    }
    
    
    func mockTestAudioFiles() -> [KPSAudioContent] {
        
        if let url1 = Bundle.current.url(forResource: "IronBacon", withExtension: "mp3"),
           let url2 = Bundle.current.url(forResource: "WhatYouWant", withExtension: "mp3") {
        
            return sut.getPlayerItem(urls: [url1, url2])
        }
        return []
    }
}

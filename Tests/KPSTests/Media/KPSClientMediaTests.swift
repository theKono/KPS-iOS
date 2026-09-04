//
//  KPSClientMediaTests.swift
//  KPSTests
//
//  Created by mingshing on 2021/8/8.
//

import XCTest
import AVFoundation
import Moya
@testable import KPS

class KPSClientMediaTests: XCTestCase {
    
    let appKey = "test_key"
    let appId = "test_id"
    let kpsAPIVersion = "test"
    
    var sut: KPSClient!
    var stubbingProvider: MoyaProvider<CoreAPIService>!
    var mockMediaDelegate = KPSClientMediaContentDelegateMock()
    
    override func setUp() {
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        sut.mediaContentDelegate = mockMediaDelegate
    }
    
    override func tearDown() {
        //sut.mediaPlayerStop()
    }
    // MARK: Fetch data source test
    func testFetchAudioContentSuccess() {
        let testAudioId = "testId"
        sut.fetchAudioContent(audioId: testAudioId) { result in
            
            switch result {
            case .success(let audioContent):
                XCTAssertTrue(audioContent.isFree)
                XCTAssertTrue(audioContent.isPublic)
                XCTAssertEqual(audioContent.type, "audio")
                break
            default: break
            }
            
        }
        
    }
    
    func testFetchAudioContentWithWordTimeSuccess() {
        let testAudioId = "testTrack3"
        sut.fetchAudioContent(audioId: testAudioId) { result in
            
            switch result {
            case .success(let audioContent):
                XCTAssertNil(audioContent.error)
                XCTAssertNil(audioContent.errorDescription)
                XCTAssertEqual(audioContent.id, "testTrack3")
                XCTAssertEqual(audioContent.length, 149)
                XCTAssertEqual(audioContent.streamingUrl?.absoluteString, "https://kps-dev.thekono.com/api/v1/projects/61398d3c62cbe46b8b9e58af/streams/61de651d3940e9000ea36fcf/playlist.m3u8")
                XCTAssertTrue(audioContent.isFree)
                XCTAssertNotNil(audioContent.firstAuthor)
                XCTAssertEqual(audioContent.firstAuthor["zh-TW"], "Kono")
                XCTAssertTrue(audioContent.isPublic)
                XCTAssertEqual(audioContent.type, "audio")
                XCTAssertGreaterThan(audioContent.content.count, 0)
                XCTAssertGreaterThan(audioContent.paragraphContents.count, 0)
                break
            default: break
            }
            
        }
    }
    
    func testFetchAudioContentWithoutPermission() {
        let testAudioId = "audioContentWithoutPermission"
        let customFailedEndpointClosure = { (target: CoreAPIService) -> Endpoint in
            return Endpoint(url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(401, target.sampleData) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }

        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customFailedEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        sut.fetchAudioContent(audioId: testAudioId) { result in
            
            switch result {
            case .success(let audioContent):
                XCTAssertEqual(audioContent.error, .needLogin)
                XCTAssertEqual(audioContent.length, 228.768)
                XCTAssertGreaterThan(audioContent.content.count, 0, "No permission response should have preview content")
                XCTAssertGreaterThan(audioContent.paragraphContents.count, 0, "No permission response should have paragraph")
                break
            default: break
            }
            
        }
    }
    
    func testSetupPlayListFromCollectionSuccess() {
        
        let mockCollection = getMockKPSCollection()
        guard let mockCollection = mockCollection else {
            XCTAssert(false)
            return
        }

        sut.playAudioContents(from: mockCollection)
        let playList = sut.getPlayList()
        
        XCTAssertEqual(playList.count, 3)
    }
    
    
    // MARK: Control playlist related test
    func testClientSetMediaPlayListSuccess() {
        
        let mockCollection = getMockKPSCollection()
        guard let mockCollection = mockCollection else {
            XCTAssert(false)
            return
        }
        let targetTrack: Int = 1
        sut.playAudioContents(from: mockCollection)
        sut.mediaPlayerPlay(targetTrack: targetTrack) { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertTrue((self?.sut.isMediaPlaying ?? false))
            XCTAssertEqual((self?.sut.currentTrack ?? -1), targetTrack)
            XCTAssertNotNil(self?.sut.currentPlayAudioContent)
            XCTAssertEqual(self?.mockMediaDelegate.isMediaPlaying, true)
            XCTAssertEqual(self?.mockMediaDelegate.mediaTrackIndex, targetTrack)
            XCTAssertNotNil(self?.mockMediaDelegate.currentContent)
            XCTAssertEqual(self?.mockMediaDelegate.mediaState, .sourceFetched)
        }
        /*
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
        */
    }
    
    func testClientMediaPlayerWithoutPermissionFirstThenRefresh() {
        setUpMockPlayList()
        let targetTrackIdx: Int = 1
        sut.mediaPlayerPlay(targetTrack: targetTrackIdx)
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerPlay() { [weak self] res in
            XCTAssertEqual(res, true)
            XCTAssertTrue((self?.sut.isMediaPlaying ?? true))
            XCTAssertEqual(self?.sut.currentTrack, targetTrackIdx)
        }
    }
    
    // MARK: Fetch playlist status test
    func testClientMediaPlayerGetTrackOrderSuccess() {
        
        setUpMockPlayList()
        let targetTrackId: String = "testTrack3"
        
        let res = sut.mediaPlayerGetTrackOrder(targetTrackId)
        
        XCTAssertEqual(res, 2)
    }
    
    func testClientMediaPlayerGetTrackOrderNotExisted() {
        
        let mockCollection = getMockKPSCollection()
        guard let mockCollection = mockCollection else {
            XCTAssert(false)
            return
        }
        let targetTrackId: String = "badTrackId"
        sut.playAudioContents(from: mockCollection)
        
        let res = sut.mediaPlayerGetTrackOrder(targetTrackId)
        
        XCTAssertEqual(res, -1)
    }
    
    func testClientMediaPlayerGetTrackOrderFromEmptyList() {
        
        let targetTrackId: String = "testTrack3"
        let res = sut.mediaPlayerGetTrackOrder(targetTrackId)
        
        XCTAssertEqual(res, -1)
    }
    
    // MARK: Control audio player related test
    func testClientMediaPlayFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlay()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    func testClientMediaPlayNextSuccess() {
        
        let mockCollection = getMockKPSCollection()
        guard let mockCollection = mockCollection else {
            XCTAssert(false)
            return
        }
        let targetTrack: Int = 1
        sut.playAudioContents(from: mockCollection)
        sut.mediaPlayerPlay(targetTrack: targetTrack) { res in
            XCTAssertTrue(res)
        }
        
        sut.mediaPlayerPlayNext { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.mockMediaDelegate.mediaTrackIndex, 2)
            XCTAssertNotNil(self?.mockMediaDelegate.currentContent)
            XCTAssertEqual(self?.mockMediaDelegate.currentContent?.id, "testTrack3")
        }
        sut.mediaPlayerPlay(targetTrack: mockCollection.children.count - 1) { res in
            
        }
        sut.mediaPlayerPlayNext { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.mockMediaDelegate.mediaTrackIndex, 0, "Reach the playlist end, the current track should reset to first track")
            XCTAssertNotNil(self?.mockMediaDelegate.currentContent, "Current content should not be nil")
            XCTAssertEqual(self?.sut.isMediaPlaying, false, "Reach the playlist end, the media player should stop playing")
        }
        
    }
    
    func testClientMediaPlayNextFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlayNext()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    
    func testClientMediaPlayPauseSuccess() {
        
        setUpTestAudioFileAndPlay()
        XCTAssertTrue(self.sut.isMediaPlaying)
        XCTAssertEqual(self.mockMediaDelegate.isMediaPlaying, true)
        
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
        
        setUpMockPlayList()
        
        let targetTrack: Int = 1
        sut.mediaPlayerPlay(targetTrack: targetTrack) { res in
            XCTAssertTrue(res)
        }
        
        sut.mediaPlayerPlayPrev { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.mockMediaDelegate.mediaTrackIndex, 0)
            XCTAssertNotNil(self?.mockMediaDelegate.currentContent)
            XCTAssertEqual(self?.mockMediaDelegate.currentContent?.id, "61c96b9de5d8c397e48dfa75")
        }
        sut.mediaPlayerPlay(targetTrack: 0) { res in
            
        }
        sut.mediaPlayerPlayPrev { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.mockMediaDelegate.mediaTrackIndex, 0)
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTime.zero)
        }
    }
    
    func testClientMediaPlayPreviousFailWithPlaylistEmpty() {
        
        sut.mediaPlayList.removeAll()
        
        sut.mediaPlayerPlayPrev()
        XCTAssertFalse(sut.isMediaPlaying)
        
    }
    
    func testClientMediaPlayForwardSuccess() {
        
        let baseTimeSec = 0.0
        let forwardTimeSec = 10.0
        
        setUpTestAudioFileAndPlay()
        sut.mediaPlayerSeekTime(baseTimeSec) { _ in
            
        }
        sut.mediaPlayerPlayForward(forwardTimeSec) { _ in
            
        }
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((baseTimeSec + forwardTimeSec) * 1000 as Float64), timescale: 1000))
        
    }
    
    func testClientMediaPlayForwardFailWithCurrentEmpty() {
        
        
        sut.mediaPlayer.pause()
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerPlayForward(1) { res in
            XCTAssertFalse(res)
        }
        
    }
    
    func testClientMediaPlayRewindSuccess() {
        
        
        let baseTimeSec = 20.0
        let rewindTimeSec = 10.0

        setUpTestAudioFileAndPlay()
        sut.mediaPlayerSeekTime(baseTimeSec) { _ in
            
        }
        sut.mediaPlayerPlayRewind(rewindTimeSec) { _ in
            
        }
        XCTAssertEqual(sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((baseTimeSec - rewindTimeSec) * 1000 as Float64), timescale: 1000))
        
        
    }
    
    func testClientMediaPlayRewindFailWithCurrentEmpty() {
        

        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerPlayRewind(1) { res in
            XCTAssertFalse(res)
        }
    }
    
    
    func testClientMediaPlaySeekTime() {
        
        let negativeTime = -1.0
        let normalTime = 1.0
        
        
        setUpMockPlayList()
        setUpTestAudioFileAndPlay()
        
        sut.mediaPlayerSeekTime(normalTime) { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((normalTime) * 1000 as Float64), timescale: 1000))
        }
        
        
        sut.mediaPlayerSeekTime(negativeTime) { [weak self] res in
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTime.zero)
        }
        
    }
    
    func testClientMediaPlaySeekSegmentSuccess() {
        
        setUpMockPlayList()
        setUpTestAudioFileAndPlay()
        
        // Use the track3(audioContentWithWordTime), tenth sentence as the test data
        let testSentenceStartTime = 78.0
        sut.mediaPlayerPlay(targetTrack: 2)
        
        sut.mediaPlayerSeekSegment(10) { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((testSentenceStartTime) * 1000 as Float64), timescale: 1000))
        }
    }
    
    func testClientMediaPlaySeekSegmentFailedWithoutPlayingItem() {
        
        setUpMockPlayList()
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerSeekSegment(10) { res in
            XCTAssertFalse(res)
        }
        
    }
    
    
    func testClientMediaPlaySeekParagraphSuccessWithoutRange() {
        setUpMockPlayList()
        setUpTestAudioFileAndPlay()
        
        let testParagraphStartTime = 13.0
        // Use the track3, second paragraph as the test data
        sut.mediaPlayerPlay(targetTrack: 2)
        
        sut.mediaPlayerSeekParagraph(1, location: nil) { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((testParagraphStartTime) * 1000 as Float64), timescale: 1000))
        }
        
    }
    
    func testClientMediaPlaySeekParagraphSuccessWithRange() {
        
        setUpMockPlayList()
        setUpTestAudioFileAndPlay()
        
        // Try to make the view sync with the playing audio, we add a magic number to adjust the target time provided by server
        let testTargetTime = 14.5 + 0.02
        let testTouchRange = NSRange(location: 19, length: 2)
        // Use the track3, second paragraph as the test data
        sut.mediaPlayerPlay(targetTrack: 2)
        
        sut.mediaPlayerSeekParagraph(1, location: testTouchRange) { [weak self] res in
            XCTAssertTrue(res)
            XCTAssertEqual(self?.sut.mediaPlayer.currentTime(), CMTimeMake(value: Int64((testTargetTime) * 1000 as Float64), timescale: 1000))
        }
    }
    
    func testClientMediaPlaySeekParagraphFailedWithoutPlayingItem() {
        
        setUpMockPlayList()
        sut.mediaPlayer.removeAllItems()
        
        sut.mediaPlayerSeekParagraph(1, location: nil) { res in
            XCTAssertFalse(res)
        }
        
    }
    
    func testClientMediaPlayClear() {
        
        setUpMockPlayList()
        sut.mediaPlayerPlay(targetTrack: 0)
        XCTAssertNotNil(mockMediaDelegate.currentContent)
        XCTAssertTrue(sut.isMediaPlaying)
        
        sut.mediaPlayerReset(isNeedClearPlayList: true)
        XCTAssertEqual(sut.mediaPlayer.items().count, 0)
        XCTAssertFalse(sut.isMediaPlaying)
        XCTAssertNil(sut.mediaPlayer.currentItem)
        XCTAssertNil(mockMediaDelegate.currentContent)
    }
    
    func testClientMediaChangeSpeed() {
        
        let playerRate = 1.5
        let mockCollection = getMockKPSCollection()
        XCTAssertNotNil(mockCollection)
        sut.playAudioContents(from: mockCollection!)
        sut.mediaPlayerChangeSpeed(rate: playerRate)
        
        XCTAssertEqual(sut.mediaPlayer.rate, Float(playerRate))
        
    }
    
    
    func testClientMediaPlayFinishNotification() {
        
        setUpMockPlayList()
        sut.mediaPlayerPlay(targetTrack: 0) { [weak self] _ in
            self?.setUpTestAudioFileAndPlay()
            var track = self?.sut.currentTrack ?? -1
            
            guard let trackCount = self?.sut.mediaPlayList.count else {
                      XCTAssert(false)
                      return
                      
                  }
            while track < trackCount - 1 {
                NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
            
                XCTAssertEqual(self?.sut.currentTrack, track + 1)
                XCTAssertEqual(self?.sut.isMediaPlaying, true)
                track += 1
            }
            NotificationCenter.default.post(name: .AVPlayerItemDidPlayToEndTime, object: nil)
            XCTAssertEqual(self?.sut.currentTrack, 0, "The media player should auto reset to the first track if we reach the end")
            XCTAssertEqual(self?.sut.isMediaPlaying, false)
        }
    }
    
    
    func testClientMediaUpdateContentPlayDataSuccess() {
        
        setUpMockPlayList()
        
        sut.mediaPlayerPlay(targetTrack: 2) { [weak self] _ in
            
            self?.setUpTestAudioFileAndPlay()
            XCTAssertEqual(self?.sut.isMediaPlaying, true)
            XCTAssertEqual(self?.mockMediaDelegate.isMediaPlaying, true)
/*
            self?.eventually(timeout: 5) {
                XCTAssertEqual(self?.mockMediaDelegate.mediaSegmentIndex, 0)
                XCTAssertEqual(self?.mockMediaDelegate.mediaParagraphIndex, 0)
                XCTAssertNotNil(self?.mockMediaDelegate.mediaHighlightRange)
                //self?.sut.mediaPlayerPause()
            }
*/
        }
    }
    
}

// Create mock object or end point function
extension KPSClientMediaTests {
    
    func setUpTestAudioFileAndPlay() {
        
        if let audioUrl = Bundle.current.url(forResource: "IronBacon", withExtension: "mp3") {
            
            let audioContent = KPSAudioContent(url: audioUrl)
            sut.mediaPlayer.removeAllItems()
            sut.mediaPlayer.insert(sut.getAVPlayerItem(source: audioContent), after: nil)
            sut.mediaPlayerPlayAction()
        }
    }
    
    func setUpMockPlayList() {
        
        let mockCollection = getMockKPSCollection()
        guard let mockCollection = mockCollection else {
            XCTAssert(false)
            return
        }
        sut.playAudioContents(from: mockCollection)
        
    }
    
    func getMockKPSCollection() -> KPSCollection? {
        
        guard let url = Bundle.current.url(forResource: "folderContent", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        
        do {
            let mockCollection = try JSONDecoder().decode(KPSCollection.self, from: data)
            return mockCollection
            
        } catch _ {
            return nil
        }
    }
    
    func customSuccessEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }
    
}

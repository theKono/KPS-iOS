//
//  KPSPlayRecord.swift
//  KPS-iOS
//
//  Created by mingshing on 2021/12/23.
//

import Foundation

public class KPSPlayRecord {
    public let collectionId: String?
    public let collectionName: [String: String]?
    public let trackName: [String: String]
    public let trackId: String
    public var playSpeed: Float
    public var startTime, endTime, length: Double
    private var playedTime: Set<Int>
    
    init(info: KPSAudioContent, rate: Float) {
        collectionId = info.collectionId
        collectionName = info.collectionName
        trackName = info.name
        trackId = info.id
        playSpeed = rate
        startTime = 0.0
        endTime = 0.0
        length = info.length ?? 0.0
        playedTime = Set()
    }
    public var duration: Double {
        return Double(playedTime.count) / 10.0
    }
    
    internal func addPlayedTimeSlot(_ timeIndex: Int) {
        playedTime.insert(timeIndex)
    }
}

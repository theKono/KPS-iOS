//
//  KPSClient+Analytic.swift
//  KPS-iOS
//
//  Created by mingshing on 2021/12/21.
//


public protocol KPSClientAnalyticDelegate: AnyObject {
    
    func kpsClient(client: KPSClient, playedRecord record: KPSPlayRecord)
    
}

extension KPSClient {
    
    func uploadPlayedRecord() {
        guard let playedRecord = currentPlayRecord else { return }
        
        // TODO: upload data to our own server
        self.analyticDelegate?.kpsClient(client: self, playedRecord: playedRecord)
        
        currentPlayRecord = nil
    }
}

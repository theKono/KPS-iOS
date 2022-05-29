//
//  KPSUtility.swift
//  KPS
//

import Foundation
import DeviceKit

public final class KPSUtiltiy {

    public init() {}
    
    static func getLocalReceiptData() -> Data? {
        
        guard let localReceiptPath = Bundle.main.appStoreReceiptURL?.path else { return nil }
        if FileManager.default.fileExists(atPath: localReceiptPath) {
            if let receiptData = FileManager.default.contents(atPath: localReceiptPath) {
                return receiptData
            }
        }
        return nil
    }
    
    static var deviceIsPad: Bool {
        return Device.current.isPad
    }
    
    static var deviceIsPhone: Bool {
        return Device.current.isPhone
    }
}

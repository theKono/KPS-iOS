//
//  KPSPurchaseReceiptManager.swift
//  KPS
//
//  Created by mingshing on 2022/3/18.
//

import Foundation
import StoreKit

class ReceiptRefreshRequestFactory {

    func receiptRefreshRequest() -> SKReceiptRefreshRequest {
        return SKReceiptRefreshRequest()
    }
}

class KPSPurchaseReceiptManager: NSObject {
    
    private let requestFactory: ReceiptRefreshRequestFactory
    private let receiptParser: ReceiptParser
    private var receiptRefreshRequest: SKRequest?
    private var receiptRefreshCompletionHandlers: [() -> Void]

    public var localReceipt: AppleReceipt? {
        guard let receiptData = KPSUtiltiy.getLocalReceiptData() else { return nil }
        do {
            let receipt = try receiptParser.parse(from: receiptData)
            return receipt
        } catch {
            print("local receipt parse error")
            return nil
        }
    }
    
    init(requestFactory: ReceiptRefreshRequestFactory = ReceiptRefreshRequestFactory(),
         receiptParser: ReceiptParser = ReceiptParser()) {
        self.requestFactory = requestFactory
        self.receiptParser = receiptParser
        receiptRefreshRequest = nil
        receiptRefreshCompletionHandlers = []
    }

    func fetchReceiptData(_ completion: @escaping () -> Void) {
        
        self.receiptRefreshCompletionHandlers.append(completion)

        if self.receiptRefreshRequest == nil {
            self.receiptRefreshRequest = self.requestFactory.receiptRefreshRequest()
            self.receiptRefreshRequest?.delegate = self
            self.receiptRefreshRequest?.start()
        }
    }
}

extension KPSPurchaseReceiptManager: SKRequestDelegate {

    public func requestDidFinish(_ request: SKRequest) {
        guard request is SKReceiptRefreshRequest else { return }

        finishReceiptRequest(request)
        request.cancel()
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        guard request is SKReceiptRefreshRequest else { return }
        
        finishReceiptRequest(request)
        request.cancel()
    }

}

private extension KPSPurchaseReceiptManager {

    func finishReceiptRequest(_ request: SKRequest?) {
        
        self.receiptRefreshRequest = nil
        let completionHandlers = self.receiptRefreshCompletionHandlers
        self.receiptRefreshCompletionHandlers = []

        for handler in completionHandlers {
            handler()
        }
    }
}

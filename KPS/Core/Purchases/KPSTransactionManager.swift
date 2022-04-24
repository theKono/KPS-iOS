//
//  KPSTransactionManager.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//

import Foundation
import StoreKit

protocol KPSTransactionManagerDelegate: AnyObject {

    func transactionManager(_ transactionManager: KPSTransactionManager, updatedTransaction transaction: SKPaymentTransaction)

    func transactionManager(_ transactionManager: KPSTransactionManager, removedTransaction transaction: SKPaymentTransaction)

    func transactionManager(_ transactionManager: KPSTransactionManager,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String])

}

class KPSTransactionManager: NSObject, SKPaymentTransactionObserver {

    /**
     * Set this property to true *only* when testing the ask-to-buy / SCA purchases flow. More information:
     * - Seealso: https://support.apple.com/en-us/HT201089
     */
    static var simulatesAskToBuyInSandbox = false

    weak var delegate: KPSTransactionManagerDelegate? {
        didSet {
            if delegate != nil {
                paymentQueue.add(self)
            } else {
                paymentQueue.remove(self)
            }
        }
    }

    private var paymentQueue: SKPaymentQueue

    init(paymentQueue: SKPaymentQueue) {
        self.paymentQueue = paymentQueue
    }

    override convenience init() {
        self.init(paymentQueue: .default())
    }

    deinit {
        paymentQueue.remove(self)
    }

    func add(_ payment: SKPayment) {
        paymentQueue.add(payment)
    }

    func finishTransaction(_ transaction: SKPaymentTransaction) {
        paymentQueue.finishTransaction(transaction)
    }
    
    @available(iOS 14.0, *)
    func presentCodeRedemptionSheet() {
        paymentQueue.presentCodeRedemptionSheet()
    }

    func payment(withProduct product: SK1Product) -> SKMutablePayment {
        
        let payment = SKMutablePayment(product: product)
        payment.simulatesAskToBuyInSandbox = Self.simulatesAskToBuyInSandbox
        
        return payment
    }

    
    func payment(withProduct product: SK1Product, discount: SKPaymentDiscount) -> SKMutablePayment {
        let payment = self.payment(withProduct: product)
        payment.paymentDiscount = discount
        return payment
    }

}

extension KPSTransactionManager: SKPaymentQueueDelegate {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        let latestTransaction = transactions.sorted {
            $0.transactionDate ?? Date() > $1.transactionDate ?? Date()
        }.first
        
        
        guard let updatedTransaction = latestTransaction else { return }
        delegate?.transactionManager(self, updatedTransaction: updatedTransaction)
        
        for transaction in transactions {
            if transaction.transactionState != .purchasing {
                finishTransaction(transaction)
            }
        }
        
    }

    // Sent when transactions are removed from the queue (via finishTransaction:).
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
    
            delegate?.transactionManager(self, removedTransaction: transaction)
        }
    }

    // Sent when a user initiated an in-app purchase from the App Store.
    // check if we need to show the purchase dialog
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        
        return true
    }

    // Sent when access to a family shared subscription is revoked from a family member or canceled the subscription.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func paymentQueue(_ queue: SKPaymentQueue,
                      didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        
        delegate?.transactionManager(self, didRevokeEntitlementsForProductIdentifiers: productIdentifiers)
    }

}


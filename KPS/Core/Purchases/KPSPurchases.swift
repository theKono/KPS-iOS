//
//  KPSPurchases.swift
//  KPS
//
//  Created by mingshing on 2022/3/9.
//

import Foundation
import StoreKit

// MARK: Block definitions
/**
 Completion block for ``Purchases/purchase(product:completion:)``
 */
public typealias PurchaseCompletedBlock = (KPSPurchaseItem?, KPSPurchaseError?) -> Void

/**
 Deferred block for ``Purchases/shouldPurchasePromoProduct(_:defermentBlock:)``
 */
public typealias DeferredPromotionalPurchaseBlock = (@escaping PurchaseCompletedBlock) -> Void

// MARK: Error definitions
public enum KPSPurchaseError: Swift.Error {
    case duplicateRequest
    case clientInvalid
    case paymentCancel
    case paymentInvalid
    case paymentNotAllowed
    case productNotAvailable
    case productAlreadyPurchased
    case ownServer
    case network
    case unknown
    
    public var errorDescription: String {
        switch self {
        case .duplicateRequest:
            return "購買程序正在進行中"
        case .clientInvalid:
            return "當前蘋果帳戶無法購買商品"
        case .paymentCancel:
            return "訂單已取消"
        case .paymentInvalid:
            return "訂單無效"
        case .paymentNotAllowed:
            return "當前蘋果設備無法購買商品(如有疑問，可以詢問蘋果客服)"
        case .productNotAvailable:
            return "當前購買選項不可用"
        case .productAlreadyPurchased:
            return "您目前正在訂閱期間"
        case .ownServer:
            return "伺服器連接錯誤"
        case .network:
            return "網路無法正常連接"
        case .unknown:
            return "未知的錯誤，您可能正在使用越獄手機"
        }
    }
}



/**
 * `Purchases` is the entry point. It should be instantiated as soon as your app has a unique
 * user id for your user. This can be when a user logs in if you have accounts or on launch if you can generate a random
 * user identifier.
 *  - Warning: Only one instance of Purchases should be instantiated at a time! Use a configure method to let the
 *  framework handle the singleton instance for you.
 */
public class KPSPurchases: NSObject {


    /// Returns the already configured instance of `Purchases`.
    /// - Note: this method will crash with `fatalError` if `Purchases` has not been initialized through `configure()`.
    ///         If there's a chance that may have not happened yet, you can use ``isConfigured``
    ///         to check if it's safe to call.
    /// - Seealso: ``isConfigured``.
    @objc(sharedPurchases)
    public static var shared: KPSPurchases {
        guard let purchases = purchases else {
            fatalError(Strings.purchase.purchases_nil.description)
        }

        return purchases
    }
    private static var purchases: KPSPurchases?

    /// Returns `true` if it has already been intialized through `configure()`.
    public static var isConfigured: Bool { purchases != nil }

    /**
     * Delegate for `Purchases` instance. The delegate is responsible for handling promotional product purchases and
     * changes to customer information.
     */
    public var delegate: KPSPurchasesDelegate? {
        get { privateDelegate }
        set {
            guard newValue !== privateDelegate else {
                print(Strings.purchase.purchases_delegate_set_multiple_times)
                return
            }

            if newValue == nil {
                print(Strings.purchase.purchases_delegate_set_to_nil)
            }

            privateDelegate = newValue
        }
    }

    private weak var privateDelegate: KPSPurchasesDelegate?
    private var purchaseItem: KPSPurchaseItem?
    private var verifyCompleteBlock: PurchaseCompletedBlock?
    /**
     * Indicates whether the user is allowed to get trial period.
     */
    public var trailEligible: Bool {
        guard let receipt = self.receiptManager.localReceipt else {return true}
        
        return receipt.inAppPurchases.count == 0
    }

    /**
     * Indicates whether the user is allowed to make payments.
     */
    public static func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }

    
    private let notificationCenter: NotificationCenter
    private let productManager: KPSPurchaseProductManager
    private let transactionManager: KPSTransactionManager
    private let identityManager: IdentityManager
    private let receiptManager: KPSPurchaseReceiptManager
    private let serverUrl: String
    private var isUserPurchasing: Bool
    fileprivate static let initLock = NSLock()


    init(serverUrl: String,
         productManager: KPSPurchaseProductManager = KPSPurchaseProductManager(),
         transactionManager: KPSTransactionManager = KPSTransactionManager(),
         identityManager: IdentityManager,
         receiptManager: KPSPurchaseReceiptManager = KPSPurchaseReceiptManager(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        
        self.serverUrl = serverUrl
        self.notificationCenter = notificationCenter
        self.productManager = productManager
        self.transactionManager = transactionManager
        self.receiptManager = receiptManager
        self.identityManager = identityManager
        self.isUserPurchasing = false
        super.init()
        
        self.transactionManager.delegate = self
        self.receiptManager.fetchReceiptData() {
            
        }
    }

    /**
     * Automatically collect subscriber attributes associated with the device identifiers
     * $idfa, $idfv, $ip
     
    @objc public func collectDeviceIdentifiers() {
        subscriberAttributesManager.collectDeviceIdentifiers(forAppUserID: appUserID)
    }
     */
    
    deinit {
        notificationCenter.removeObserver(self)
        
        privateDelegate = nil
    }

    static func clearSingleton() {
        Self.purchases = nil
    }

    static func setDefaultInstance(_ purchases: KPSPurchases) {
        initLock.lock()

        self.purchases = purchases
        initLock.unlock()
    }

}


// MARK: Purchasing
public extension KPSPurchases {

    /**
     * Fetches the `KPSPurchaseItem` for your IAPs for given `productIdentifiers`.
     *
     * - Note: `completion` may be called without `KPSPurchaseItem`s that you are expecting. This is usually caused by
     * iTunesConnect configuration errors. Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have signed the latest paid
     * application agreements.
     *
     * - Parameter productIdentifiers: A set of product identifiers for in app purchases setup via AppStoreConnect:
     * https://appstoreconnect.apple.com/
     * This should be either hard coded in your application, from a file, or from a custom endpoint if you want
     * to be able to deploy new IAPs without an app update.
     * - Parameter completion: An @escaping callback that is called with the loaded products.
     * If the fetch fails for any reason it will return an empty array.
     */
    func getProducts(_ productIdentifiers: [String], useCache: Bool = true, completion: @escaping (Result<Set<KPSPurchaseItem>, Error>) -> Void) {
        productManager.products(withIdentifiers: productIdentifiers, completion: completion)
    }


    

    /**
     * Purchase the passed ``KPSPurchaseItem``.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will
     * handle this for you.
     *
     * - Parameter item: The ``KPSPurchaseItem`` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `KPSPurchaseItem` and a ``CustomerInfo``.
     *
     * If the purchase was not successful, there will be an `Error`.
     */
    func purchase(item: KPSPurchaseItem, completion: @escaping PurchaseCompletedBlock) {
        
        self.isUserPurchasing = true
        
        if verifyCompleteBlock != nil {
            completion(nil, .duplicateRequest)
            return
        }
        
        if let product = item.sk1Product {
            let payment = transactionManager.payment(withProduct: product)
            transactionManager.add(payment)
            self.purchaseItem = item
            self.verifyCompleteBlock =  completion
        }
    }


    /**
     * Purchase the passed ``KPSPurchaseItem``.
     * Call this method when a user has decided to purchase a product with an applied discount. Only call this in
     * direct response to user input. From here `Purchases` will handle the purchase with `StoreKit` and call the
     * `PurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback, Purchases will handle
     * this for you.
     *
     * - Parameter package: The ``KPSPurchaseItem`` the user intends to purchase
     * - Parameter discount: The `StoreProductDiscount` to apply to the purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     *
     * If the purchase was successful there will be a `StoreTransaction` and a ``CustomerInfo``.
     * If the purchase was not successful, there will be an `Error`.
     
    func purchase(item: KPSPurchaseItem, discount: StoreProductDiscount, completion: @escaping PurchaseCompletedBlock) {
        
    }
     */

    /**
     * This method will post all purchases associated with the current App Store account to Server
     * 
     */
    func restorePurchases(completion: PurchaseCompletedBlock? = nil) {
        if verifyCompleteBlock != nil {
            completion?(nil, .duplicateRequest)
            return
        }
        
        verifyCompleteBlock = completion
        receiptManager.fetchReceiptData {
            print(self.receiptManager.localReceipt)
            self.uploadLocalReceipt()
        }
    }



    /**
     * Use this function to open the manage subscriptions page.
     * Open App Store's subscription management section will be opened.
     *
     * - Parameter completion: A completion block that is called when the modal is closed.
     * If it was not successful, there will be an `Error`.
     */
    func showManageSubscriptions() {
        //purchasesOrchestrator.showManageSubscription(completion: completion)
        
        let subscriptionURL = URL.init(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions")!
        // itms-apps://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions
        UIApplication.shared.open(subscriptionURL)
        
    }
}

// MARK: Purchase status and record
public extension KPSPurchases {

    /**
     * Fetches the `KPSPurchaseRecord`
     *
     */
    func getPurchaseRecords() {
        
    }
    
    func getPurchaseStatus() -> CustomerSubscriptionStatus {
        return identityManager.subscriptionStatus
    }


}
// MARK: Configuring Purchases
public extension KPSPurchases {

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults. Use this constructor if you want to
     * sync status across a shared container, such as between a host app and an extension. The instance of the
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter endpointURL: The backend server endpoint use to verify the purchase receipt and grant the content permission
     *
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @discardableResult static func configure(withServerUrl endpointUrl: String) -> KPSPurchases {
        let identityManager = IdentityManager(serverUrl: endpointUrl)
        let purchases = KPSPurchases(serverUrl: endpointUrl, identityManager: identityManager)
        setDefaultInstance(purchases)
        return purchases
    }
}

// MARK: Transaction
extension KPSPurchases: KPSTransactionManagerDelegate {

    func transactionManager(_ transactionManager: KPSTransactionManager, updatedTransaction transaction: SKPaymentTransaction) {
        switch transaction.transactionState {
        case .restored, // for observer mode
             .purchased:
            handlePurchasedTransaction(transaction)
        case .purchasing:
            break
        case .failed:
            handleFailedTransaction(transaction)
        case .deferred:
            handleDeferredTransaction(transaction)
        @unknown default:
            print("unhandled transaction state!")
        }
    }

    func transactionManager(_ transactionManager: KPSTransactionManager,
                         removedTransaction transaction: SKPaymentTransaction) {
        // unused for now
    }

    func transactionManager(_ transactionManager: KPSTransactionManager,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        // unused for now
    }
}

private extension KPSPurchases {

    func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        print(self.receiptManager.localReceipt)
        if isUserPurchasing {
            uploadLocalReceipt()
        }
    }

    func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        
        if let error = transaction.error {
            let nsError = error as NSError
            switch nsError.code {
            case SKError.unknown.rawValue:
                if let errorInfo = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                    switch (errorInfo.domain, errorInfo.code) {
                    case ("ASDServerErrorDomain", 3532):
                        uploadLocalReceipt()
                        return
                    default:
                        self.verifyCompleteBlock?(purchaseItem, .unknown)
                        break
                    }
                }
                
            case SKError.clientInvalid.rawValue:
                self.verifyCompleteBlock?(purchaseItem, .clientInvalid)
            case SKError.paymentCancelled.rawValue:
                self.verifyCompleteBlock?(purchaseItem, .paymentCancel)
            case SKError.paymentInvalid.rawValue:
                self.verifyCompleteBlock?(purchaseItem, .paymentInvalid)
            case SKError.paymentNotAllowed.rawValue:
                self.verifyCompleteBlock?(purchaseItem, .paymentNotAllowed)
            case SKError.storeProductNotAvailable.rawValue:
                self.verifyCompleteBlock?(purchaseItem, .productNotAvailable)
            default:
                self.verifyCompleteBlock?(purchaseItem, .network)
            }
            
        }
        self.verifyCompleteBlock = nil
        self.purchaseItem = nil
        self.isUserPurchasing = false
    }

    func handleDeferredTransaction(_ transaction: SKPaymentTransaction) {
        
    }

}

// MARK: Private communicate with our own server
private extension KPSPurchases {
    
    func uploadLocalReceipt() {

        if let base64ReceiptData = KPSUtiltiy.getLocalReceiptData() {
            let base64Receipt = base64ReceiptData.base64EncodedString()

            PurchaseAPIServiceProvider.request(.uploadReceipt(receipt: base64Receipt, version: 1, serverUrl: self.serverUrl)) { [weak self] result in
                
                defer {
                    self?.verifyCompleteBlock = nil
                    self?.purchaseItem = nil
                    self?.isUserPurchasing = false
                }
                switch result {
                case let .success(response):
                    do {
                        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                        let _ = String(decoding: filteredResponse.data, as: UTF8.self)
                        
                        self?.identityManager.updatePaymentStatus()
                        
                        if let verifyCompleteBlock = self?.verifyCompleteBlock {
                            verifyCompleteBlock(self?.purchaseItem, nil)
                        }
                        
                    } catch _ {
                        
                        let errorResponse = String(decoding: response.data, as: UTF8.self)
                        print("[API Error: \(#function)] \(errorResponse)")
                        self?.verifyCompleteBlock?(self?.purchaseItem, .ownServer)
                    }
                case .failure(let error):
                    print(error.errorDescription ?? "")
                    self?.verifyCompleteBlock?(self?.purchaseItem, .ownServer)
                }
            }
        }
        else {
            verifyCompleteBlock?(purchaseItem, .unknown)
            verifyCompleteBlock = nil
            purchaseItem = nil
        }
    }
}


// MARK: Private
private extension KPSPurchases {

    @objc func applicationDidBecomeActive(notification: Notification) {
        
        syncSubscriberAttributesIfNeeded()
    }

    @objc func applicationWillResignActive(notification: Notification) {
        syncSubscriberAttributesIfNeeded()
    }

    func subscribeToAppStateNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(applicationDidBecomeActive(notification:)),
                                       name: UIApplication.didBecomeActiveNotification, object: nil)

        notificationCenter.addObserver(self,
                                       selector: #selector(applicationWillResignActive(notification:)),
                                       name: UIApplication.willResignActiveNotification, object: nil)
    }

    func syncSubscriberAttributesIfNeeded() {
        
    }

}

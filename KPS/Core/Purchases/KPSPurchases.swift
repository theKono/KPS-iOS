//
//  KPSPurchases.swift
//  KPS
//
//  Created by mingshing on 2022/3/9.
//

import Foundation
import StoreKit
import Moya

// MARK: Block definitions
/**
 Completion block for ``Purchases/purchase(product:completion:)``
 */
public typealias PurchaseCompletedBlock = (KPSPurchaseItem?, Bool, KPSPurchaseError?) -> Void

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
    case receiptExpire
    case sessionInvalid
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
        case .receiptExpire:
            return "有效期限已過期"
        case .sessionInvalid:
            return "請嘗試重新登入後再次購買"
        case .unknown:
            return "未知的錯誤，您可能正在使用越獄手機"
        }
    }
}


// MARK: KPS Purchase Service Env
public enum KPSPurchaseEnv {
    
    case dev
    case stg
    case prd
    
    var baseUrl: String {
        switch self{
        case .dev:
            return "https://kps-dev.thekono.com/api/v1/projects/"
        case .stg:
            return "https://kps-stg.thekono.com/api/v1/projects/"
        case .prd:
            return "https://kps.thekono.com/api/v1/projects/"
        }
    }
    
    var sessionKey: String {
        return "kps_session"
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
    public weak var delegate: KPSPurchasesDelegate?

    private var purchaseItem: KPSPurchaseItem?
    private var verifyCompleteBlock: PurchaseCompletedBlock?
    
    /**
     * Indicates whether the user is allowed to get trial period.
     */
    public var trailEligible: Bool {
        guard let receipt = self.receiptManager.localReceipt else {return true}
        
        return receipt.inAppPurchases.count == 0 && self.productManager.hasIntroductoryOfferProduct
    }
    
    /**
     * Indicates the trail period days
     */
    public var introductoryOfferDays: Int {
        return self.productManager.introductoryOfferDays
    }

    public var customerType: CustomerType = .Unknown {
        didSet {
            
            if oldValue != customerType {

                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSPurchaseCustomerTypeChanged"), object: nil, userInfo: ["customerType": customerType])
            }
            delegate?.kpsPurchase(purchase: self, customerTypeDidChange: customerType)
        }
    }
    
    /**
     * Indicates whether the user is allowed to make payments.
     */
    public static func canMakePayments() -> Bool { SKPaymentQueue.canMakePayments() }

    
    private let notificationCenter: NotificationCenter
    private let contentServer: KPSClient
    private let productManager: KPSPurchaseProductManager
    private let transactionManager: KPSTransactionManager
    private let subscriptionManager: SubscriptionManager
    private let receiptManager: KPSPurchaseReceiptManager
    private let couponManager: KPSCouponManager
    private let serverUrl: String
    private let apiServiceProvider: MoyaProvider<PurchaseAPIService>
    
    private static var networkProvider: MoyaProvider<PurchaseAPIService> = MoyaProvider<PurchaseAPIService>(endpointClosure: KPSPurchases.customizeEndpoint)
    private static let customizeEndpoint = { (target: PurchaseAPIService) -> Endpoint in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        
        guard let sessionToken = KPSPurchases.sessionToken,
            let sessionKey = KPSPurchases.sessionKey else { return defaultEndpoint }
        switch target {
        case .fetchProductIds:
            return defaultEndpoint
        default:
            return defaultEndpoint.adding(newHTTPHeaderFields: [sessionKey: sessionToken])
        }
    }
    private static var sessionKey: String? {
        get {
            return UserDefaults.standard.string(forKey: "kps_purhcase_session_key")
        }
        set(newToken) {
            guard let token = newToken else {
                UserDefaults.standard.removeObject(forKey: "kps_purhcase_session_key")
                return
            }
            UserDefaults.standard.set(token, forKey: "kps_purhcase_session_key")
        }
    }
    
    private static var sessionToken: String? {
        get {
            return UserDefaults.standard.string(forKey: "kps_purhcase_session_token")
        }
        set(newToken) {
            guard let token = newToken else {
                UserDefaults.standard.removeObject(forKey: "kps_purhcase_session_token")
                return
            }
            UserDefaults.standard.set(token, forKey: "kps_purhcase_session_token")
        }
    }
    
    
    private var isUserPurchasing: Bool
    fileprivate static let initLock = NSLock()


    init(serverUrl: String,
         apiServiceProvider: MoyaProvider<PurchaseAPIService> = KPSPurchases.networkProvider,
         contentServer: KPSClient = KPSClient.shared,
         productManager: KPSPurchaseProductManager = KPSPurchaseProductManager(),
         transactionManager: KPSTransactionManager = KPSTransactionManager(),
         receiptManager: KPSPurchaseReceiptManager = KPSPurchaseReceiptManager(),
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        
        self.serverUrl = serverUrl
        self.apiServiceProvider = apiServiceProvider
        self.contentServer = contentServer
        self.notificationCenter = notificationCenter
        self.productManager = productManager
        self.transactionManager = transactionManager
        self.receiptManager = receiptManager
        self.subscriptionManager = SubscriptionManager(serverUrl: serverUrl, apiServiceProvider: KPSPurchases.networkProvider)
        self.couponManager = KPSCouponManager(serverUrl: serverUrl, apiServiceProvider: KPSPurchases.networkProvider)
        self.isUserPurchasing = false
        super.init()
        
        SKPaymentQueue.default().add(self.transactionManager)
        self.transactionManager.delegate = self
        syncPaymentStatus()
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
        
    }

    static func clearSingleton() {
        Self.purchases = nil
    }

    static func setDefaultInstance(_ purchases: KPSPurchases) {
        initLock.lock()

        self.purchases = purchases
        initLock.unlock()
    }
    
    public func syncPaymentStatus(_ completion: (()->Void)? = nil) {
        
        let group = DispatchGroup()
        group.enter()
        self.receiptManager.fetchReceiptData() {
            group.leave()
        }
        
        group.enter()
        self.subscriptionManager.updatePaymentStatus {
            group.leave()
        }
        
        group.enter()
        contentServer.fetchPermissions { _ in
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.updateCurrentCustomerType()
            completion?()
        }
    }
    
    public func updateSessionToken(_ token: String?) {
        KPSPurchases.sessionToken = token
    }
}


// MARK: Purchasing
public extension KPSPurchases {

    /**
     * Fetches the `productIdentifiers` for our custom endpoint has been set.
     *
     * - Note: `completion` may be called without `productIdentifier` that you are expecting. This is usually caused by
     * there are no correct configuration on the custom endpoint.
     *
     * - Parameter completion: An @escaping callback that is called with the available productIdentifiers.
     * If the fetch fails for any reason it will return an empty array.
     */
    func getProductIdentifiers(completion: @escaping (Result<Set<String>, Error>) -> Void) {
        
        apiServiceProvider.request(.fetchProductIds(serverUrl: self.serverUrl)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let productIdResponse = try JSONDecoder().decode(ProductIdsResponse.self, from: filteredResponse.data)
                    
                    //DEBUG
                    //let response = String(decoding: response.data, as: UTF8.self)
                    //print(response)
                    if let productIds = productIdResponse.productIds {
                        completion(.success(Set(productIds)))
                    } else {
                        completion(.success([]))
                    }

                } catch {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    completion(.success([]))
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion(.failure(error))
                
            }
        }
    }

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
     * If the purchase was successful there will be a ``KPSPurchaseItem``.
     *
     * If the purchase was not successful, there will be an `Error`.
     */
    func purchase(item: KPSPurchaseItem, completion: @escaping PurchaseCompletedBlock) {
        
        self.isUserPurchasing = true
        
        if verifyCompleteBlock != nil {
            completion(nil, false, .duplicateRequest)
            return
        }
        
        if let product = item.sk1Product {
            let payment = transactionManager.payment(withProduct: product)
            transactionManager.add(payment)
            self.purchaseItem = item
            self.verifyCompleteBlock = completion
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
     * If the purchase was successful there will be a `StoreTransaction`.
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
            completion?(nil, false, .duplicateRequest)
            return
        }
        
        verifyCompleteBlock = completion
        receiptManager.fetchReceiptData {
            //print(self.receiptManager.localReceipt)
            self.uploadLocalReceipt()
        }
    }


    @available(iOS 14.0, *)
    func presentCodeRedemptionSheet() {
        transactionManager.presentCodeRedemptionSheet()
    }
    

    /**
     * Use this function to open the manage subscriptions page.
     * Open App Store's subscription management section will be opened.
     *
     * - Parameter completion: A completion block that is called when the modal is closed.
     * If it was not successful, there will be an `Error`.
     */
    func showManageSubscriptions() {
        
        guard let subscriptionProvider = subscriptionManager.latestOrder?.provider else { return }
        
        switch subscriptionProvider {
        case .ios:
            let subscriptionURL = URL.init(string: "https://apps.apple.com/account/subscriptions")!
            UIApplication.shared.open(subscriptionURL)
        case .android:
            let subscriptionURL = URL.init(string: "https://play.google.com/store/account/subscriptions")!
            UIApplication.shared.open(subscriptionURL)
        default:
            break
        }
    }
}

// MARK: Purchase status and record
public extension KPSPurchases {

    /**
     * Fetches the `KPSPurchaseRecord`
     *
     */
    func getPurchaseRecords(_ completion: ((Result<[KPSPurchaseTransaction], Error>) -> Void)?)  {
        subscriptionManager.fetchTransactions { result in
            completion?(result)
        }
    }
    
    func getCurrentCustomerType(_ completion: ((CustomerType)->Void)?) {
        syncPaymentStatus {
            completion?(self.customerType)
        }
    }
    
    private func updateCurrentCustomerType() {
        
        if subscriptionManager.subscriptionStatus == .None {
            customerType = trailEligible ? .New : .Free
        } else if subscriptionManager.subscriptionStatus == .Trial {
            guard let currentPlan = subscriptionManager.latestOrder?.latestTransaction.plan,
                  let expireTime = subscriptionManager.latestOrder?.latestTransaction.end else {
                customerType = .New
                return
            }
            customerType = .Trial_VIP(
                currentPlan: currentPlan,
                nextPlan: subscriptionManager.latestOrder?.nextPlan,
                expireTime: expireTime,
                platform: subscriptionManager.latestOrder?.provider
            )
        } else if subscriptionManager.subscriptionStatus == .Active {
            guard let currentPlan = subscriptionManager.latestOrder?.latestTransaction.plan,
                  let expireTime = subscriptionManager.latestOrder?.latestTransaction.end else {
                customerType = .New
                return
                
            }
            customerType = .VIP(
                currentPlan: currentPlan,
                nextPlan: subscriptionManager.latestOrder?.nextPlan,
                expireTime: expireTime,
                platform: subscriptionManager.latestOrder?.provider
            )
        }
    }

}

// MARK: Configuring Purchases
public extension KPSPurchases {

    /**
     * Configures an instance of the Purchases SDK with a custom userDefaults.
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter endpointURL: The backend server endpoint use to verify the purchase receipt and grant the content permission
     *
     *
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @discardableResult static func configure(withServerUrl endpointUrl: String, sessionKey: String) -> KPSPurchases {
        KPSPurchases.sessionKey = sessionKey
        
        let purchases = KPSPurchases(serverUrl: endpointUrl)
        setDefaultInstance(purchases)
        return purchases
    }
    
    /**
     * Config KPS Purchase module with KPS Content Server service
     * Purchases SDK will be set as a singleton.
     * You should access the singleton instance using ``Purchases.shared``
     *
     * - Parameter project: The project Id we use in KPS Content Server
     * - Parameter env: The server environment setting we want to use
     
     * - Returns: An instantiated `Purchases` object that has been set as a singleton.
     */
    @discardableResult static func configure(withProjectId projectId: String, env: KPSPurchaseEnv) -> KPSPurchases {
        let endpointUrl = env.baseUrl + projectId
        KPSPurchases.sessionKey = env.sessionKey
        
        let purchases = KPSPurchases(serverUrl: endpointUrl)
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
        //print(self.receiptManager.localReceipt)
        if isUserPurchasing {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSPurchasedTransactionComplete"), object: nil, userInfo: nil)
            uploadLocalReceipt()
        } else {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSPurchasedNewTransaction"), object: nil, userInfo: nil)
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
                        self.verifyCompleteBlock?(purchaseItem, false, .unknown)
                        break
                    }
                }
                
            case SKError.clientInvalid.rawValue:
                self.verifyCompleteBlock?(purchaseItem, false, .clientInvalid)
            case SKError.paymentCancelled.rawValue:
                self.verifyCompleteBlock?(purchaseItem, false, .paymentCancel)
            case SKError.paymentInvalid.rawValue:
                self.verifyCompleteBlock?(purchaseItem, false, .paymentInvalid)
            case SKError.paymentNotAllowed.rawValue:
                self.verifyCompleteBlock?(purchaseItem, false, .paymentNotAllowed)
            case SKError.storeProductNotAvailable.rawValue:
                self.verifyCompleteBlock?(purchaseItem, false, .productNotAvailable)
            default:
                self.verifyCompleteBlock?(purchaseItem, false, .network)
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
            //print(base64Receipt)
            var isPurchaseInTrial: Bool = false
            if let latestTransaction = self.receiptManager.localReceipt?.inAppPurchases.sorted(by: { $0.purchaseDate > $1.purchaseDate }).first {
                isPurchaseInTrial = latestTransaction.isInTrialPeriod ?? false
            }
            
            apiServiceProvider.request(.uploadReceipt(receipt: base64Receipt, version: 1, serverUrl: self.serverUrl)) { [weak self] result in
                
                switch result {
                case let .success(response):
                    do {
                        let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                        let responseStr = String(decoding: filteredResponse.data, as: UTF8.self)
                        
                        if responseStr.contains("kpsSignInToken") {
                            self?.verifyCompleteBlock?(self?.purchaseItem, false, .sessionInvalid)
                            self?.finishPurchaseAction()
                        } else {
                        
                            self?.syncPaymentStatus() {
                                if self?.subscriptionManager.subscriptionStatus == .None {
                                    self?.verifyCompleteBlock?(self?.purchaseItem, false, .receiptExpire)
                                } else {
                                    self?.verifyCompleteBlock?(self?.purchaseItem, isPurchaseInTrial, nil)
                                }
                                self?.finishPurchaseAction()
                            }
                        }
                    } catch _ {
                        
                        let errorResponse = String(decoding: response.data, as: UTF8.self)
                        print("[API Error: \(#function)] \(errorResponse)")
                        
                        switch response.statusCode{
                        case 403:
                            self?.verifyCompleteBlock?(self?.purchaseItem, false, .receiptExpire)
                        default:
                            self?.verifyCompleteBlock?(self?.purchaseItem, false, .ownServer)
                        }
                        self?.finishPurchaseAction()
                    }
                case .failure(let error):
                    print(error.errorDescription ?? "")
                    self?.verifyCompleteBlock?(self?.purchaseItem, false, .ownServer)
                    self?.finishPurchaseAction()
                }
            }
        }
        else {
            verifyCompleteBlock?(purchaseItem, false, .unknown)
            finishPurchaseAction()
        }
    }
    
    private func finishPurchaseAction() {
        verifyCompleteBlock = nil
        purchaseItem = nil
        isUserPurchasing = false
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

// MARK: - KPS Coupon
public extension KPSPurchases {
    
    func redeemCoupon(code: String, completion: @escaping(Result<KPSCouponResponse, MoyaError>) -> ()) {
        
        couponManager.redeemCoupon(code: code) {  [weak self] result in
            guard let weakSelf = self else { return }
            
            switch result {
            case .success(let couponInfo):
                
                weakSelf.syncPaymentStatus() {
                    completion(.success(couponInfo))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

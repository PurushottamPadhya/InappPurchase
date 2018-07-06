//
//  IAPHelper.swift
//  HighlightsNepal
//
//  Created by Amrit Tiwari on 4/26/18.
//  Copyright © 2018 tiwariammit@gmail.com. All rights reserved.
//

import Foundation

import UIKit
import StoreKit
import Alamofire

 enum IAPHandlerAlertType{
    case disabled
    case restored
    case purchased
    case failed
    case succeed
    
    func message() -> String{
        switch self {
        case .disabled: return "Purchases are disabled in your device!"
        case .restored: return "You've successfully restored your purchase!"
        case .purchased: return "You've successfully top up this purchase!"
        case .failed: return "Purchase can not succeed. Please try again"
        case .succeed: return "Succeed."
        }
    }
}


struct INAPP_PRODUCT_IDENTIFIERS
{
    static let TOP_UP_PRODUCT_IDENTIFIER_1  = "iCard_5"
    static let TOP_UP_PRODUCT_IDENTIFIER_2  = "iCard_10"
    static let TOP_UP_PRODUCT_IDENTIFIER_5  = "iCard_20"
}
enum PRODUCT_IDENTIFIERS : String
{
    //MARK: Product ID's
    
    case TOP_UP_PRODUCT_IDENTIFIER_1  = "iCard_5"
    case TOP_UP_PRODUCT_IDENTIFIER_2  = "iCard_10"
    case TOP_UP_PRODUCT_IDENTIFIER_5  = "iCard_20"
    //case TOP_UP_PRODUCT_IDENTIFIER_0    = "YOUR_PRODUCT_IDENTIFIER_RESTOREE"
}

enum USER_DEFAULTS_IDENTIFIERS : String
{
    case TIER_ONE_PRODUCT_IDENTIFIER = "TIER_ONE_IDENTIFIER"
    
    case TIER_TWO_PRODUCT_IDENTIFIER  = "TIER_TWO_IDENTIFIER"
    case TIER_THREE_PRODUCT_IDENTIFIER  = "TIER_THREE_IDENTIFIER"
}

enum ReceiptURL : String
{
    case sandbox = "https://sandbox.itunes.apple.com/verifyReceipt"
    case production = "https://buy.itunes.apple.com/verifyReceipt"
    case myServer = "your server"
    
}

struct Constants
{
    static let inappSecretKey  = "your secret key"

}




@objc class IAPHandler: NSObject{
    
    static let sessionIdSetNotification = Notification.Name("SubscriptionServiceSessionIdSetNotification")
    static let optionsLoadedNotification = Notification.Name("SubscriptionServiceOptionsLoadedNotification")
    static let restoreSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    static let purchaseSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    
    @objc public static let shared = IAPHandler()
    
    @objc public var purchaseProductIDList = Set<String>()
    fileprivate var productID = ""
    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var iapProducts = [SKProduct]()
    var p = SKProduct()
    
    var purchaseStatusBlock: ((IAPHandlerAlertType) -> Void)?
 
    var productListBlock:(([String]) ->Void)?
    
    var InappProductListSBlock:(([Subscription]?,IAPHandlerAlertType) ->Void)?
    
    
    
    var productList: [Subscription]? {
        didSet {
            
        }
    }
    var productOptions: [Subscription]?{
        didSet{
            
        }
    }

    
    // MARK: - MAKE PURCHASE OF A PRODUCT
   fileprivate func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }
    
    public func purchaseMyProduct(product: Subscription){
        SKPaymentQueue.default().add(self)
        
        p = product.product
       // if iapProducts.count == 0 { return }
        
        if self.canMakePurchases() {
            
            let product = product.product
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)
            
            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            productID = product.productIdentifier
        } else {
            
            purchaseStatusBlock?(.disabled)
        }
    }
    
    
    // MARK: - RESTORE PURCHASE
    fileprivate func restorePurchase(){
        
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    
    // MARK: - FETCH AVAILABLE IAP PRODUCTS
    @objc public func fetchAvailableProducts(){
        
        // Put here your IAP Products ID's
        productsRequest = SKProductsRequest(productIdentifiers: purchaseProductIDList)
        productsRequest.delegate = self
        productsRequest.start()
    }
    public func returnProductList(list: [String]) ->[String]{
        let pList = [String]()
        return pList
    }
}


//MARK:- ***** IAP Delegate *****
extension IAPHandler: SKProductsRequestDelegate, SKPaymentTransactionObserver{
    
    // MARK: - REQUEST IAP PRODUCTS
    

    func productsRequest (_ request:SKProductsRequest, didReceive response:SKProductsResponse) {
        
        if (response.products.count > 0) {
            productList = response.products.map { Subscription(product: $0) }
            InappProductListSBlock?(productList,.succeed)
        }
        else{
            print("empty product")
            InappProductListSBlock?(nil,.failed)
        }
    }
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            print("Subscription Options Failed Loading: \(error.localizedDescription)")
            InappProductListSBlock?(nil, .failed)
        }
    }
    
 
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        purchaseStatusBlock?(.restored)
    }
    
    // MARK:- IAP PAYMENT QUEUE
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    print("purchased")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    purchaseStatusBlock?(.purchased)
                    break
                    
                case .failed:
                    print("failed")
//                    AtAndroidToastMessage.message("Trascations failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    
                    print(trans.error!)
                    purchaseStatusBlock?(.failed)
                    break
                case .restored:
                    print("restored")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    purchaseStatusBlock?(.restored)
                    break
                    
                default:
                    //SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    //purchaseStatusBlock?(.failed)
                    break
                }
            }
        }
    }
    
    
    //MARK: - Handle receipt of transaction
    func uploadReceipt(product:Subscription , completion: @escaping (Result<Any>) -> Void) {
        if let receiptData = loadReceipt() {
            
            ReceiptValidation.shared.verifyReceipt(withReceipt: receiptData, product: product) { response in
                switch response {
                case .success(let result):
                    completion(Result.success(result))
                    //Post Notification
                    print(result)

                // 2
                case .failure(let error):
                    completion(Result.failure(error))
                    
                }
            }

        }
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("Add Payment")
        
        for transaction:AnyObject in transactions{
            let trans = transaction as! SKPaymentTransaction
            print(trans.error as Any)
            switch trans.transactionState{
            case .purchased:
                print("IAP unlocked")
                print(p.productIdentifier)
                
                let prodID = p.productIdentifier as String
                switch prodID{
                case "IAP id":
                    print("Keep on")
                default:
                    print("IAP not setup")
                }
                queue.finishTransaction(trans)
                break
            case .failed:
                print ("Buy error")
                queue.finishTransaction(trans)
                break
            default:
                print("default: Error")
                break
            }
        }
    }
 
}

//
//  IAPReceiptValidation.swift
//  WTV_GO
//
//  Created by NITV on 5/14/18.
//  Copyright © 2018 nitv. All rights reserved.
//

import Foundation
import Alamofire
import StoreKit



final class ReceiptValidation {
    
    
    
    static let shared = ReceiptValidation()
    private init() {
        // private
    }
    
    private lazy var baseURL: URL = {

        guard let url = URL(string: ReceiptURL.myServer) else {
            fatalError("Invalid URL")
        }
        return url
    }()
    
    func verifyReceipt(withReceipt: Data,product: Subscription, completion: @escaping (Result) -> Void) {

        let params: [String: Any] = [
            "token": withReceipt.base64EncodedString(),
            "mechanism": "AppStore",
            "amount" : product.formattedPrice,
            "product-id":product.product.productIdentifier
        ]

        Alamofire.request(baseURL, method: .post, parameters: params, encoding: URLEncoding.default, headers: nil)
            .validate(statusCode: 200..<500)
            .responseJSON { response in
                switch response.result {
                case .success:
                    completion(Result.success(response))
                case .failure(let error):
                    completion(Result.failure(error))
                }
        }
    }
    
    
    func upload(withReceipt: Data, product: Subscription, completion: @escaping (Result) -> Void) {
        let body = [
            "receipt-data": withReceipt.base64EncodedString(),
            "password": inappSecretKey
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        let url = URL(string: "\(ReceiptURL.production)")!
        //let url = baseURL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                completion(Result.failure(error))
            } else if let responseData = responseData {
                let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! Dictionary<String, Any>
                print(json)
                //completion(Result.success(responseData))
            }
        }
        
        task.resume()
    }
    
}

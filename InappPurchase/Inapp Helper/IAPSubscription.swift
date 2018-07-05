//
//  IAPSubscription.swift
//  WTV_GO
//
//  Created by NITV on 5/9/18.
//  Copyright © 2018 nitv. All rights reserved.
//

import Foundation
import StoreKit

private var formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.formatterBehavior = .behavior10_4
    
    return formatter
}()

struct Subscription {
    let product: SKProduct
    let formattedPrice: String
    
    init(product: SKProduct) {
        self.product = product
        
        if formatter.locale != self.product.priceLocale {
            formatter.locale = self.product.priceLocale
        }
        
        formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"
    }
}

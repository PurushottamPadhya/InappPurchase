//
//  Helper.swift
//  InappPurchase
//
//  Created by NITV on 7/6/18.
//  Copyright © 2018 Own. All rights reserved.
//

import Foundation
import UIKit


class Helper: NSObject {
    
    class func showDismisAlertWithMessage(title: String? ,message : String? , viewController : UIViewController?) {
        
                let alertController = UIAlertController(title: title, message: message, preferredStyle:.alert)
                alertController.addAction(UIAlertAction(title: "OK", style:.cancel, handler: nil))
        
                viewController?.present(alertController, animated: true, completion: nil)
        
    }
}

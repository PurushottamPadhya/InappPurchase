//
//  ViewController.swift
//  InappPurchase
//
//  Created by NITV on 7/5/18.
//  Copyright © 2018 Own. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var inappProductView : InappProductView!
    var hud : JGProgressHud!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func subscriptionInappClicked(_ sender: Any) {
        self.initiateInappPayment()
    }

    func initiateInappPayment(){
        
        let productsIDs  = Set([INAPP_PRODUCT_IDENTIFIERS.TOP_UP_PRODUCT_IDENTIFIER_1, INAPP_PRODUCT_IDENTIFIERS.TOP_UP_PRODUCT_IDENTIFIER_2, INAPP_PRODUCT_IDENTIFIERS.TOP_UP_PRODUCT_IDENTIFIER_5])
        
        showProgressHudWithMessage(message:"Loading products...")
        IAPHandler.shared.purchaseProductIDList = productsIDs
        IAPHandler.shared.fetchAvailableProducts()
        
        IAPHandler.shared.InappProductListSBlock = {[weak self] (product, type) in
            guard let strongSelf = self else{return}
            
            switch type {
            case IAPHandlerAlertType.succeed:
                if (product?.count)! > 0 {
                    
                    strongSelf.populateInappProductList(product: product!)
                }
                else{
                    Utils.showToastOnView(message: "Problem in loading product data.", view: (self?.view)!)
                }
                break
            case IAPHandlerAlertType.failed:
                Utils.showToastOnView(message: type.message(), view: (self?.view)!)
                break
            default:
                break
            }
            
            self?.hideProgressHud()
            
        }
        
        
    }
    func populateInappProductList(product: [Subscription]){
        print("clicked")
        if inappProductView != nil {
            inappProductView.removeFromSuperview()
            inappProductView = nil
        }
        let mainWindow = UIApplication.shared.keyWindow!
        inappProductView = InappProductView(frame: CGRect(x: mainWindow.frame.origin.x, y: mainWindow.frame.origin.y, width: mainWindow.frame.width, height: mainWindow.frame.height))
        inappProductView.controller = controller
        inappProductView.productList = product
        inappProductView.setupInappProductList()
        
        mainWindow.addSubview(inappProductView);

        //block operation handles
        inappProductView.InappProductDidSelectBlock = {[weak self] (product) in
            guard let strongSelf = self else{return}
            print("product count is: \(product)")
            self?.hideProgressHud()
            self?.inappProductView.removeFromSuperview()
            self?.inappProductView = nil
            mainWindow.removeFromSuperview()
            strongSelf.purchaseProductWithProduct(product: product)
            
        }
    }
    
    func purchaseProductWithProduct(product: Subscription){
        hideProgressHud()
        showProgressHudWithMessage(message:"purchasing...")
        IAPHandler.shared.purchaseMyProduct(product: product)
        IAPHandler.shared.purchaseStatusBlock = {[weak self] (type) in
            guard let selff = self else{return}
            if type == .purchased{
                self?.handlePurchasedState(product: product)
                
            }
            else {
                self?.hideProgressHud()
                selff.hideProgressHud()
                print(type.message())
                Utils.showToastOnView(message: type.message(), view: (self?.view)!)
            }
        }
    }
    
    func handlePurchasedState(product: Subscription) {
        
        hideProgressHud()
        showProgressHudWithMessage(message:"Verifying purchase...")
        IAPHandler.shared.uploadReceipt(product: product) { response in
            
            switch response{
            case .success(let result):
                print("Success in app payment\(result)")
                if let data = result.result.value as? NSDictionary {
                    print(data)
                    if let status = data["status"] as? String, status == "Successful"{
                        if let message = data["message"] as? String{
                            self.showPaymentSucessAlertMessage(title: "Congratulations", msg: message)
                        }
                        if let balance = data["balance"] {
                            UserDefaults.standard.setValue(balance, forKey: "userBalance")
                            self.balanceLabel.text =  String("\(Utils.getCurrencySymbol()) \(balance)")
                        }
                    }
                    else{
                        if let message = data["message"] as? String{
                            self.showPaymentSucessAlertMessage(title: "Error", msg: message)
                        }
                        else{
                            self.showPaymentSucessAlertMessage(title: "Error", msg:" Error processing purchase")
                        }
                        
                    }
                    
                }
                self.hideProgressHud()
                break
            case .failure(let error):
                self.hideProgressHud()
                print("Failed in app payment\(error.localizedDescription)")
                self.showPaymentSucessAlertMessage(title: "Error", msg:error.localizedDescription)
                break
                
            }
            
        }
    }
    
    func showProgressHudWithMessage(message: String){
        
        if self.hud != nil {
            self.hud.dismiss()
        }
        
        self.hud = ProgressHud.showNormalHud(view:self.view, message:message)
        
    }
    func hideProgressHud(){
        self.hud.dismiss()
        
    }
    func showPaymentSucessAlertMessage(title: String, msg: String){
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            print("clicked ok")
        })
        alertController.addAction(alertAction)
        self.present(alertController, animated: true)
    }


}


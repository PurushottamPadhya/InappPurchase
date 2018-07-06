//
//  InappProductView.swift
//  WTV_GO
//
//  Created by NITV on 5/10/18.
//  Copyright © 2018 nitv. All rights reserved.
//

import UIKit
import StoreKit
import JGProgressHUD

class InappProductView: UIView, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {


    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var productListTableView: UITableView!
    var productList : [Subscription]?
    var controller : UIViewController?
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var view: UIView!
    var hud : JGProgressHUD!
    var InappProductDidSelectBlock:((Subscription) ->Void)?
    
   
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        loadNib()
        
        registerNib()

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadNib()
        
    }
    
    
    func loadNib() {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "InappProductView", bundle: bundle)
        
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.frame = bounds
        
        print("product list Frame \(view)")
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        
    }

    func registerNib(){
        
        let nibTable = UINib(nibName: "InappTableViewCell", bundle: nil)
        productListTableView.register(nibTable, forCellReuseIdentifier: "inappProductIdentifier")
    }
    func setupInappProductList(){
        

        self.productListTableView.separatorColor = UIColor.clear
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        //self.productListTableView.backgroundColor = UIColor.white.withAlphaComponent(1)
        //self.containerView.backgroundColor = UIColor.white.withAlphaComponent(1)
        
        sortingProductListWithPrice()
        productListTableView.delegate = self
        productListTableView.dataSource = self
        productListTableView.reloadData()
        if let product = productList{
             tableViewHeightConstraint.constant = CGFloat (60 * product.count )
        }
        self.addTapGesture()
        
    }
    func sortingProductListWithPrice(){
        let sortedArray = productList?.sorted(by: {$0.formattedPrice < $1.formattedPrice})
        productList = sortedArray
   
    }
    
    @IBAction func closeButtonClicked(_ sender: Any) {
        self.removeFromSuperview()
    }
    
    
    
    //MARK: - table view delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return productList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "inappProductIdentifier", for: indexPath) as! InappTableViewCell
        guard let currentCellData = productList?[indexPath.row] else { return cell }
        cell.configureCell(product: currentCellData)
        cell.productPriceButton.addTarget(self, action: #selector(processPayment(sender: )), for: .touchUpInside)
        cell.productPriceButton.tag = indexPath.row
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let selectedProduct = productList?[indexPath.row] else { return }
        //initiateInappPaymentwithProduct(productID: selectedProduct.product_price)
        self.InappProductDidSelectBlock!(selectedProduct)
        print(selectedProduct)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 60
    }
    @objc func processPayment(sender: UIButton){
        
        guard let selectedProduct = productList?[sender.tag] else { return }
        //initiateInappPaymentwithProduct(productID: selectedProduct.product_price)
        self.InappProductDidSelectBlock!(selectedProduct)
        print(selectedProduct)
    }
    

    //MARK: - tap gesture recognizer
    func addTapGesture(){
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewTapped(sender:)))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if ((touch.view?.isDescendant(of: stackView))!){
            return false
        }
        return true
    }
    @objc func viewTapped(sender : UITapGestureRecognizer){
        
        self.isHidden = true
        self.removeFromSuperview()
        
    }


}

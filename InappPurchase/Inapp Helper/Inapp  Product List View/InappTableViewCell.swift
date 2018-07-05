//
//  InappTableViewCell.swift
//  WTV_GO
//
//  Created by NITV on 5/10/18.
//  Copyright © 2018 nitv. All rights reserved.
//

import UIKit

class InappTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var productPriceButton: UIButton!
    @IBOutlet weak var topupPrice: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configureCell(product: Subscription){
        productNameLabel.text = product.product.localizedTitle
        productPriceButton.setTitle(product.formattedPrice, for: UIControlState.normal)
        var price  = product.formattedPrice
        while price.hasPrefix("$") {
            price.remove(at: price.startIndex)
        }
        topupPrice.text = "$\(round(Double(price)!))"
    }
    
}

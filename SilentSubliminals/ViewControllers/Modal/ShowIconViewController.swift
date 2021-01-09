//
//  ShowIconViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 09.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit

class ShowIconViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var itemTitle: String?
    var icon: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = itemTitle
        imageView.image = icon
    }
    

}

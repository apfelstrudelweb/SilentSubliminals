//
//  MediathekCollectionViewCell.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 02.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import PureLayout

class MediathekCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var symbolImageView: UIImageView!
    var title: String? {
        didSet {
            addLabel()
        }
    }
    var hasOwnIcon: Bool = false
    
    let label = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
        
    func addLabel() {
        
        if hasOwnIcon { return }
        
        //label.removeFromSuperview()
        for view in self.subviews {
            if view.isKind(of: UILabel.self) {
                return
            }
        }
        
        symbolImageView.addSubview(label)
//        label.autoPinEdgesToSuperviewEdges()
        label.autoPinEdge(.left, to: .left, of: symbolImageView, withOffset: 4)
        label.autoPinEdge(.right, to: .right, of: symbolImageView, withOffset: -4)
        label.autoPinEdge(.bottom, to: .bottom, of: symbolImageView, withOffset: -4)
 
        label.text = title
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 2
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        
//        label.layer.shadowColor = UIColor.black.cgColor
//        label.layer.shadowRadius = 1.0
//        label.layer.shadowOpacity = 0.8
//        label.layer.shadowOffset = CGSize(width: 2, height: 2)
//        label.layer.masksToBounds = false
    }
}

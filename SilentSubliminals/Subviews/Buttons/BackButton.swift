//
//  BackButton.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.12.20.
//  Copyright © 2020 Ullrich Vormbrock. All rights reserved.
//

import UIKit

protocol BackButtonDelegate : AnyObject {
    
    func close()
}

class BackButton: UIButton {
    
    weak var delegate : BackButtonDelegate?

    override func layoutSubviews() {
        super.layoutSubviews()

        self.setImage(UIImage(named: "backButton.png"), for: [.normal])
        self.tintColor = .white//PlayerControlColor.lightColor
        self.addTarget(self, action: #selector(self.close(_:)), for: .touchUpInside)
    }
    
    @objc func close(_ sender: UIButton) {
        //superview.navigationController?.dismiss(animated: true, completion: nil)
        self.delegate?.close()
    }
}

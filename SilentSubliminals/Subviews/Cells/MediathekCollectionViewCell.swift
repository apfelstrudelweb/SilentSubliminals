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
        //shake()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //print("layout subviews")
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
    
    func shake(completionHandler: @escaping() -> Void) {
          
        CATransaction.begin()
        
        let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
        shakeAnimation.duration = 0.1
        shakeAnimation.repeatCount = 10
        shakeAnimation.autoreverses = true
        let startAngle: Float = (-2) * 3.14159/180
        let stopAngle = -startAngle
        shakeAnimation.fromValue = NSNumber(value: startAngle as Float)
        shakeAnimation.toValue = NSNumber(value: 3 * stopAngle as Float)
        shakeAnimation.timeOffset = 290 * drand48()
        
        CATransaction.setCompletionBlock{
                completionHandler()
        }

        let layer: CALayer = symbolImageView.layer
        layer.add(shakeAnimation, forKey: "position")
        
        CATransaction.commit()
    }

    func stopShaking() {
        let layer: CALayer = symbolImageView.layer
        layer.removeAnimation(forKey: "shaking")
    }
    
    
    func addBorderToImage(image : UIImage) -> UIImage {
        let bgImage = image.cgImage
        let initialWidth = (bgImage?.width)!
        let initialHeight = (bgImage?.height)!
        let borderWidth = Int(Double(initialWidth) * 0.10);
        let width = initialWidth + borderWidth * 2
        let height = initialHeight + borderWidth * 2
        let data = malloc(width * height * 4)

        let context = CGContext(data: data,
                            width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bytesPerRow: width * 4,
                            space: (bgImage?.colorSpace)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue);

        context?.draw(bgImage!, in: CGRect(x: CGFloat(borderWidth), y: CGFloat(borderWidth), width: CGFloat(initialWidth), height: CGFloat(initialHeight)))
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(CGFloat(borderWidth))
        context?.move(to: CGPoint(x: 0, y: 0))
        context?.addLine(to: CGPoint(x: 0, y: height))
        context?.addLine(to: CGPoint(x: width, y: height))
        context?.addLine(to: CGPoint(x: width, y: 0))
        context?.addLine(to: CGPoint(x: 0, y: 0))
        context?.strokePath()

        let cgImage = context?.makeImage()
        let uiImage = UIImage(cgImage: cgImage!)

        free(data)

        return uiImage;
    }
}

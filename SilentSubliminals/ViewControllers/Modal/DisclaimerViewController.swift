//
//  DisclaimerViewController.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 01.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit


class DisclaimerViewController: UIViewController, DisclaimerDelegate  {
    

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: ScrollingPageControl!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var containerView: UIView!
    
    let numberOfPages: Int = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.cornerRadius = cornerRadius
        containerView.layer.cornerRadius = cornerRadius

        scrollView.delegate = self
        scrollView.clipsToBounds = true
        //pageControl.delegate = self
        
        pageControl.numberOfPages = numberOfPages
        pageControl.dotColor = UIColor(red: 193/255, green: 193/255, blue: 193/255, alpha: 1.0)
        pageControl.selectedColor = .white
        pageControl.dotSize = 12
        
        pageControl.clipsToBounds = true
        
        scrollView.clipsToBounds = true
        scrollView.backgroundColor = darkGrayColor
        scrollView.layer.cornerRadius = cornerRadius

        
        for index in 0..<numberOfPages {
            let item = DisclaimerDetailView()
            item.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(item)
            item.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
            item.agreeButton.isHidden = true
            item.agreeLabel.isHidden = true
            item.closeButton.isHidden = true
            
            if index == numberOfPages - 1 {
                item.agreeButton.isHidden = false
                item.agreeLabel.isHidden = false
                item.closeButton.isHidden = false
                item.delegate = self
            }
        }
        
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension DisclaimerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = round(scrollView.contentOffset.x / scrollView.frame.width)
        pageControl.selectedPage = Int(page)
    }
}

//extension DisclaimerViewController: ScrollingPageControlDelegate {
//    func viewForDot(at index: Int) -> UIView? {
//        guard index == 0 else { return nil }
//        let view = UIView()
//        view.layer.cornerRadius = 0.5 * view.frame.size.width
//        view.backgroundColor = .white
//        view.isOpaque = false
//        return view
//    }
//}


class DisclaimerView: UIView {
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "DisclaimerView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
}

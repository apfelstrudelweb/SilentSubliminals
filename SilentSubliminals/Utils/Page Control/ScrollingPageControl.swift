//
//  ScrollingPageControl.swift
//  ScrollingPageControl
//
//  Created by Emilio Peláez on 3/10/18.
//

import UIKit
import PureLayout

public protocol ScrollingPageControlDelegate: class {
	//	If delegate is nil or the implementation returns nil for a given dot, the default
	//	circle will be used. Returned views should react to having their tint color changed
	func viewForDot(at index: Int) -> UIView?
}

open class ScrollingPageControl: UIView {
    
    var stackView: UIStackView?
    
	open weak var delegate: ScrollingPageControlDelegate? {
		didSet {
			createViews()
		}
	}
	//	The number of dots
	open var numberOfPages: Int = 0 {
		didSet {
			guard numberOfPages != oldValue else { return }
			numberOfPages = max(0, numberOfPages)
			invalidateIntrinsicContentSize()
			createViews()
		}
	}
    
    //    The size of the dots
    open var dotSize: CGFloat = 10 {
        didSet {
            createViews()
        }
    }
    
    
	private func createViews() {
        
        stackView = UIStackView()
        stackView?.axis = .horizontal
        stackView?.alignment = .center
        stackView?.distribution = .equalCentering
        addSubview(stackView ?? UIView())
        
        stackView?.autoPinEdge(.top, to: .top, of: self)
        stackView?.autoPinEdge(.bottom, to: .bottom, of: self)
        stackView?.autoCenterInSuperview()

		dotViews = (0..<numberOfPages).map { index in
			delegate?.viewForDot(at: index) ?? CircularView(frame: CGRect(origin: .zero, size: CGSize(width: dotSize, height: dotSize)))
		}
	}
    
	//	The index of the currently selected page
	open var selectedPage: Int = 0 {
		didSet {
			guard selectedPage != oldValue else { return }
			selectedPage = max(0, min (selectedPage, numberOfPages - 1))
			updateColors()
		}
	}

	private var dotViews: [UIView] = [] {
		didSet {
            
            stackView?.autoSetDimension(.width, toSize: CGFloat(2 * dotViews.count) * dotSize)

			oldValue.forEach { $0.removeFromSuperview() }
            dotViews.forEach {
                stackView?.addArrangedSubview($0)

                $0.autoSetDimensions(to: CGSize(width: dotSize, height: dotSize))
                
            }
			updateColors()
		}
	}
	
	//	The color of all the unselected dots
	open var dotColor = UIColor.lightGray { didSet { updateColors() } }
	//	The color of the currently selected dot
	open var selectedColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) { didSet { updateColors() } }
    
    private func updateColors() {
        dotViews.enumerated().forEach { page, dot in
            dot.tintColor = page == selectedPage ? selectedColor : dotColor
        }
    }


	public init() {
		super.init(frame: .zero)
		isOpaque = false
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		isOpaque = false
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
	}

}

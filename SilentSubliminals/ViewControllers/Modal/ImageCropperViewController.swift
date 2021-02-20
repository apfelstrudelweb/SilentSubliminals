//
//  ImageCropperViewController.swift
//  SilentSubliminals
//
//  Created by Ullrich Vormbrock on 20.02.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//

import UIKit
import UnsplashPhotoPicker

public protocol ImageCropperDelegate: class {
    func didSelectCroppedImage(image: UIImage?)
}

class ImageCropperViewController: UIViewController, UIScrollViewDelegate {
    
    weak var delegate : ImageCropperDelegate?
    
    var restoredImage : UIImage?
    var isBackgroundImageForPlayer: Bool = false
    
    @IBOutlet weak var aspectRatio: NSLayoutConstraint!
    
    
    private var imageDataTask: URLSessionDataTask?
    private static var cache: URLCache = {
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 100 * 1024 * 1024
        let diskPath = "unsplash"
        
        if #available(iOS 13.0, *) {
            return URLCache(
                memoryCapacity: memoryCapacity,
                diskCapacity: diskCapacity,
                directory: URL(fileURLWithPath: diskPath, isDirectory: true)
            )
        }
        else {
            #if !targetEnvironment(macCatalyst)
            return URLCache(
                memoryCapacity: memoryCapacity,
                diskCapacity: diskCapacity,
                diskPath: diskPath
            )
            #else
            fatalError()
            #endif
        }
    }()

    @IBOutlet var scrollView: UIScrollView!{
        didSet{
            scrollView.delegate = self
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 10.0
        }
    }
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var cropAreaView: CropAreaView!
    
    var cropArea:CGRect{
        get{
            let factor = imageView.image!.size.width/view.frame.width
            let scale = 1/scrollView.zoomScale
            let imageFrame = imageView.imageFrame()
            let x = (scrollView.contentOffset.x + cropAreaView.frame.origin.x - imageFrame.origin.x) * scale * factor
            let y = (scrollView.contentOffset.y + cropAreaView.frame.origin.y - imageFrame.origin.y) * scale * factor
            let width = cropAreaView.frame.size.width * scale * factor
            let height = cropAreaView.frame.size.height * scale * factor
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = restoredImage
        
        cropAreaView.layer.borderColor = UIColor.white.cgColor
        cropAreaView.layer.borderWidth = 1
        
        //aspectRatio.constant = isBackgroundImageForPlayer ? 0.56 : 1.0
        if isBackgroundImageForPlayer {
            let deviceWidth = UIScreen.main.bounds.width * UIScreen.main.scale
            let deviceHeight = UIScreen.main.bounds.height * UIScreen.main.scale
            cropAreaView.aspectRatio(deviceWidth / deviceHeight).isActive = true
            scrollView.aspectRatio(deviceWidth / deviceHeight).isActive = true
        } else {
            cropAreaView.aspectRatio(1.0/1.0).isActive = true
        }
        
        
        showUnsplash()
    }
    
    func showUnsplash() {
        showSplashDialog(title: "Action required",
                        subtitle: "Please enter a keyword for your unsplash photo",
                        actionTitle: "OK",
                        cancelTitle: "Cancel",
                        inputText: "",
                        inputPlaceholder: "",
                        inputKeyboardType: .default,
                        completionHandler: { (text) in
                            let configuration = UnsplashPhotoPickerConfiguration(
                                accessKey: "7syVpKRGq7fmM3EYTf2AsOQHfog2IlEY75uUzLzy2E4",
                                secretKey: "P86po4fvPaDeXaTZSd3W09QThiGmAyJ8PbBzC1f3rWA",
                                query: text,
                                allowsMultipleSelection: false
                            )
                            let unsplashPhotoPicker = UnsplashPhotoPicker(configuration: configuration)
                            unsplashPhotoPicker.photoPickerDelegate = self

                            self.present(unsplashPhotoPicker, animated: true, completion: nil)
                        },
                        actionHandler: { (input:String?) in
                            //self.affirmationTitleLabel.text = input?.capitalized
                        })
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    

    
    @IBAction func crop(_ sender: UIButton) {
        let croppedCGImage = imageView.image?.cgImage?.cropping(to: cropArea)
        let croppedImage = UIImage(cgImage: croppedCGImage!)
        imageView.image = croppedImage
        scrollView.zoomScale = 1
        
        delegate?.didSelectCroppedImage(image: croppedImage)
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UnsplashPhotoPickerDelegate
extension ImageCropperViewController: UnsplashPhotoPickerDelegate {
    
    public func unsplashPhotoPicker(_ photoPicker: UnsplashPhotoPicker, didSelectPhotos photos: [UnsplashPhoto]) {
        print("Unsplash photo picker did select \(photos.count) photo(s)")
        
        guard let photo = photos.first else { return }
        downloadPhoto(photo)
    }
    
    func downloadPhoto(_ photo: UnsplashPhoto) {
        guard let url = photo.urls[.regular] else { return }

        if let cachedResponse = ImageCropperViewController.cache.cachedResponse(for: URLRequest(url: url)),
            let image = UIImage(data: cachedResponse.data) {
            imageView.image = image
            
            return
        }

        imageDataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            guard let strongSelf = self else { return }

            strongSelf.imageDataTask = nil

            guard let data = data, let image = UIImage(data: data), error == nil else { return }

            DispatchQueue.main.async {
                strongSelf.imageView.image = image
                strongSelf.delegate?.didSelectCroppedImage(image: image)

            }
        }

        imageDataTask?.resume()
    }

    public func unsplashPhotoPickerDidCancel(_ photoPicker: UnsplashPhotoPicker) {
        print("Unsplash photo picker did cancel")
    }
}

extension UIImageView{
    func imageFrame()->CGRect{
        let imageViewSize = self.frame.size
        guard let imageSize = self.image?.size else{return CGRect.zero}
        let imageRatio = imageSize.width / imageSize.height
        let imageViewRatio = imageViewSize.width / imageViewSize.height
        
        if imageRatio < imageViewRatio {
            let scaleFactor = imageViewSize.height / imageSize.height
            let width = imageSize.width * scaleFactor
            let topLeftX = (imageViewSize.width - width) * 0.5
            return CGRect(x: topLeftX, y: 0, width: width, height: imageViewSize.height)
        }else{
            let scalFactor = imageViewSize.width / imageSize.width
            let height = imageSize.height * scalFactor
            let topLeftY = (imageViewSize.height - height) * 0.5
            return CGRect(x: 0, y: topLeftY, width: imageViewSize.width, height: height)
        }
    }
}

class CropAreaView: UIView {
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
    
}


extension UIView {

    func aspectRatio(_ ratio: CGFloat) -> NSLayoutConstraint {

        return NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: self, attribute: .height, multiplier: ratio, constant: 0)
    }
}

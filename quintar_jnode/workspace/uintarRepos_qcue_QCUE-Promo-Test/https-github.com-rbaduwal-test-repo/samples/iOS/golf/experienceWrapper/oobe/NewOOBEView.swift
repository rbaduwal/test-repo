import UIKit
import Q_ui

class NewOOBEView: UIView {
   
   @IBOutlet weak var containerView: UIView!
   @IBOutlet weak var skipButton: UIButton!
   @IBOutlet weak var skipButtonTopConstraint: NSLayoutConstraint!
   @IBOutlet weak var pageControlBottomConstraint: NSLayoutConstraint!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var pageControl: UIPageControl!
   
   var testView = UIView()
   var blurBackgroundCount = 0
   var minYforBlurView:CGFloat = 0
   var oobeSlideDuration: Double = 1.0
   var oobeTimerDuration: Double = 3.0
   var oobeImageArray = [["ImageOne"],["ImageTwo","ImageThree"],["ImageFour","ImageFive","ImageFour"],["ImageSix","ImageSeven"],["ImageEight","ImageNine","ImageTen"], ["ImageEleven","ImageTwelve"],["ImageThirteen"]]
   
   override init(frame: CGRect) {
      super.init(frame: frame)
      loadView()
      setUpCollectionView()
      self.skipButton.isHidden = true
   }
   required init?(coder: NSCoder) {
      super.init(coder: coder)
      loadView()
      setUpCollectionView()
   }
   func setDurations(slideDuration:Double,timerDuration:Double) {
      self.oobeSlideDuration = slideDuration
      self.oobeTimerDuration = timerDuration
   }
   func setUpCollectionView() {
      self.pageControl.numberOfPages = oobeImageArray.count
      self.pageControl.currentPage = 0
      self.collectionView.delegate = self
      self.collectionView.dataSource = self
      self.collectionView.register(UINib(nibName: "OOBECollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "OOBECollectionViewCell")
      self.collectionView.contentInsetAdjustmentBehavior = .never
      self.collectionView.backgroundColor = .clear
      skipButton.setTitle("Skip", for: .normal)
   }
   func loadView() {
      guard let view = loadViewFromNib("NewOOBEView") else { return }
      view.frame = self.bounds
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.backgroundColor = .clear
      addSubview(view)
   }
   func setPageConstrolBottomConstraint(value:CGFloat) {
      self.minYforBlurView = value
      self.pageControlBottomConstraint.constant = value - 10
      self.skipButtonTopConstraint.constant = -value + 16
      self.layoutIfNeeded()
   }
   @IBAction func skipButtonAction(_ sender: UIButton) {
      let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
      if let OOBECell = self.collectionView.cellForItem(at: indexPath) as? OOBECollectionViewCell {
         OOBECell.resetTimerAndCount()
      }
   }
}

extension NewOOBEView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      return oobeImageArray.count
   }
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OOBECollectionViewCell", for: indexPath) as! OOBECollectionViewCell
      cell.setOOBESlides(slideNames: oobeImageArray[indexPath.row])
      return cell
   }
   func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      return collectionView.frame.size
   }
   func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
      let OOBECell = cell as! OOBECollectionViewCell
      // To set a blured view
      if indexPath.row == 0 && blurBackgroundCount == 0 {
         let size = OOBECell.getImageViewSize()
         let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
         let blurEffectView = CustomIntensityVisualEffectView(effect: blurEffect, intensity: 0.5)
         let convertedSize = self.containerView.convert(size, from: OOBECell.OOBESlideImageView)
         blurEffectView.frame = CGRect(x: 30, y: convertedSize.minY, width: size.width, height: size.height)
         blurEffectView.layer.cornerRadius = 24
         blurEffectView.clipsToBounds = true
         self.containerView.insertSubview(blurEffectView, belowSubview: self.collectionView)
         //To add blacked out background around blured slides
         let pathBigRect = UIBezierPath(rect: CGRect(x: 0, y: 0, width: containerView.bounds.width, height: containerView.bounds.height))
         let pathSmallRect = UIBezierPath(roundedRect:  CGRect(x: 30, y: convertedSize.minY, width: size.width, height: size.height), cornerRadius: 24)
         pathBigRect.append(pathSmallRect)
         pathBigRect.usesEvenOddFillRule = true
         let fillLayer = CAShapeLayer()
         fillLayer.path = pathBigRect.cgPath
         fillLayer.fillRule = CAShapeLayerFillRule.evenOdd
         fillLayer.fillColor = UIColor.black.cgColor
         fillLayer.opacity = 0.4
         containerView.layer.addSublayer(fillLayer)
         blurBackgroundCount = 1
      }
      if indexPath.row == oobeImageArray.count - 1 {
         OOBECell.gotItButton.isHidden = false
      }
      OOBECell.startAnimation(timerDuration: oobeTimerDuration, slideDuration: oobeSlideDuration)
   }
   func scrollViewDidScroll(_ scrollView: UIScrollView) {
      if scrollView == self.collectionView {
         let scrollPos = scrollView.contentOffset.x / self.frame.width
         pageControl.currentPage = Int(scrollPos)
         if pageControl.currentPage == 0 {
            skipButton.setTitle("Skip", for: .normal)
         } else {
            skipButton.setTitle("Skip Tutorial", for: .normal)
         }
      }
   }
}

// OOBEScaledHeightImageView class is exlusive for oobe to make imageView used inside collection view cell resize and should not be used in any other context
class OOBEScaledHeightImageView: UIImageView {
   override var intrinsicContentSize: CGSize {
      if let myImage = self.image {
         let myImageWidth = myImage.size.width
         let myImageHeight = myImage.size.height
         let width = frame.width
         let ratio = myImageWidth/myImageHeight
         let scaledHeight = width / ratio
         experienceWrapper.golf?.screenView?.oobeView.setPageConstrolBottomConstraint(value: (scaledHeight - min(UIScreen.main.bounds.height, UIScreen.main.bounds.width))/2)
         return CGSize(width: width, height: scaledHeight)
      }
      return CGSize(width: -1.0, height: -1.0)
   }
   override func layoutSubviews() {
      super.layoutSubviews()
      invalidateIntrinsicContentSize()
   }
}

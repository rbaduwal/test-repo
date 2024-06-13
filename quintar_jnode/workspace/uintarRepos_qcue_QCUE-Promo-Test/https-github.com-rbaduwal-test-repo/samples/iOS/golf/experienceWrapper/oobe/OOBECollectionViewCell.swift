import UIKit
import Q_ui

class OOBECollectionViewCell: UICollectionViewCell {
   
   @IBOutlet weak var gotItButton: UIButton!
   @IBOutlet weak var OOBESlideImageView: OOBEScaledHeightImageView!
   
   var oobeTimer : Timer?
   var imageCount: Int = 0
   var oobeImageArray:[String] = []
   var slideDuration: Double = 1.0
   
   override func awakeFromNib() {
      super.awakeFromNib()
      self.layoutIfNeeded()
      self.gotItButton.isHidden = true
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      self.oobeTimer?.invalidate()
      self.oobeTimer = nil
      self.imageCount = 0
      self.oobeImageArray = []
      self.OOBESlideImageView.image = nil
      self.gotItButton.isHidden = true
      self.slideDuration = 1.0
   }
   func setOOBESlides(slideNames:[String]) {
      self.oobeImageArray = slideNames
      self.OOBESlideImageView.image = UIImage(named: oobeImageArray[imageCount])
   }
   func resetTimerAndCount() {
      imageCount = 0
      oobeTimer?.invalidate()
      oobeTimer = nil
      experienceWrapper.golf?.screenView?.oobeView.isHidden = true
      experienceWrapper.golf?.screenView?.oobeView.collectionView.setContentOffset(.zero, animated: false)
      experienceWrapper.golf?.enableOobeView = false
   }
   func startAnimation(timerDuration:Double,slideDuration:Double) {
      self.slideDuration = slideDuration
      if oobeImageArray.count == 1 {
         self.OOBESlideImageView.image = UIImage(named: oobeImageArray[imageCount])
      } else {
         if oobeTimer == nil {
            oobeTimer = Timer.scheduledTimer(timeInterval: timerDuration, target: self, selector: #selector(oobeTimerAction), userInfo: nil, repeats: true)
         }
      }
   }
   func getImageViewSize() -> CGRect {
       self.layoutIfNeeded()
       return self.OOBESlideImageView.bounds
   }
   @objc func oobeTimerAction() {
      if imageCount == oobeImageArray.count - 1 {
         imageCount = 0
      } else {
         imageCount = imageCount + 1
      }
      UIView.transition(with: self.OOBESlideImageView, duration: slideDuration, options: .transitionCrossDissolve, animations: {
         self.OOBESlideImageView.image = UIImage.init(named: self.oobeImageArray[self.imageCount])
      }, completion: nil)
   }
    @IBAction func gotItButtonAction(_ sender: UIButton) {
        self.resetTimerAndCount()
    }
}

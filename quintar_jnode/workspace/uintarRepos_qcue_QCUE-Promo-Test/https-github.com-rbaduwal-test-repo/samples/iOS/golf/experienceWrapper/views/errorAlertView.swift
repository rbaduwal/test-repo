import UIKit
import Q_ui
import Q

class ErrorAlertView: UIView {
   
   @IBOutlet weak var titleTextLabel: UILabel!
   @IBOutlet weak var infoTextLabel: UILabel!
   @IBOutlet weak var closeButtonTapView: UIView!
   @IBOutlet weak var connectButton: UIButton!
   @IBOutlet weak var cancelButton: UIButton!
   @IBOutlet weak var connectTopView: UIView!
   @IBOutlet weak var connectSideView: UIView!
   @IBOutlet weak var closeImage: UIImageView!
   @IBOutlet weak var errorLine: UIView!
   
   var isErrorAlertViewDismissed:Bool = true
   var hole: String = ""
   override func awakeFromNib() {
      super.awakeFromNib()
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onCloseButtonAction(tapGestureRecognizer:)))
      closeButtonTapView.isUserInteractionEnabled = true
      closeButtonTapView.addGestureRecognizer(tapGestureRecognizer)
   }
   public func setErrorTitleAndText(titleText:String,infoText:String) {
      self.titleTextLabel.text = titleText
      self.infoTextLabel.text = infoText
      self.isErrorAlertViewDismissed = false
   }
   public func showViewForConnectMsg(hole: String) {
      self.hole = hole
      self.cancelButton.isHidden = false
      self.connectButton.isHidden = false
      self.connectSideView.isHidden = false
      self.connectTopView.isHidden = false
      self.errorLine.isHidden = true
      self.closeButtonTapView.isUserInteractionEnabled = false
      self.closeImage.isHidden = true
      self.closeButtonTapView.isHidden = false
   }
   
   @objc func onCloseButtonAction(tapGestureRecognizer: UITapGestureRecognizer) {
      self.isHidden = true
      self.isErrorAlertViewDismissed = true
      experienceWrapper.golf?.screenView?.connectingView.isHidden = true
      experienceWrapper.golf?.screenView?.connectView.isHidden = false
   }
   @IBAction func connectTapped(_ sender: UIButton) {
      if experienceWrapper.golf?.fop != hole {
         experienceWrapper.golf?.screenView?.liveTableView.listAutoScrolledOnce = false
         experienceWrapper.golf?.onFopChanged(hole)
         experienceWrapper.golf?.screenView?.connectingView.isHidden = true
         experienceWrapper.golf?.screenView?.isHoleChangedFromDropDown = true
         experienceWrapper.golf?.screenView?.featuredHolePicker.selectRow((experienceWrapper.golf?.screenView?.featuredHoles?.firstIndex{$0.fop == hole} ?? 0) + 1, inComponent: 0, animated: false)
         if let selectedHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == hole} ) {
            experienceWrapper.golf?.screenView?.selectedHoleNum = selectedHole.num
         }
         self.isHidden = true
         for gesture in (experienceWrapper.golf?.screenView?.gestureRecognizers)!{
           gesture.isEnabled = true
         }
         self.isErrorAlertViewDismissed = true
         self.cancelButton.isHidden = true
         self.connectButton.isHidden = true
         self.connectSideView.isHidden = true
         self.connectTopView.isHidden = true
         self.closeImage.isHidden = false
         self.closeButtonTapView.isHidden = false
         self.errorLine.isHidden = false
         self.closeButtonTapView.isUserInteractionEnabled = true
         experienceWrapper.golf?.screenView?.hidePlayerDrawerOnHoleChangeFromDropDown()
         experienceWrapper.golf?.screenView?.connectView.isHidden = false
         experienceWrapper.golf?.screenView?.playerContainerView.resetPlayerArrayAfterHoleChange()
         experienceWrapper.golf?.screenView?.replayTableView.resetPlayerArraysAfterHoleChange()
         experienceWrapper.golf?.screenView?.reloadPlayerData()
         experienceWrapper.golf?.screenView?.playerContainerView.scrollToLive()
         experienceWrapper.golf?.screenView?.blurEffectView.isHidden = true
      }
      Q.log.instance.push(.ANALYTICS, msg: "onHoleSelectionFromDropdown", userInfo: ["selectedHoleNumber":hole])
   }
   @IBAction func cancelTapped(_ sender: UIButton) {
      self.isHidden = true
      for gesture in (experienceWrapper.golf?.screenView?.gestureRecognizers)!{
        gesture.isEnabled = true
      }
      self.isErrorAlertViewDismissed = true
      self.cancelButton.isHidden = true
      self.connectButton.isHidden = true
      self.connectSideView.isHidden = true
      self.connectTopView.isHidden = true
      self.closeImage.isHidden = false
      self.errorLine.isHidden = false
      self.closeButtonTapView.isHidden = false
      self.closeButtonTapView.isUserInteractionEnabled = true
      experienceWrapper.golf?.screenView?.blurEffectView.isHidden = true
   }
}

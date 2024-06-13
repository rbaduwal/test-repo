import UIKit
import Q

class MainContainerView: UIView {
   
   var widthConstraint:NSLayoutConstraint!
   @IBOutlet weak var replayTableView: ReplayTableUIView!
   @IBOutlet weak var liveTableView: liveTableUIView!
   @IBOutlet weak var segmentedControl: UISegmentedControl!
   @IBOutlet weak var expandAndCollapseConstraint:NSLayoutConstraint!
   @IBOutlet weak var roundAndSelectionView:RoundAndHoleSelectionView!
   @IBOutlet weak var holeSelectionButton:UIButton!
   @IBOutlet weak var roundSelectionButton:UIButton!
   @IBOutlet weak var segmentedControlView:UIView!
   
   override func awakeFromNib() {
      initialSetUp()
      setSegmentedControl()
      //liveTableView.getGameData(data: gameData)
      setShadow()
   }
   func initialSetUp() {
      liveTableView.isHidden = false
      replayTableView.isHidden = true
   }
   
   required init?(coder: NSCoder) {
      super.init(coder: coder)
   }
   
   func setConstraint(width:NSLayoutConstraint) {
      self.widthConstraint = width
   }
   func setSegmentedControl() {
      let font:UIFont = UIFont.systemFont(ofSize: 14)
      self.segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
      let selectedtitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: "#003A70")]
      let normaltitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(hexString: "#AFAFAF")]
      segmentedControl.setTitleTextAttributes(normaltitleTextAttributes, for: .normal)
      segmentedControl.setTitleTextAttributes(selectedtitleTextAttributes, for: .selected)
   }
   func setButtonBorder() {
      let lineView1 = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: holeSelectionButton.frame.size.height))
      lineView1.backgroundColor = UIColor.white
      holeSelectionButton.addSubview(lineView1)
      
      let lineView2 = UIView(frame: CGRect(x: 0, y: 0, width: 2, height: holeSelectionButton.frame.size.height))
      lineView2.backgroundColor = UIColor.white
      holeSelectionButton.addSubview(lineView2)
      roundSelectionButton.addSubview(lineView2)
   }
   func setShadow() {
      self.segmentedControlView.layer.shadowColor = UIColor.darkGray.cgColor
      self.segmentedControlView.layer.shadowOffset = CGSize(width: 0, height: 5)
      self.segmentedControlView.layer.shadowRadius = 5
      self.segmentedControlView.layer.shadowOpacity = 0.5
   }
   func setSelectedSegment(isLive: Bool) {
      if(isLive) {
         self.segmentedControl.selectedSegmentIndex = 0
         onLiveSelection()
      } else {
         self.segmentedControl.selectedSegmentIndex = 1
         onReplaySelection()
      }
   }
   func onLiveSelection() {
      UIView.transition(with: liveTableView, duration: 0.8, options: .transitionCrossDissolve, animations: {
         self.liveTableView.isHidden = false
      })
      UIView.transition(with: replayTableView, duration: 0.8, options: .transitionCrossDissolve, animations: {
         self.replayTableView.isHidden = true
      })
      Q.log.instance.push(.ANALYTICS, msg: "onLiveSelection", userInfo: nil)
   }
   func onReplaySelection() {
      UIView.transition(with: liveTableView, duration: 0.8, options: .transitionCrossDissolve, animations: {
         self.liveTableView.isHidden = true
      })
      UIView.transition(with: replayTableView, duration: 0.8, options: .transitionCrossDissolve, animations: {
         self.replayTableView.isHidden = false
      })
      Q.log.instance.push(.ANALYTICS, msg: "onReplaySelection", userInfo: nil)
   }
   
   @IBAction func segmentedControlAction(_ sender: UISegmentedControl) {
      
      switch segmentedControl.selectedSegmentIndex {
      case 0:
         onLiveSelection()
      case 1:
         onReplaySelection()
      default:
         break
      }
   }
}

import UIKit
import Q
import Q_ui

class TogglePlayerEntitiesVisibilityView: UIView {

   var visibilityModel: Q_ui.playerVisibilityModel?
   var isshotTrailButtonPressed: Bool = false
   var isplayerFlagButtonPressed: Bool = false
   var isapexButtonPressed: Bool = false
   var testArray: [Int] = [Int]()
   
   //Buttons
   @IBOutlet weak var contentView: UIView!
   @IBOutlet weak var shotTrailButton: UIButton!
   @IBOutlet weak var playerFlagButton: UIButton!
   @IBOutlet weak var apexButton: UIButton!
   
   @IBOutlet weak var playerName: UILabel!
   
   //ticks
   @IBOutlet weak var shortTrailLabel: UILabel!
   @IBOutlet weak var playerFlagLabel: UILabel!
   @IBOutlet weak var apexLabel: UILabel!
   
   override func awakeFromNib() {
      super.awakeFromNib()
      self.isHidden = true
      
      setLinearGradient()
      setContentViewCornerRadius()
      setUpTapGesture()
      addBottomLineForButtons()
      NotificationCenter.default.addObserver(self, selector: #selector(onPlayerCardTapped(_:)), name: Notification.Name(Q_ui.constants.onTappedNotification), object: nil)
   }
   func setUpTapGesture() {
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onContentViewTap))
      tapGestureRecognizer.cancelsTouchesInView = true
      self.addGestureRecognizer(tapGestureRecognizer)
   }
   func setLinearGradient() {
      let layer = CAGradientLayer()
      layer.frame = contentView.bounds
      layer.colors = [UIColor.white.cgColor,UIColor.black.cgColor]
      layer.startPoint = CGPoint(x: -7, y: -7)
      layer.endPoint = CGPoint(x: 1, y: 1)
      contentView.layer.insertSublayer(layer, at: 0)
   }
   func setContentViewCornerRadius() {
      self.contentView.layer.cornerRadius = 20
      self.contentView.layer.masksToBounds = true
   }
   func addBottomLineForButtons() {
      let shotTrailButtonLine = UIView(frame: CGRect(x: 0, y: 50, width: 290, height: 0.5))
      shotTrailButtonLine.backgroundColor = UIColor(hexString: "#FFFFFF", alpha: 0.1)
      shotTrailButton.addSubview(shotTrailButtonLine)
      
      let playerFlagButtonLine = UIView(frame: CGRect(x: 0, y: 50, width: 290, height: 0.5))
      playerFlagButtonLine.backgroundColor = UIColor(hexString: "#FFFFFF", alpha: 0.1)
      playerFlagButton.addSubview(playerFlagButtonLine)
   }
   @objc func onContentViewTap() {
      if let vm = self.visibilityModel {
         experienceWrapper.golf?.setPlayerVisibility(visibilityModel: vm)
         
         userInfo.instance.playerVisibilityModels = userInfo.instance.playerVisibilityModels.filter{!($0.player == vm.player)}
         userInfo.instance.playerVisibilityModels.append(vm)
         self.testArray.append(2)
         self.isHidden = true
      }
   }
   @objc func onPlayerCardTapped(_ notification: NSNotification) {
      if let selectedPlayer = notification.userInfo?["player"] as? Q.golfPlayer {
         if userInfo.instance.playerVisibilityModels.count > 0 {
            for vm in userInfo.instance.playerVisibilityModels {
               if selectedPlayer == vm.player {
                  self.visibilityModel = vm
                  break
               }
               self.visibilityModel = Q_ui.playerVisibilityModel(player: selectedPlayer,
                  isPlayerFlagVisible: true,
                  isShotTrailVisible: true,
                  isApexVisible: true)
            }
         } else {
            self.visibilityModel = Q_ui.playerVisibilityModel(player: selectedPlayer,
               isPlayerFlagVisible: true,
               isShotTrailVisible: true,
               isApexVisible: true)
         }
         self.isHidden = false
         if let vm = self.visibilityModel {
            setButtonStates(vm: vm)
            self.playerName.text = "\(String(describing: vm.player.sn)), \(vm.player.fn.uppercased().first ?? " ")"
         }
      }
   }
   func setButtonStates(vm: Q_ui.playerVisibilityModel) {
      if vm.isShotTrailVisible {
         self.shotTrailButton.setTitleColor(UIColor.yellow, for: .normal)
         self.shortTrailLabel.text = "✓"
         isshotTrailButtonPressed = true
      } else {
         self.shotTrailButton.setTitleColor(UIColor.white, for: .normal)
         self.shortTrailLabel.text = ""
         isshotTrailButtonPressed = false
      }
      
      if vm.isPlayerFlagVisible {
         self.playerFlagButton.setTitleColor(UIColor.yellow, for: .normal)
         self.playerFlagLabel.text = "✓"
         isplayerFlagButtonPressed = true
      } else {
         self.playerFlagButton.setTitleColor(UIColor.white, for: .normal)
         self.playerFlagLabel.text = ""
         isplayerFlagButtonPressed = false
      }
      
      if vm.isApexVisible {
         self.apexButton.setTitleColor(UIColor.yellow, for: .normal)
         self.apexLabel.text = "✓"
         isapexButtonPressed = true
      } else {
         self.apexButton.setTitleColor(UIColor.white, for: .normal)
         self.apexLabel.text = ""
         isapexButtonPressed = false
      }
   }
   @IBAction func shotTrailButtonAction(_ sender: UIButton) {
      if !isshotTrailButtonPressed {
         self.shotTrailButton.setTitleColor(UIColor.yellow, for: .normal)
         self.shortTrailLabel.text = "✓"
         self.visibilityModel?.isShotTrailVisible = true
         self.isshotTrailButtonPressed = true
      } else {
         self.shotTrailButton.setTitleColor(UIColor.white, for: .normal)
         self.shortTrailLabel.text = ""
         self.visibilityModel?.isShotTrailVisible = false
         self.isshotTrailButtonPressed = false
      }
   }
   @IBAction func playerFlagButtonAction(_ sender: UIButton) {
      if !isplayerFlagButtonPressed {
         self.playerFlagButton.setTitleColor(UIColor.yellow, for: .normal)
         self.playerFlagLabel.text = "✓"
         self.visibilityModel?.isPlayerFlagVisible = true
         self.isplayerFlagButtonPressed = true
      } else {
         self.playerFlagButton.setTitleColor(UIColor.white, for: .normal)
         self.playerFlagLabel.text = ""
         self.visibilityModel?.isPlayerFlagVisible = false
         self.isplayerFlagButtonPressed = false
      }
   }
   @IBAction func apexButtonAction(_ sender: UIButton) {
      if !isapexButtonPressed {
         self.apexButton.setTitleColor(UIColor.yellow, for: .normal)
         self.apexLabel.text = "✓"
         self.visibilityModel?.isApexVisible = true
         self.isapexButtonPressed = true
      } else {
         self.apexButton.setTitleColor(UIColor.white, for: .normal)
         self.apexLabel.text = ""
         self.visibilityModel?.isApexVisible = false
         self.isapexButtonPressed = false
      }
   }
}



import UIKit
import Q
import Q_ui

open class experienceView: PassThroughView {
   
   @IBOutlet weak var pgaLogo: UIImageView!
   @IBOutlet weak var mainContainerView: MainContainerView!
   @IBOutlet weak var playerDrawerButton: UIButton!
   @IBOutlet weak var widthConstraint: NSLayoutConstraint!
   @IBOutlet weak var playerContainerView: PlayerSelectionView!
   @IBOutlet weak var connectView: UIView!
   @IBOutlet weak var connectingView: UIView!
   @IBOutlet weak var connectViewText: UILabel!
   @IBOutlet weak var replayTableView: ReplayTableUIView!
   @IBOutlet weak var expandAndCollapseConstraint:NSLayoutConstraint!
   @IBOutlet weak var roundAndSelectionView:RoundAndHoleSelectionView!
   @IBOutlet weak var liveTableView: liveTableUIView!
   @IBOutlet weak var togglePlayerEntitiesVisibilityView: TogglePlayerEntitiesVisibilityView!
   @IBOutlet weak var liveView: UIView!
   @IBOutlet weak var connectButton: UIButton!
   @IBOutlet weak var debugInfo: UILabel!
   @IBOutlet weak var featuredHoleView: UIView!
   @IBOutlet weak var featuredHolePicker: UIPickerView!
   @IBOutlet weak var innerConnectView: InnerConnectUIView!
   @IBOutlet weak var errorAlertView: ErrorAlertView!
   @IBOutlet weak var connectingTextLabel: UILabel!
   @IBOutlet weak var oobeView: NewOOBEView!
   
   // properties
   var live: [String: Any] = ["hole": 0, "par": 0, "yrds": 0, "players": [Q.golfPlayer](), "playerCount": 0]
   var liveDetails: [[String: Any]] = []
   var totalRounds = Int()
   var totalHoles = Int()
   var selectedRoundNum = Int()
   var selectedHoleNum = Int()
   var players: [golfPlayer] = []
   var livePlayers: [golfPlayer] = []
   var playedThroughPlayers: [golfPlayer] = []
   var favoritePlayers: [golfPlayer] = []
   var featuredHoles: [Q.golfHole]? = nil
   var pickerViewRowTitleArray: [String] = [String]()
   var isHoleChangedFromDropDown: Bool = false
   var sportDataLoadingCompleted: Bool = false
   var isHoleSelected: Bool = false
   var isRegistrationSatisfied: Bool = false
   var groupOnReplayAvailable:Int = 0
   var blurEffectView:CustomIntensityVisualEffectView!
   var currentRoundNum: Int? = nil
   let notificationCenter = UNUserNotificationCenter.current()
   public var enableDebugLabel: Bool = false {
      didSet {
         DispatchQueue.main.async {
            if self.enableDebugLabel {
               self.debugInfo.isHidden = false
            } else {
               self.debugInfo.isHidden = true
            }
         }
      }
   }
   public var enableOobeView: Bool = false {
      didSet {
         DispatchQueue.main.async {
            if self.enableOobeView {
               self.oobeView.isHidden = false
            } else {
               self.oobeView.isHidden = true
            }
         }
      }
   }
   public var enableInAppNotifications: Bool = false
   public var viewModel: golfViewModel? {
      didSet {
         onViewModelUpdated()
      }
   }
   public static let defaultPlayerImg = UIImage.fromSdkBundle(named: "defaultPlayer")
   
   // init/deinit
   required public init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   deinit {
       self.roundAndSelectionView.roundAndHoleSelectionDelegate = nil
   }
   
   // public functions
   open override func awakeFromNib() {
      super.awakeFromNib()
      setColorForConnectViewVector()
      self.initialSetUp()
      self.roundAndSelectionView.roundAndHoleSelectionDelegate = self
      self.featuredHolePicker.dataSource = self
      self.featuredHolePicker.delegate = self
      self.notificationCenter.delegate = self
      self.setUpTouchForConnectView()
      self.requestPermissionForNotification()
      // Assuming a sport data object exists, we are guaranteed to have some archive data available.
      // Listen to the live sync callback so we know when live data is available, and call it now if
      // we are already synced
      if let sd = experienceWrapper.golf?.sportData {
         sd.liveSynced = onSportDataLoadingCompleted
         if sd.isDataSynced {
            onSportDataLoadingCompleted(sportData: sd)
         }
      }
   }
   open override func layoutSubviews() {
      super.layoutSubviews()
   }
   public func hidePlayerDrawerOnHoleChangeFromDropDown() {
      self.expandAndCollapseConstraint.constant = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
      UIView.animate(withDuration: 0.75) {
         self.layoutIfNeeded()
      } completion: { _ in
         self.isHoleChangedFromDropDown = false
         self.mainContainerView.isHidden = true
         self.expandAndCollapseConstraint.constant = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 116
      }
   }
   public func reloadPlayerData() {
      self.updateLiveTable()
      // TODO: Should not assume first hole, use fop instead
      roundAndSelectionView.setHoles(holes: self.viewModel?.sportData?.currentCourse?.featuredHoles ?? [])
      if let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
         if let activeRounds = self.viewModel?.sportData?.activeRounds {
            //todo: only for current version
            roundAndSelectionView.setRounds(rounds: activeRounds)
            roundAndSelectionView.setRoundDropdownTitle(round: selectedRoundNum)
            roundAndSelectionView.setHoleDropdownTitle(hole: currentHole.num)
         } else {
            roundAndSelectionView.setRounds(rounds: [])
         }
         if let currentRound = self.viewModel?.sportData?.currentRound {
            // Create a list of players, sorted in reverse order of play
            let groups = currentRound.orderedGroups(forHole: currentHole)
            var players = [Q.golfPlayer]()
            for group in groups {
               for player in group.players {
                  players.append(player)
               }
            }
            players.reverse()
            var playedThroughGroups = groups.filter({ golfGroup in
               golfGroup.location(forHole: currentHole) == .DONE
            })
            playedThroughGroups.reverse()
            playerContainerView.setPlayerInfos(playedThroughGroups: playedThroughGroups, lastLiveGroup: playedThroughGroups.first)
            playerContainerView.setCurrentRoundLabel(round: currentRound.num)
            playerContainerView.setCurrentHoleLabel(hole: self.selectedHoleNum)
         }
      }
      reloadReplayTable()
      if self.currentRoundNum == nil {
         self.currentRoundNum = self.viewModel?.sportData?.currentRound?.num
      }
   }
   public func resetArElementsOnRoundChange() {
      playerContainerView.selectedFavoritedPlayers.removeAll()
      experienceWrapper.golf?.removeReplays()
      playerContainerView.resetSelectedGroup()
      playerContainerView.isGroupPlayAnimating = .stopped
      playerContainerView.selectedPlayers.removeAll()
      userInfo.instance.playerVisibilityModels.removeAll()
   }
   public func checkRoundChanged() {
      if let currentRound = currentRoundNum {
         if currentRound != self.viewModel?.sportData?.currentRound?.num {
            resetArElementsOnRoundChange()
         }
      }
      self.currentRoundNum = self.viewModel?.sportData?.currentRound?.num
   }
   public func updateConnectUI() {
      if isRegistrationSatisfied && self.sportDataLoadingCompleted && self.isHoleSelected && experienceWrapper.golf?.userIsAtCourse ?? true {
         self.showViewForSatisfiedRegistrationCondition()
      } else {
         self.showViewForFailedRegistrationCondition()
      }
   }
   
   // private functions
   @objc private func onPlayerDataUpdated(_ notification: Notification) {
      if let hole = notification.userInfo?["data"] as? Q.golfHole{
         if hole.num == self.selectedHoleNum {
            if let groupOnReplay = getPlayedThroughGroups(hole: hole).first, (groupOnReplay.tid != groupOnReplayAvailable && enableInAppNotifications) {
               groupOnReplayAvailable = groupOnReplay.tid
               self.sendGroupReplayAvailableNotification(group: groupOnReplay)
            }
         }
      }
      DispatchQueue.main.async {
         self.checkRoundChanged()
         self.reloadPlayerData()
      }
   }
   func sendGroupReplayAvailableNotification(group: Q.golfGroup) {
      var playerNames:String = ""
      let players = group.players
      if players.count == 1 {
         playerNames = players[0].nameLastCommaFirstInitial
      } else if(players.count == 2) {
         playerNames = "\(players[0].nameLastCommaFirstInitial) and \(players[1].nameLastCommaFirstInitial)"
      } else if(players.count == 3) {
         playerNames = "\(players[0].nameLastCommaFirstInitial), \(players[1].nameLastCommaFirstInitial) and \(players[2].nameLastCommaFirstInitial)"
      } else if(players.count == 3) {
         playerNames = "\(players[0].nameLastCommaFirstInitial), \(players[1].nameLastCommaFirstInitial), \(players[2].nameLastCommaFirstInitial) and \(players[3].nameLastCommaFirstInitial)"
      }
      self.sendInAppNotificationForGroupReplay(playerNames: playerNames)
   }
   func sendInAppNotificationForGroupReplay(playerNames: String) {
      let content = UNMutableNotificationContent()
      content.categoryIdentifier = UUID().uuidString
      content.title = String(format: "%@ \(configurableText.instance.getText(id: messageType.groupPlayNotificationTitle))", playerNames)
      content.sound = UNNotificationSound.default
      let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
      let identifier = UUID().uuidString
      let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(request) { error in
      }
   }
   func getPlayedThroughGroups(hole: Q.golfHole) -> [Q.golfGroup] {
      var playedThroughGroups: [Q.golfGroup] = []
      let currentRound = self.viewModel?.sportData?.currentRound
      let groups = currentRound?.orderedGroups(forHole: hole)
      guard let groups = groups else {return []}
      playedThroughGroups = groups.filter({ golfGroup in
         return golfGroup.location(forHole: hole) == .DONE
      })
      return playedThroughGroups.reversed()
   }
   func requestPermissionForNotification() {
       notificationCenter.requestAuthorization(options: [.alert,.sound]) { granted, error in
           if granted {
              experienceWrapper.golf?.enableInAppNotifications = true
           } else {
              experienceWrapper.golf?.enableInAppNotifications = false
           }
       }
   }
   @objc private func handConnectViewTap(recognizer: UITapGestureRecognizer) {
      if isHoleChangedFromDropDown {
         self.hidePlayerDrawerOnHoleChangeFromDropDown()
      }
   }
   @objc private func onDeviceStateChange(_ notification: Notification) {
       DispatchQueue.main.async { [weak self] in
           guard let self = self else { return }
           if let isRegistrationConditionSatisfied = notification.userInfo?["isRegistrationConditionSatisfied"] as? Bool {
              self.isRegistrationSatisfied = isRegistrationConditionSatisfied
              self.updateConnectUI()
           }
       }
   }
   @objc private func respondToSwipeGesture(gesture: UIGestureRecognizer) {
      if let swipeGesture = gesture as? UISwipeGestureRecognizer {
         switch swipeGesture.direction {
         case UISwipeGestureRecognizer.Direction.right:
            if isHoleChangedFromDropDown {
               self.expandAndCollapseConstraint.constant = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
            }else {
               self.expandAndCollapseConstraint.constant = UIScreen.main.bounds.width - 116
            }
            UIView.animate(withDuration: 0.75) {
               self.layoutIfNeeded()
            }completion: { _ in
               if self.isHoleChangedFromDropDown {
                  self.isHoleChangedFromDropDown = false
                  self.mainContainerView.isHidden = true
                  self.expandAndCollapseConstraint.constant = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) - 116
               }
            }
         case UISwipeGestureRecognizer.Direction.left:
            
            self.expandAndCollapseConstraint.constant = UIScreen.main.bounds.width - 391
            UIView.animate(withDuration: 0.75) {
               self.layoutIfNeeded()
            }
         default:
            break
         }
      }
   }
   private func onViewModelUpdated() {
      DispatchQueue.main.async {
         self.selectedRoundNum = experienceWrapper.golf?.sportData?.currentRound?.num ?? 1
         if let selectedHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
            self.selectedHoleNum = selectedHole.num
            self.featuredHoles = experienceWrapper.golf?.cop?.featuredHoles
            self.setInitialPickerViewData()
            self.reloadPlayerData()
         }
      }
   }
   private func initialSetUp() {
      self.errorAlertView.isHidden = true
      self.connectingTextLabel.text = configurableText.instance.getText(id: .connectingMessage)
      self.connectViewText.text = configurableText.instance.getText(id: .messageOnConnectedToHole)
      playerDrawerButton.layer.zPosition = 999
      liveView.layer.zPosition = 999
      liveView.applySketchShadowToView(color: .black, alpha: 0.25, x: 0, y: 4, blur: 8, spread: 0)
      self.expandAndCollapseConstraint.constant = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width) - 116
      
      let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
      swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
      self.addGestureRecognizer(swipeLeft)
      
      let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
      swipeRight.direction = UISwipeGestureRecognizer.Direction.right
      self.addGestureRecognizer(swipeRight)
      connectButton.setBackgroundColor(UIColor.black, forState: .selected)
      connectButton.setBackgroundColor(UIColor.black, forState: .highlighted)
      self.mainContainerView.isHidden = true
      self.playerContainerView.isHidden = true
      self.replayTableView.clearOldFavoritedPlayers()
      self.mainContainerView.layer.cornerRadius = 10
      self.mainContainerView.layer.maskedCorners = [.layerMinXMinYCorner]
   }
   private func setColorForConnectViewVector() {
      self.connectButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
      self.connectButton.layer.shadowRadius = 12
      self.connectButton.layer.shadowOpacity = 1
      self.connectButton.layer.shadowOffset = CGSize(width: 4, height: 4)
      self.connectButton.layer.cornerRadius = 12
      self.featuredHoleView.layer.cornerRadius = 12
   }
   private func showViewForSatisfiedRegistrationCondition() {
      DispatchQueue.main.async {
         self.connectButton.backgroundColor = .black.withAlphaComponent(0.7)
         self.connectButton.setTitleColor(.green, for: .normal)
         self.connectButton.layer.cornerRadius = 12
         self.innerConnectView.changeVectorColor(color: UIColor(hexString: "#01FD1A").withAlphaComponent(0.5))
         self.connectButton.isUserInteractionEnabled = true
      }
   }
   private func showViewForFailedRegistrationCondition() {
      DispatchQueue.main.async {
         self.connectButton.backgroundColor = .black.withAlphaComponent(0.15)
         self.connectButton.setTitleColor(.white.withAlphaComponent(0.2), for: .normal)
         self.connectButton.layer.cornerRadius = 12
         self.innerConnectView.changeVectorColor(color: UIColor.white.withAlphaComponent(0.3))
         self.connectButton.isUserInteractionEnabled = false
      }
   }
   private func setInitialPickerViewData() {
      guard let featuredHoles = featuredHoles else {return}
      self.pickerViewRowTitleArray.append("SELECT")
      featuredHoles.forEach { featuredHole in
         self.pickerViewRowTitleArray.append("Hole\(featuredHole.num)")
      }
   }
   private func setUpTouchForConnectView() {
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handConnectViewTap(recognizer:)))
      self.connectView.addGestureRecognizer(tapGestureRecognizer)
   }
   private func reloadReplayTable() {
      guard let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) else { return }
      if self.selectedHoleNum >= 0 && self.selectedRoundNum >= 0 {
         if let selectedRound = self.viewModel?.sportData?.rounds[self.selectedRoundNum - 1] {
            let groups = selectedRound.orderedGroups(forHole: currentHole)
            var filteredPlayers = [Q.golfPlayer]()
            for group in groups {
               for player in group.players {
                  if let playedHole = player.playedHoles.first(where: {$0.num == self.selectedHoleNum}) {
                     let combinedTrace = playedHole.combinedTrace
                     if !combinedTrace.isEmpty {
                        filteredPlayers.append(player)
                     }
                  }
               }
            }
            replayTableView.setPlayers(players: filteredPlayers)
            replayTableView.setFavoritedPlayers()
         }
      }
   }
   private func onSportDataLoadingCompleted(sportData: sportData) {
      DispatchQueue.main.async {
         self.sportDataLoadingCompleted = true
         self.endObserve()
         self.beginObserve()
         self.mainContainerView.liveTableView.listAutoScrolledOnce = false
         if let vm = self.viewModel {
            self.selectedRoundNum = vm.sportData?.currentRound?.num ?? 1
            if let selectedHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
               self.selectedHoleNum = selectedHole.num
               self.reloadPlayerData()
            }
         }
      }
   }
   private func beginObserve() {
      NotificationCenter.default.addObserver(self, selector: #selector(onPlayerDataUpdated), name: Notification.Name(Q.constants.playerDidChangeNotification), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(onPlayerDataUpdated), name: Notification.Name(Q.constants.groupLocationChangedNotification), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(onDeviceStateChange),name: .deviceState, object: nil)
   }
   private func endObserve() {
      NotificationCenter.default.removeObserver(self, name: Notification.Name(Q.constants.groupLocationChangedNotification), object: nil)
      NotificationCenter.default.removeObserver(self, name: Notification.Name(Q.constants.playerDidChangeNotification), object: nil)
      NotificationCenter.default.removeObserver(self, name: Notification.Name.deviceState, object: nil)
   }
   private func removeIndicatorAndUpdateView()  {
      mainContainerView.isHidden = false
      connectView.isHidden = false
   }
   private func updateLiveTable() {
      
      var holesDetail:[liveTableUIView.liveTableDetails] = []
      if let holes = self.viewModel?.sportData?.currentCourse?.holes {
         for hole in holes {
            var livePlayers:[Q.golfPlayer]? = nil
            if let liveGroupId = hole.liveGroups.first,
               let groups = experienceWrapper.golf?.sportData?.currentRound?.groups,
               let liveGroup = groups[liveGroupId] {
               livePlayers = liveGroup.players
            }
            let holeDetail = liveTableUIView.liveTableDetails(hole: hole, players: livePlayers)
            holesDetail.append(holeDetail)
         }
      }
      
      DispatchQueue.main.async {
         self.liveTableView.setLiveDetails(details: holesDetail)
      }
   }
   private func showHoleConnectConfirmationAlert(selectedHole: String) {
      if let hole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == selectedHole} ) {
         self.errorAlertView.titleTextLabel.font = .systemFont(ofSize: 14, weight: .bold)
         let holeConfirmationText = configurableText.instance.getText(id: .holeConfirmationMessage) + String(hole.num) + "?"
         self.errorAlertView.setErrorTitleAndText(titleText: holeConfirmationText, infoText: "")
      }
      self.errorAlertView.isHidden = false
      for gesture in self.gestureRecognizers!{
        gesture.isEnabled = false
      }
      self.errorAlertView.showViewForConnectMsg(hole: selectedHole)
      let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
      blurEffectView = CustomIntensityVisualEffectView(effect: blurEffect,  intensity: 0.075)
      blurEffectView.frame = self.bounds
      self.addSubview(blurEffectView)
      self.bringSubviewToFront(errorAlertView)
   }
}

extension experienceView: RoundAndHoleSelectionDelegate {
   func onRoundSelected(round: Int) {
      self.selectedRoundNum = round
      self.reloadReplayTable()
      if let currentRoundNum = self.viewModel?.sportData?.currentRound?.num {
         if selectedRoundNum < currentRoundNum {
            experienceWrapper.golf?.switchToReplay()
            self.playerContainerView.switchToReplayLabel()
            self.playerContainerView.scrollToReplay()
            self.mainContainerView.setSelectedSegment(isLive: false)
         } else if currentRoundNum == selectedRoundNum {
            experienceWrapper.golf?.switchToLive()
            self.mainContainerView.setSelectedSegment(isLive: true)
            experienceWrapper.golf?.screenView?.playerContainerView.deselectNonLivePlayers()
            self.playerContainerView.scrollToLive()
         }
      }
      Q.log.instance.push(.ANALYTICS, msg: "onRoundSelectionFromDropdown", userInfo: ["selectedRoundNumber":round])
   }
   func onHoleSelected(hole: String) {
      if experienceWrapper.golf?.fop != hole {
         self.showHoleConnectConfirmationAlert(selectedHole: hole)
      }
   }
}

extension experienceView: UIPickerViewDelegate, UIPickerViewDataSource {
   public func numberOfComponents(in pickerView: UIPickerView) -> Int {
      return 1
   }
   public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
      return self.pickerViewRowTitleArray.count
   }
   public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
      //To hide pickerView row selection indicator
      pickerView.subviews[1].isHidden = true
      var label = UILabel()
      if let v = view {
         label = v as! UILabel
      }
      label.text = pickerViewRowTitleArray[row]
      label.textColor = UIColor.white
      label.textAlignment = .center
      if pickerView.selectedRow(inComponent: component) == row {
         label.font = UIFont (name: "AvenirNextCondensed-DemiBold", size: 30)
         return label
      } else {
         label.font = UIFont (name: "AvenirNextCondensed-Medium", size: 30)
         return label
      }
   }
   public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
      return 30
   }
   public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
      pickerView.reloadAllComponents()
      if row != 0 {
         if let featuredHoles = self.featuredHoles {
            self.isHoleSelected = true
            if self.isRegistrationSatisfied && experienceWrapper.golf?.userIsAtCourse ?? true {
               self.showViewForSatisfiedRegistrationCondition()
            }
            self.selectedHoleNum = featuredHoles[row-1].num
            experienceWrapper.golf?.onFopChanged(featuredHoles[row-1].fop)
            Q.log.instance.push(.ANALYTICS, msg: "onHoleSelectionFromPicker", userInfo: ["selectedHoleNumber":featuredHoles[row-1].fop])
         }
      } else {
         self.isHoleSelected = false
         self.showViewForFailedRegistrationCondition()
      }
   }
}

extension experienceView: UNUserNotificationCenterDelegate {
   public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
      completionHandler([.banner,.sound, .list])
   }
}

extension UILabel {
   func addCharacterSpacing(kernValue: Double = 3) {
      if let labelText = text, labelText.isEmpty == false {
         let attributedString = NSMutableAttributedString(string: labelText)
         attributedString.addAttribute(.kern,
            value: kernValue,
            range: NSRange(location: 0, length: attributedString.length - 1))
         attributedText = attributedString
      }
   }
}

extension UIButton {
   func setBackgroundColor(_ color: UIColor, forState controlState: UIControl.State) {
      let colorImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
         color.setFill()
         UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1, height: 1)).fill()
      }
      setBackgroundImage(colorImage, for: controlState)
   }
}

extension UIView {
   func applySketchShadowToView(color: UIColor = .black,
      alpha: Float = 0.5,
      x: CGFloat = 0,
      y: CGFloat = 0,
      blur: CGFloat = 8,
      spread: CGFloat = 0) {
      
      layer.shadowColor = color.cgColor
      layer.shadowOpacity = alpha
      layer.shadowOffset = CGSize(width: x, height: y)
      layer.shadowRadius = blur / 2.0
      if spread == 0 {
         layer.shadowPath = nil
      } else {
         let dx = -spread
         let rect = bounds.insetBy(dx: dx, dy: dx)
         layer.shadowPath = UIBezierPath(rect: rect).cgPath
      }
   }
   func loadViewFromNib(_ nibName: String) -> UIView? {
       // grabs the appropriate bundle
       let bundle = Bundle(for: type(of: self))
       let nib = UINib(nibName: nibName, bundle: bundle)
       return nib.instantiate(withOwner: self, options: nil).first as? UIView
   }
}

enum groupPlayAnimating {
   case stopped
   case paused
   case playing
}

open class PassThroughView: UIView {
   open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
      let hitView = super.hitTest(point, with: event)
      if hitView?.isKind(of: PassThroughView.self) ?? false {
          return nil
      } else {
          return hitView
      }
   }
}

// Use this when loading nibs from the SDK or experience wrapper
public extension UINib {
   static func fromSdkBundle(_ nibName: String) -> UINib? {
   
      // grab the appropriate bundle. If the app uses the QSDK frameworks
      // directly then our resources are in the app's bundle, otherwise
      // they are in the special 'module' bundle.
#if NO_SPM
      let bundle = Bundle.main
      // let bundle = Bundle(for: experienceView.self)
#else
      let bundle = Bundle.module
#endif
      return UINib(nibName: nibName, bundle: bundle)
   }
}

// Use this when loading icons and images from the SDK or experience wrapper
public extension UIImage {
   static func fromSdkBundle(named assetName: String) -> UIImage? {
   
      // grab the appropriate bundle. If the app uses the QSDK frameworks
      // directly then our resources are in the app's bundle, otherwise
      // they are in the special 'module' bundle.
#if NO_SPM
      let bundle = Bundle.main
      // let bundle = Bundle(for: experienceView.self)
#else
      let bundle = Bundle.module
#endif
      return UIImage(named: assetName, in: bundle, with: nil)
   }
}

import UIKit
import Q_ui
import Q

class PlayerSelectionView: UIView {
   
   @IBOutlet weak var liveLabel: UILabel!
   @IBOutlet weak var roundLabel: UILabel!
   @IBOutlet weak var holeLabel: UILabel!
   @IBOutlet weak var last_liveLabelOne: UILabel!
   @IBOutlet weak var last_liveLabelTwo: UILabel!
    
   var isLive: Bool = true
   var player: [Q.golfPlayer] = []
   var tableView = UITableView()
   var userScrolledToReplay = false
   var showsUpcoming = false
   var selectedPlayers: [Q.golfPlayer] = []
   var selectedFavoritedPlayers:[Q.golfPlayer] = []
   var favoritePlayers:[Q.golfPlayer] = []
   var playerInfos: [Q.golfPlayer] = []
   var playerDrawerArrays:[[String:[Any]]] = []
   var addDummiesToPlayedThrough = false
   var isDataLoadedOnce: Bool = false

   var gameRound: Int = 1
   var gameHole: Int = 7
   let liveBGColor = UIColor(hexString: "#002547")
   let replayTextColor = UIColor(hexString: "#003A70")
   var playedThroughGroups:[Q.golfGroup] = []
   var selectedGroup:Q.golfGroup? = nil
   var lastLiveGroup:Q.golfGroup? = nil
   var isGroupPlayAnimating: groupPlayAnimating = .stopped
   
   override func awakeFromNib() {
      switchToLive()
      setLiveAndPlayedThroughPlayer()
      setup()
      tableView.delegate = self
      tableView.dataSource = self
      
      self.tableView.register(UINib.fromSdkBundle("liveReplayPlayerTableViewCell"), forCellReuseIdentifier: "liveReplayPlayerTableViewCell")
      self.tableView.register(UINib.fromSdkBundle("PlayedThroughCell"            ), forCellReuseIdentifier: "playedThroughCell")
      self.tableView.register(UINib.fromSdkBundle("replayPlayersTableViewCell"   ), forCellReuseIdentifier: "replayPlayersTableViewCell")
      setGestureRecognizerForDismissDropDown()
   }
   override func didMoveToWindow() {
      super.didMoveToWindow()
      // screenview is set only at this point.
      experienceWrapper.golf?.screenView?.replayTableView.replayTableViewDelegate = self
      experienceWrapper.golf?.screenView?.replayTableView.setFavoritedPlayers()
      self.setLiveAndPlayedThroughPlayer()
   }
   required public init?(coder aDecoder: NSCoder) {
      super.init(coder: aDecoder)
   }
   func setGestureRecognizerForDismissDropDown() {
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedPlayerCard))
      tapGesture.cancelsTouchesInView = false
      self.tableView.addGestureRecognizer(tapGesture)
      self.liveLabel.isUserInteractionEnabled = true
      self.last_liveLabelOne.isUserInteractionEnabled = true
      self.last_liveLabelTwo.isUserInteractionEnabled = true
      self.roundLabel.isUserInteractionEnabled = true
      self.holeLabel.isUserInteractionEnabled = true
      self.liveLabel.addGestureRecognizer(UITapGestureRecognizer(target:self , action: #selector(tappedPlayerCard)))
      self.last_liveLabelOne.addGestureRecognizer(UITapGestureRecognizer(target:self , action: #selector(tappedPlayerCard)))
      self.last_liveLabelTwo.addGestureRecognizer(UITapGestureRecognizer(target:self , action: #selector(tappedPlayerCard)))
      self.roundLabel.addGestureRecognizer(UITapGestureRecognizer(target:self , action: #selector(tappedPlayerCard)))
      self.holeLabel.addGestureRecognizer(UITapGestureRecognizer(target:self , action: #selector(tappedPlayerCard)))
   }
   func setCurrentRoundLabel(round: Int?) {
      if let round = round {
         self.roundLabel.text = "R\(round)"
      } else {
         self.roundLabel.text = "R"
      }
   }
   func setCurrentHoleLabel(hole: Int?) {
      if let hole = hole {
         self.holeLabel.text = "H\(hole)"
      } else {
         self.roundLabel.text = "H"
      }
   }
   @objc func tappedPlayerCard() {
      if let roundAndSelectionView = experienceWrapper.golf?.screenView?.roundAndSelectionView {
         if roundAndSelectionView.dropDown != -1 {
            roundAndSelectionView.dismissDropdown()
         }
      }
   }
   func setPlayerInfos(playedThroughGroups: [Q.golfGroup], lastLiveGroup: Q.golfGroup?) {
      self.playedThroughGroups = playedThroughGroups
      self.lastLiveGroup = lastLiveGroup
      setLiveAndPlayedThroughPlayer()
      if self.lastLiveGroup == nil {
         self.switchToReplayLabel()
      } else if self.lastLiveGroup != nil && !self.isDataLoadedOnce {
         // isDataLoadedOnce is used to fix the issues which would arise when we receive group array as empty when initially loading the table view
         self.switchToLive()
         self.isDataLoadedOnce = true
      }
      self.tableView.reloadData()
   }
   func setLiveAndPlayedThroughPlayer() {
      self.playerDrawerArrays.removeAll()
      
      if let lastLiveGroup = lastLiveGroup {
         showsUpcoming = false
         playerDrawerArrays.append(["LIVE_REPLAY": [lastLiveGroup]])
      }
      
      if !favoritePlayers.isEmpty {
         playerDrawerArrays.append(["FAVORITE": favoritePlayers])
      }
      
      if !self.playedThroughGroups.isEmpty {
         playerDrawerArrays.append(["REPLAY": self.playedThroughGroups])
      }
      
      // to calculate the bottom padding when played through players are empty or the total height of the section is less than the tableView height
      if tableView.numberOfSections > 1 {
         let playedThroughSectionHeight = tableView.numberOfSections == 3 ? (tableView.rect(forSection: 1).height + tableView.rect(forSection: 2).height) + 10.0 : (tableView.rect(forSection: 1).height) + 10.0
         self.setTableViewBottomContentInset(playedThroughSectionHeight: playedThroughSectionHeight)
      } else if tableView.numberOfSections == 1 && !(playerDrawerArrays.first?.keys.first ?? "" == "LIVE_REPLAY") {
         let playedThroughSectionHeight = (tableView.rect(forSection: 0).height) + 10.0
         self.setTableViewBottomContentInset(playedThroughSectionHeight: playedThroughSectionHeight)
      }
      
      tableView.reloadData()
   }
   func setTableViewBottomContentInset(playedThroughSectionHeight: CGFloat) {
      if tableView.frame.height - playedThroughSectionHeight <= 0 {
         addDummiesToPlayedThrough = false
         tableView.contentInset.bottom = 0
      } else {
         addDummiesToPlayedThrough = playedThroughGroups.isEmpty
         tableView.contentInset.bottom = tableView.frame.height - playedThroughSectionHeight
      }
   }
   func setup() {
      tableView.automaticallyAdjustsScrollIndicatorInsets = false
      tableView = UITableView(frame: CGRect(x: -6, y: self.frame.height*0.25, width: self.frame.width, height:self.frame.height*0.74),style: .plain)
      
      tableView.insetsContentViewsToSafeArea = false//solved the issue where cell was being compressed
      tableView.separatorColor = .clear
      tableView.showsVerticalScrollIndicator = false
      tableView.bounces = false
      tableView.backgroundColor = UIColor.clear
      tableView.allowsSelection = true
      self.addSubview(tableView)
      setConstraintsToTableView()
   }
   func setConstraintsToTableView() {
      tableView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
         //tableView.widthAnchor.constraint(equalToConstant: self.frame.width),
         tableView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 0),
         tableView.rightAnchor.constraint(equalTo: self.rightAnchor,constant: 0),
         tableView.topAnchor.constraint(equalTo: self.topAnchor, constant: 90),
         tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0)
      ])
   }
   func setPlayers(players: [Q.golfPlayer]) {
      self.player = players
   }
   func switchToReplayLabel() {
      self.last_liveLabelOne.isHidden = true
      self.last_liveLabelTwo.isHidden = true
      self.liveLabel.isHidden = false

      self.backgroundColor = .white
      self.liveLabel.text = "REPLAY"
      self.liveLabel.alpha = 1
      self.liveLabel.backgroundColor = UIColor(hexString: "#4D759B")
      self.liveLabel.transform = .identity
      UIView.animate(withDuration: 0.5) { [weak self] in
         self?.liveLabel.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
         self?.liveLabel.transform = .identity
      }
      self.isLive = false
      self.tableView.reloadData()
   }
   func scrollToReplay() {
      userScrolledToReplay = true
      for(index, item) in playerDrawerArrays.enumerated() {
         if item.keys.first == "FAVORITE" && tableView.numberOfRows(inSection: index) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top, animated: true)
            return
         } else if item.keys.first == "REPLAY" && tableView.numberOfRows(inSection: index) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top, animated: true)
         }
      }
   }
   func switchToLive() {
      if !self.isLive {
         // This is for auto scrolling the live table when a hole changed or data is updated for the first time.
         // After that when data is updated the table will persists on the position the usr scrolled it to.
         experienceWrapper.golf?.screenView?.liveTableView.listAutoScrolledOnce = false
      }

      self.liveLabel.isHidden = true
      self.last_liveLabelOne.isHidden = false
      self.last_liveLabelOne.text = "LAST"
      self.last_liveLabelOne.addCharacterSpacing(kernValue: 1)
      self.last_liveLabelOne.backgroundColor = UIColor(hexString: "#E8000B")
      self.last_liveLabelOne.layer.borderColor = UIColor.clear.cgColor
      self.last_liveLabelTwo.isHidden = false
      self.last_liveLabelTwo.text = "GROUP"

      self.last_liveLabelTwo.addCharacterSpacing(kernValue: 1)
      self.last_liveLabelTwo.backgroundColor = UIColor(hexString: "#E8000B")
      self.last_liveLabelTwo.layer.borderColor = UIColor.clear.cgColor

      self.backgroundColor = liveBGColor
      self.isLive = true
      self.last_liveLabelOne.alpha = 1
      self.last_liveLabelTwo.alpha = 1
      self.last_liveLabelOne.transform = .identity
      self.last_liveLabelTwo.transform = .identity
      UIView.animate(withDuration: 0.5) { [weak self] in
         self?.last_liveLabelOne.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
         self?.last_liveLabelOne.transform = .identity
         self?.last_liveLabelTwo.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
         self?.last_liveLabelTwo.transform = .identity
      }
      setLiveAndPlayedThroughPlayer()
   }
   func scrollToLive() {
      userScrolledToReplay = false
      if playerDrawerArrays.isEmpty {
         experienceWrapper.golf?.switchToLive()
         switchToLive()
      } else {
         for(index, item) in playerDrawerArrays.enumerated() {
            if item.keys.first == "LIVE_REPLAY" && tableView.numberOfRows(inSection: index) > 0 {
               self.tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top, animated: true)
               experienceWrapper.golf?.switchToLive()
               break
            } else {
               experienceWrapper.golf?.switchToLive()
               switchToLive()
            }
         }
      }
   }
   func addToSelectedPlayers(player: Q.golfPlayer) {
      selectedPlayers.append(player)
   }
   func removeFromSelectedPlayers(player: Q.golfPlayer) {
      selectedPlayers.removeAll( where: {$0 == player} )
   }
   func ifReplayPlayerSelected(player: Q.golfPlayer) -> Bool {
       return (self.selectedPlayers.contains(player))
   }
   func setSelectedGroups(group: Q.golfGroup) {
       self.selectedGroup = group
   }
   func resetSelectedGroup() {
       self.isGroupPlayAnimating = .stopped
       self.selectedGroup = nil
   }
   func deselectNonLivePlayers() {
       self.selectedPlayers.removeAll()
       self.selectedFavoritedPlayers.removeAll()
   }
   func ifSelected(player: Q.golfPlayer) -> Bool {
      for i in selectedPlayers.indices {
         if selectedPlayers[i].pid == player.pid && selectedPlayers[i].team?.round.num == player.team?.round.num {
            return true
         }
      }
      return false
   }
   func ifFavoritedPlayerSelected(player:Q.golfPlayer) -> Bool {
       return (self.selectedFavoritedPlayers.contains(player))
   }
   func addToSelectedFavoritePlayers(player:Q.golfPlayer) {
       selectedFavoritedPlayers.append(player)
   }
   func removeFromFavoritedSelectedPlayers(player:Q.golfPlayer) {
      selectedFavoritedPlayers.removeAll( where: {$0 == player})
   }
}

extension PlayerSelectionView: UITableViewDelegate, UITableViewDataSource {
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return playerDrawerArrays.count
   }
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if section < playerDrawerArrays.count {
         return playerDrawerArrays[section].values.first?.count ?? 0
      } else {
         return 0
      }
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      if let sectionName = playerDrawerArrays[indexPath.section].keys.first {
         if sectionName == "LIVE_REPLAY" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "liveReplayPlayerTableViewCell") as! liveReplayPlayerTableViewCell
            if let lastLiveGroup = self.lastLiveGroup {
               cell.setGroup(group: lastLiveGroup)
            }
            cell.selectionStyle = .none
            return cell
         } else if sectionName == "FAVORITE" {
            let player = favoritePlayers[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "playedThroughCell") as! playedThroughCell
            cell.selectionStyle = .none
            cell.backgroundColor = .white
            cell.playerName.textColor = replayTextColor
            cell.setPlayer(player: player, isFavorited: true)
            if (indexPath.row == favoritePlayers.count - 1) {
               cell.underLineBottomConstraint.constant = 7
               cell.underLine.isHidden = false
            } else {
               cell.underLineBottomConstraint.constant = -1.5
               cell.underLine.isHidden = true
            }
            cell.layoutIfNeeded()
            return cell
         }
      }
      let group = playedThroughGroups[indexPath.row]
      let cell = tableView.dequeueReusableCell(withIdentifier: "replayPlayersTableViewCell") as!  replayPlayersTableViewCell
      cell.selectionStyle = .none
      cell.backgroundColor = .white
      cell.setPlayersDetails(group: group)
      return cell
   }
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if let sectionName = playerDrawerArrays[indexPath.section].keys.first {
         if sectionName == "FAVORITE" {
            if let cell = self.tableView.cellForRow(at: indexPath) as? playedThroughCell {
               let player = favoritePlayers[indexPath.row]
               // Turn off group replay in case if it was on.
               if let _ = experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup {
                  experienceWrapper.golf?.removeReplays()
                  experienceWrapper.golf?.screenView?.playerContainerView.resetSelectedGroup()
                  experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .stopped
                  self.tableView.reloadData()
               }
               if !ifFavoritedPlayerSelected(player: player) {
                  if self.ifReplayPlayerSelected(player: player) {
                     experienceWrapper.golf?.screenView?.playerContainerView.removeFromSelectedPlayers(player: player)
                     experienceWrapper.golf?.removeReplayForPlayer(player: player)
                     experienceWrapper.golf?.screenView?.playerContainerView.tableView.reloadData()
                  }
                  if isLive {
                     self.switchToReplayLabel()
                  }
                  experienceWrapper.golf?.switchToReplay()
                  experienceWrapper.golf?.addReplayForPlayer(player: player)
                  self.addToSelectedFavoritePlayers(player: player)
                  cell.setPlayer(player: player, isFavorited: true)
                  Q.log.instance.push(.ANALYTICS, msg: "onIndividualReplay", userInfo: ["playerName":player.nameLastCommaFirstInitial,"roundNumber":player.team?.round.num ?? -1,"holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
               } else {
                  experienceWrapper.golf?.removeReplayForPlayer(player: player)
                  self.removeFromFavoritedSelectedPlayers(player: player)
                  cell.setPlayer(player: player, isFavorited: true)
                  userInfo.instance.playerVisibilityModels = userInfo.instance.playerVisibilityModels.filter{!($0.player == (favoritePlayers[indexPath.row]))}
               }
            }
         }
      }
   }
   func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
      return CGFloat.leastNonzeroMagnitude
   }
   func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
      UITableView.automaticDimension
   }
   func scrollViewDidScroll(_ scrollView: UIScrollView) {
      var heightOfLiveSection: CGFloat = 154.0
      if self.tableView.numberOfSections > 0 {
         heightOfLiveSection = self.tableView.rect(forSection: 0).height //80.0 * CGFloat(tableView.numberOfRows(inSection: 0))
      }
      if scrollView.contentOffset.y == 0 {
         userScrolledToReplay = false
         for(_, item) in playerDrawerArrays.enumerated() {
            if item.keys.contains("LIVE_REPLAY") && lastLiveGroup != nil {
               if !isLive {
                  resetPlayerEntitiesVisibility()
                  experienceWrapper.golf?.switchToLive()
                  experienceWrapper.golf?.screenView?.reloadPlayerData()
                  //setLiveAndPlayedThroughPlayer()
                  self.switchToLive()
                  self.scrollToLive()
               }
            }
         }
      } else if (scrollView.contentOffset.y > heightOfLiveSection * 0.5) && !userScrolledToReplay {
         if isLive {
            experienceWrapper.golf?.switchToReplay()
            userScrolledToReplay = true
            self.switchToReplayLabel()
            self.scrollToReplay()
         }
      }
   }
   func resetPlayerEntitiesVisibility() {
      if let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
         for player in selectedPlayers {
            if let group = player.team,
               group.location(forHole: currentHole).inPlayOnHole == false {
               
               userInfo.instance.playerVisibilityModels = userInfo.instance.playerVisibilityModels.filter{$0.player != player}
            }
         }
      }
   }
   func resetPlayerArrayAfterHoleChange() {
      self.selectedPlayers = []
      self.selectedGroup = nil
      self.selectedFavoritedPlayers = []
      self.playedThroughGroups = []
      self.favoritePlayers = []
      self.playerDrawerArrays.removeAll()
   }
}

extension PlayerSelectionView: ReplayTableViewDelegate {
   func addtoFavoritePlayers(player: Q.golfPlayer) {
      self.favoritePlayers.insert(player, at: 0)

      self.setLiveAndPlayedThroughPlayer()
      
      for(index, item) in playerDrawerArrays.enumerated() {
         if item.keys.first == "FAVORITE" && tableView.numberOfRows(inSection: index) > 0 {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: index), at: .top, animated: true)
            break
         }
      }
   }
   func removeFromFavoritePlayers(player: Q.golfPlayer) {
      self.favoritePlayers = self.favoritePlayers.filter(){$0 != player}
      self.selectedFavoritedPlayers = self.selectedFavoritedPlayers.filter(){$0 != player}
      self.setLiveAndPlayedThroughPlayer()
   }
}

open class CustomLabel : UILabel {
   @IBInspectable open var characterSpacing: CGFloat = 1 {
      didSet {
         let attributedString = NSMutableAttributedString(string: self.text!)
         attributedString.addAttribute(NSAttributedString.Key.kern, value: self.characterSpacing, range: NSRange(location: 0, length: attributedString.length))
         self.attributedText = attributedString
      }
   }
}

extension UIScrollView {
   func scrollToTop() {
      let desiredOffset = CGPoint(x: 0, y: -contentInset.top)
      setContentOffset(desiredOffset, animated: true)
   }
}

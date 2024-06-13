import UIKit
import Q_ui
import Q

protocol ReplayTableViewDelegate {
   func addtoFavoritePlayers(player: Q.golfPlayer)
   func removeFromFavoritePlayers(player: Q.golfPlayer)
}
class ReplayTableUIView: UIView {
   
   @IBOutlet weak var headerContainer: UIView!
   @IBOutlet weak var tableViewContainer: UIView!
   //@IBOutlet weak var positionButton: UIButton!   
   
   var sortingType:SORTINGTYPE = .byPosition
   private var tableView:UITableView = {
      let tableView = UITableView()
      return tableView
   }()
   
   var playerInfos: [Q.golfPlayer] = []
   var playerInfoCopy: [Q.golfPlayer] = []
   var favoritePlayers: [Q.golfPlayer] = []
   var allFavoritedPlayers: [favoritedPlayer] = [] //For persistence of favorited players
   var replayTableViewDelegate: ReplayTableViewDelegate?
   
   override func awakeFromNib() {
      setUpHeader()
      tableViewSetUp()
      tableView.delegate = self
      tableView.dataSource = self
      
      tableView.register(UINib.fromSdkBundle("ReplayTableViewCell"       ), forCellReuseIdentifier: "ReplayTableViewCell")
      tableView.register(UINib.fromSdkBundle("ReplayTableViewHeaderCell" ), forCellReuseIdentifier: "ReplayTableViewHeaderCell")
      clearOldFavoritedPlayers()
   }
   func clearOldFavoritedPlayers(){
      if let data = UserDefaults.standard.data(forKey: "favoritedPlayer") {
         do {
            let decoder = JSONDecoder()
            allFavoritedPlayers = try decoder.decode([favoritedPlayer].self, from: data)
            allFavoritedPlayers = allFavoritedPlayers.filter { favoritedPlayer in
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd"
               let playerDate = dateFormatter.string(from: favoritedPlayer.timestamp ?? Date().addingTimeInterval(TimeInterval(-86400)))
               let currentDate = dateFormatter.string(from: Date())
               return currentDate == playerDate
            }
         } catch {
            Q.log.instance.push(.ERROR, msg: "Unable to Decode Stored favorite players")
         }
         do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allFavoritedPlayers)
            UserDefaults.standard.set(data, forKey: "favoritedPlayer")
         } catch {
            Q.log.instance.push(.ERROR, msg: "Unable to Encode Stored favorite players")
         }
      }

   }

   func setFavoritedPlayers() {
      guard favoritePlayers.isEmpty && !allFavoritedPlayers.isEmpty else {return}
      var players : [Q.golfPlayer] = []
      if let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
         if let activeRounds = experienceWrapper.golf?.sportData?.activeRounds {
            for round in activeRounds {
               let groups = round.orderedGroups(forHole: currentHole)
               let playedThroughGroups = groups.filter({ golfGroup in
                  golfGroup.location(forHole: currentHole) == .DONE
               })
               for eachGroup in  playedThroughGroups {
                  players.append(contentsOf: eachGroup.players)
               }
            }
         }
         for player in players {
            allFavoritedPlayers.forEach { favoritedPlayer in
               if currentHole.num == favoritedPlayer.holeId && player.team?.round.num == favoritedPlayer.roundId && player.pid == favoritedPlayer.playerId {
                  if replayTableViewDelegate != nil {
                     replayTableViewDelegate?.addtoFavoritePlayers(player: player)
                     self.favoritePlayers.append(player)
                  }
               }
            }
         }
         do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allFavoritedPlayers)
            UserDefaults.standard.set(data, forKey: "favoritedPlayer")
         } catch {
            Q.log.instance.push(.ERROR, msg: "Unable to Encode Stored favorite players")
         }
      }
   }
   func resetPlayerArraysAfterHoleChange() {
      self.playerInfos = []
      self.playerInfoCopy = []
      self.favoritePlayers = []
   }
   func setPlayers(players: [Q.golfPlayer]) {
      self.playerInfos = players
      self.playerInfoCopy = []
      
      if let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
         for player in players {
            if let group = player.team {
               let playerLocation = group.location(forHole: currentHole)
               if playerLocation == Q.golfGroup.GROUP_LOCATION.DONE {
                  self.playerInfoCopy.append(player)
               }
            }
         }
      }
      
      //Every time the data is updated the table will be sorted according the users earlier selection.
      switch sortingType {
         case .byPosition:
            self.sortByPosition()
         case .byName:
            self.sortByNames()
         case .byScore:
            self.sortByPoints()
      }
   }
   func setUpHeader() {
      if let viewNib = UINib.fromSdkBundle("ReplayTableViewHeader"),
         let view = viewNib.instantiate(withOwner: self, options: nil).first as? replayTableViewHeader {
         
         view.frame = self.headerContainer.bounds
         view.replayTableViewHeaderDelegate = self
         headerContainer.addSubview(view)
      }
   }
   func tableViewSetUp() {
      tableView = UITableView(frame: CGRect(x: 0, y: 0, width: self.tableViewContainer.bounds.width, height: self.tableViewContainer.bounds.height),style: .plain)
      tableView.showsVerticalScrollIndicator = false
      tableView.insetsContentViewsToSafeArea = false
      tableView.bounces = false
      tableView.backgroundColor = .clear
      tableView.separatorColor = UIColor(hexString: "#99B0C6")
      tableView.separatorInset.left = 0
      self.tableViewContainer.addSubview(tableView)
      setConstraint()
   }
   func setConstraint() {
      tableView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
         tableView.leftAnchor.constraint(equalTo: self.tableViewContainer.leftAnchor,constant: 0),
         tableView.rightAnchor.constraint(equalTo: self.tableViewContainer.rightAnchor,constant: 0),
         tableView.topAnchor.constraint(equalTo: self.tableViewContainer.topAnchor,constant: 0),
         tableView.bottomAnchor.constraint(equalTo: self.tableViewContainer.bottomAnchor,constant:0)
      ])
   }
}
extension ReplayTableUIView: UITableViewDelegate, UITableViewDataSource {
   func numberOfSections(in tableView: UITableView) -> Int {
      1
   }
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return playerInfoCopy.count //playerDetailsCopy.count
   }
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let player = playerInfoCopy[indexPath.row]
      let isFavorited = favoritePlayers.filter { player in
         player == playerInfoCopy[indexPath.row]
      }.count > 0
      
      if !isFavorited {
         replayTableViewDelegate?.addtoFavoritePlayers(player: player)
         self.favoritePlayers.append(playerInfoCopy[indexPath.row])
         Q.log.instance.push(.ANALYTICS, msg: "onPlayerFavorited", userInfo: ["playerName":player.nameLastCommaFirstInitial,"roundNumber":player.team?.round.num ?? -1,"holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
      } else {
         Q.log.instance.push(.ANALYTICS, msg: "onPlayerUnFavorited", userInfo: ["playerName":player.nameLastCommaFirstInitial,"roundNumber":player.team?.round.num ?? -1,"holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
         self.favoritePlayers = self.favoritePlayers.filter(){$0 != player}
         self.replayTableViewDelegate?.removeFromFavoritePlayers(player: player)
         experienceWrapper.golf?.removeReplayForPlayer(player: player)
      }
      tableView.reloadData()
      if let currentHole = experienceWrapper.golf?.cop?.featuredHoles.first(where: {$0.fop == experienceWrapper.golf?.fop} ) {
         if !isFavorited {
            allFavoritedPlayers.append(favoritedPlayer(holeId: currentHole.num, roundId: player.team?.round.num, playerId: player.pid, timestamp: Date()))
         } else {
            allFavoritedPlayers = allFavoritedPlayers.filter { favoritedPlayer in
               if (favoritedPlayer.playerId == player.pid) && (favoritedPlayer.roundId == player.team?.round.num) && (favoritedPlayer.holeId == currentHole.num){
                  return false
               } else {
                  return true
               }
            }
         }
         do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(allFavoritedPlayers)
            UserDefaults.standard.set(data, forKey: "favoritedPlayer")
         } catch {
            Q.log.instance.push(.ERROR, msg: "Unable to Encode Stored favorite players")
         }
      }
   }
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "ReplayTableViewCell", for: indexPath) as! replayTableViewCell
      let isFavorited = checkFavoritePlayers(player: playerInfoCopy[indexPath.row])
      cell.setDetails(player: playerInfoCopy[indexPath.row], isFavorited: isFavorited)
      return cell
   }
}
extension ReplayTableUIView: replayTableViewHeaderDelegate {
   
   func checkFavoritePlayers(player: Q.golfPlayer) -> Bool {
      for p in favoritePlayers {
         if p == player {
            return true
         }
      }
      return false
   }
   func sortByNames() {
      self.sortingType = .byName
      playerInfoCopy = playerInfoCopy.sorted{$0.sn < $1.sn }
      tableView.reloadData()
   }
   
   func sortByPoints() {
      self.sortingType = .byScore
      playerInfoCopy = playerInfoCopy.sorted{$0.score ?? Q_ui.defaults.score < $1.score ?? Q_ui.defaults.score}
      tableView.reloadData()
   }
   
   func sortByPosition() {
      self.sortingType = .byPosition
      playerInfoCopy = playerInfoCopy.sorted{$0.position ?? Q_ui.defaults.golfPlayerPosition < $1.position ?? Q_ui.defaults.golfPlayerPosition }
      tableView.reloadData()
   }
   
   func showFavoritePlayer(selection:Bool) {
      if selection {
         for p in 0..<playerInfoCopy.count {
            for fp in 0..<favoritePlayers.count {
               if playerInfoCopy[p] == favoritePlayers[fp] {
                  let temp = playerInfoCopy.remove(at: p)
                  playerInfoCopy.insert(temp, at: 0)
               }
            }
         }
         tableView.reloadData()
      } else {
         
      }
   }
}

enum SORTINGTYPE {
    case byPosition
    case byName
    case byScore
}

public struct favoritedPlayer : Codable{
   public var holeId : Int?
   public var roundId : Int?
   public var playerId : Int?
   public var timestamp : Date?
}

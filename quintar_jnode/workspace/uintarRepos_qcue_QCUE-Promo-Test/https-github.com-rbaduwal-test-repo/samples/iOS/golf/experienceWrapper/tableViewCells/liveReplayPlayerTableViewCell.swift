import UIKit
import Q
import Q_ui
class liveReplayPlayerTableViewCell: UITableViewCell {

    @IBOutlet weak var livePlayer1Label: UILabel!
    @IBOutlet weak var livePlayer2Label: UILabel!
    @IBOutlet weak var livePlayer3Label: UILabel!
    @IBOutlet weak var livePlayer4Label: UILabel!
    @IBOutlet weak var groupPlayButton: UIButton!
        
    var group: Q.golfGroup? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Q_ui.constants.groupReplayCompleted), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onGroupReplayCompleted(_:)), name: Notification.Name(Q_ui.constants.groupReplayCompleted), object: nil)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        
        livePlayer1Label.text = ""
        livePlayer2Label.text = ""
        livePlayer3Label.text = ""
        livePlayer4Label.text = ""
        
        livePlayer1Label.isHidden = false
        livePlayer2Label.isHidden = false
        livePlayer3Label.isHidden = false
        livePlayer4Label.isHidden = false
    }
    
   @IBAction func livePlayButton(_ sender: Any) {
      if experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .playing && experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == group?.tid {
         experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .paused
         self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedPlay"), for: .normal)
         experienceWrapper.golf?.pauseBallTrace()
      } else if experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .paused && experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == group?.tid {
         experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .playing
         self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedStop"), for: .normal)
         experienceWrapper.golf?.resumeBallTrace()
      } else {
         experienceWrapper.golf?.screenView?.playerContainerView.selectedPlayers.removeAll()
         experienceWrapper.golf?.screenView?.playerContainerView.selectedFavoritedPlayers.removeAll()
         experienceWrapper.golf?.screenView?.playerContainerView.resetSelectedGroup()
         experienceWrapper.golf?.switchToLive()
         experienceWrapper.golf?.screenView?.playerContainerView.deselectNonLivePlayers()
         experienceWrapper.golf?.screenView?.playerContainerView.scrollToLive()
         experienceWrapper.golf?.screenView?.playerContainerView.switchToLive()
         experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .playing
         userInfo.instance.playerVisibilityModels.removeAll()
         self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedStop"), for: .normal)
         if let group = self.group {
            experienceWrapper.golf?.screenView?.playerContainerView.setSelectedGroups(group: group)
            experienceWrapper.golf?.addReplayForGroup(group: group)
            Q.log.instance.push(.ANALYTICS, msg: "onGroupPlayFromReplayAvailable", userInfo: ["groupNumber":group.tid,"roundNumber":group.round.num,"holeNumber":experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
         }
      }
      experienceWrapper.golf?.screenView?.playerContainerView.tableView.reloadData()
   }
    
    @objc func onGroupReplayCompleted(_ notification: Notification) {
        DispatchQueue.main.async {
           if let playedGroup = notification.userInfo?["data"] as? Q.golfGroup, playedGroup.tid == self.group?.tid {
              experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .stopped
                self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedPlay"), for: .normal)
            }
        }
    }
    
    func setGroup(group: Q.golfGroup) {
        self.group = group
        self.setPlayerNames()
    }
    
    func setPlayerNames() {
        setPlayerName(index: 0, nameLabel: livePlayer1Label)
        setPlayerName(index: 1, nameLabel: livePlayer2Label)
        setPlayerName(index: 2, nameLabel: livePlayer3Label)
        setPlayerName(index: 3, nameLabel: livePlayer4Label)
        
       if(experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == self.group?.tid && experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .playing) {
            self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedStop"), for: .normal)
        } else {
            self.groupPlayButton.setImage(UIImage.fromSdkBundle(named: "reversedPlay"), for: .normal)
        }
    }
    
    func setPlayerName(index: Int, nameLabel: UILabel) {
        if let players = group?.players {
            if(index < players.count) {
               nameLabel.text = players[index].nameLastCommaFirstInitial
            } else {
                nameLabel.isHidden = true
            }
        } else {
            nameLabel.isHidden = true
        }
    }
}

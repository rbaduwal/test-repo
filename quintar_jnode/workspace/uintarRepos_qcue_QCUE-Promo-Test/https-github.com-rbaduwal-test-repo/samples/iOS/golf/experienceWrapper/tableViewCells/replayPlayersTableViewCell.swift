import UIKit
import Q
import Q_ui
import Kingfisher

class replayPlayersTableViewCell: UITableViewCell {
   @IBOutlet weak var player1Image: UIButton!
   @IBOutlet weak var player2Image: UIButton!
   @IBOutlet weak var player4Image: UIButton!
   @IBOutlet weak var player3Image: UIButton!
   @IBOutlet weak var player1NameLabel: UILabel!
   @IBOutlet weak var player2NameLabel: UILabel!
   @IBOutlet weak var player3NameLabel: UILabel!
   @IBOutlet weak var player4NameLabel: UILabel!
   @IBOutlet weak var groupNo: UIButton!
   @IBOutlet weak var groupNoPlayImage: UIImageView!
   @IBOutlet weak var player1ImageHeight: NSLayoutConstraint!
   @IBOutlet weak var player4ImageHeight: NSLayoutConstraint!
   @IBOutlet weak var player3ImageHeight: NSLayoutConstraint!
   @IBOutlet weak var player2ImageHeight: NSLayoutConstraint!
   @IBOutlet weak var player1labelHeight: NSLayoutConstraint!
   @IBOutlet weak var player2LabelHeight: NSLayoutConstraint!
   @IBOutlet weak var player3LabelHeight: NSLayoutConstraint!
   @IBOutlet weak var player4LabelHeight: NSLayoutConstraint!
   @IBOutlet weak var player1ImageToLabelDistance: NSLayoutConstraint!
   @IBOutlet weak var player2ImageToLabelDistance: NSLayoutConstraint!
   @IBOutlet weak var player3ImageToLabelDistance: NSLayoutConstraint!
   @IBOutlet weak var player4ImageToLabelDistance: NSLayoutConstraint!
   @IBOutlet weak var plyr1LblToPlyr2ImgDistance: NSLayoutConstraint!
   @IBOutlet weak var plyr2LblToPlyr3ImgDistance: NSLayoutConstraint!
   @IBOutlet weak var plyr3LblToPlyr4ImgDistance: NSLayoutConstraint!
   @IBOutlet weak var plyr4LblToPlayBtnDistance: NSLayoutConstraint!
   @IBOutlet weak var viewPlayerImageOne: UIView!
   @IBOutlet weak var viewPlayerImageTwo: UIView!
   @IBOutlet weak var viewPlayerImageThree: UIView!
   @IBOutlet weak var viewPlayerImageFour: UIView!
    
   @IBOutlet weak var imageOneTop: NSLayoutConstraint!
   @IBOutlet weak var imageTwoTop: NSLayoutConstraint!
   @IBOutlet weak var imageThreeTop: NSLayoutConstraint!
   @IBOutlet weak var imageFourTop: NSLayoutConstraint!
   var selectedImage1 = experienceView.defaultPlayerImg
   var selectedImage2 = experienceView.defaultPlayerImg
   var selectedImage3 = experienceView.defaultPlayerImg
   var selectedImage4 = experienceView.defaultPlayerImg
   var unSelectedImage1 = experienceView.defaultPlayerImg
   var unSelectedImage2 = experienceView.defaultPlayerImg
   var unSelectedImage3 = experienceView.defaultPlayerImg
   var unSelectedImage4 = experienceView.defaultPlayerImg
   var group: Q.golfGroup? = nil
   var players: [Q.golfPlayer] = []
   var image1Url: URL?
   var image2Url: URL?
   var image3Url: URL?
   var image4Url: URL?
   
   override func awakeFromNib() {
      super.awakeFromNib()
      setUiForPlayerButtons()
      NotificationCenter.default.removeObserver(self, name: Notification.Name(Q_ui.constants.groupReplayCompleted), object: nil)
      NotificationCenter.default.addObserver(self, selector: #selector(onGroupReplayCompleted(_:)), name: Notification.Name(Q_ui.constants.groupReplayCompleted), object: nil)
   }
   override func setSelected(_ selected: Bool, animated: Bool) {
      super.setSelected(selected, animated: animated)
   }
   override func prepareForReuse() {
      super.prepareForReuse()
      selectedImage1 = experienceView.defaultPlayerImg
      selectedImage2 = experienceView.defaultPlayerImg
      selectedImage3 = experienceView.defaultPlayerImg
      selectedImage4 = experienceView.defaultPlayerImg
      unSelectedImage1 = experienceView.defaultPlayerImg
      unSelectedImage2 = experienceView.defaultPlayerImg
      unSelectedImage3 = experienceView.defaultPlayerImg
      unSelectedImage4 = experienceView.defaultPlayerImg
      player1NameLabel.text = ""
      player2NameLabel.text = ""
      player3NameLabel.text = ""
      player4NameLabel.text = ""
      player4LabelHeight.constant = 16
      player4ImageHeight.constant = 63
      plyr3LblToPlyr4ImgDistance.constant = 12
      player4ImageToLabelDistance.constant = 7
      player3LabelHeight.constant = 16
      player3ImageHeight.constant = 63
      player1ImageToLabelDistance.constant = 10
      player2ImageToLabelDistance.constant = 10
      player3ImageToLabelDistance.constant = 7
      plyr2LblToPlyr3ImgDistance.constant = 12
      plyr1LblToPlyr2ImgDistance.constant = 12
      player2LabelHeight.constant = 16
      player2ImageHeight.constant = 63
      player2Image.isHidden = false
      player3Image.isHidden = false
      player4Image.isHidden = false
      viewPlayerImageTwo.isHidden = false
      viewPlayerImageThree.isHidden = false
      viewPlayerImageFour.isHidden = false

      self.player1Image.imageView?.kf.cancelDownloadTask()
      self.player2Image.imageView?.kf.cancelDownloadTask()
      self.player3Image.imageView?.kf.cancelDownloadTask()
      self.player4Image.imageView?.kf.cancelDownloadTask()
      viewPlayerImageOne.layer.borderColor = UIColor(hexString: "#808080").cgColor
      player1Image.setImage(experienceView.defaultPlayerImg, for: .normal)
      viewPlayerImageTwo.layer.borderColor = UIColor(hexString: "#808080").cgColor
      player2Image.setImage(experienceView.defaultPlayerImg, for: .normal)
      viewPlayerImageThree.layer.borderColor = UIColor(hexString: "#808080").cgColor
      player3Image.setImage(experienceView.defaultPlayerImg, for: .normal)
      viewPlayerImageFour.layer.borderColor = UIColor(hexString: "#808080").cgColor
      player4Image.setImage(experienceView.defaultPlayerImg, for: .normal)
      groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryPlay")
      imageOneTop.constant = 0
      imageTwoTop.constant = 0
      imageThreeTop.constant = 0
      imageFourTop.constant = 0
   }
   func cancelDownload() {
      if let image1Url = image1Url {
         KingfisherManager.shared.downloader.cancel(url: image1Url)
      }
      if let image2Url = image2Url {
         KingfisherManager.shared.downloader.cancel(url: image2Url)
      }
      if let image3Url = image3Url {
         KingfisherManager.shared.downloader.cancel(url: image3Url)
      }
      if let image4Url = image4Url {
         KingfisherManager.shared.downloader.cancel(url: image4Url)
      }
      self.image1Url = nil
      self.image2Url = nil
      self.image3Url = nil
      self.image4Url = nil
   }
   @objc func onGroupReplayCompleted(_ notification: Notification) {
      DispatchQueue.main.async {
         if let playedGroup = notification.userInfo?["data"] as? Q.golfGroup, playedGroup.tid == self.group?.tid {
            experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .stopped
            self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryPlay")
         }
      }
   }
   func setPlayersDetails(group:Q.golfGroup) {
      self.group = group
      self.players = group.players
      let playerCount = players.count
      if playerCount == 3 {
         player4LabelHeight.constant = 0
         player4ImageHeight.constant = 0
         plyr3LblToPlyr4ImgDistance.constant = 18
         player4ImageToLabelDistance.constant = 0
         player4Image.isHidden = true
         viewPlayerImageFour.isHidden = true
      } else if playerCount == 2 {
         player4LabelHeight.constant = 0
         player4ImageHeight.constant = 0
         plyr3LblToPlyr4ImgDistance.constant = 0
         player4ImageToLabelDistance.constant = 0
         player3LabelHeight.constant = 0
         player3ImageHeight.constant = 0
         player3ImageToLabelDistance.constant = 0
         plyr2LblToPlyr3ImgDistance.constant = 18
         player3Image.isHidden = true
         player4Image.isHidden = true
         viewPlayerImageThree.isHidden = true
         viewPlayerImageFour.isHidden = true
         plyr4LblToPlayBtnDistance.constant = 0
      } else {
         player4LabelHeight.constant = 0
         player4ImageHeight.constant = 0
         plyr3LblToPlyr4ImgDistance.constant = 0
         player4ImageToLabelDistance.constant = 0
         player3LabelHeight.constant = 0
         player3ImageHeight.constant = 0
         player3ImageToLabelDistance.constant = 0
         player2ImageToLabelDistance.constant = 0
         plyr2LblToPlyr3ImgDistance.constant = 0
         plyr1LblToPlyr2ImgDistance.constant = 18
         player2LabelHeight.constant = 0
         player2ImageHeight.constant = 0
         player2Image.isHidden = true
         player3Image.isHidden = true
         player4Image.isHidden = true
         viewPlayerImageTwo.isHidden = true
         viewPlayerImageThree.isHidden = true
         viewPlayerImageFour.isHidden = true
         plyr4LblToPlayBtnDistance.constant = 0
      }
      self.setPlayerDataBasedOnIndex(index: 0)
      self.setPlayerDataBasedOnIndex(index: 1)
      self.setPlayerDataBasedOnIndex(index: 2)
      self.setPlayerDataBasedOnIndex(index: 3)
      self.updateGroupButtonBasedOnSelection()
   }
   func setPlayerDataBasedOnIndex(index: Int) {
      if players.count > index {
         let player = players[index]
         switch index {
         case 0:
            player1NameLabel.text = player.nameLastCommaFirstInitial
         case 1:
            player2NameLabel.text = player.nameLastCommaFirstInitial
         case 2:
            player3NameLabel.text = player.nameLastCommaFirstInitial
         case 3:
            player4NameLabel.text = player.nameLastCommaFirstInitial
         default:
            break
         }
         setImageButton(playerIndex: index)
         self.setImageBasedOnSelection(index: index)
      }
   }
   func setUiForPlayerButtons() {
      setPlayerProfileBorderView(imageView: viewPlayerImageOne, color: UIColor(hexString: "#808080"))
      player1Image.imageView?.contentMode = .scaleAspectFill      
      setPlayerProfileBorderView(imageView: viewPlayerImageTwo, color: UIColor(hexString: "#808080"))
      player2Image.imageView?.contentMode = .scaleAspectFill      
      setPlayerProfileBorderView(imageView: viewPlayerImageThree, color: UIColor(hexString: "#808080"))
      player3Image.imageView?.contentMode = .scaleAspectFill      
      setPlayerProfileBorderView(imageView: viewPlayerImageFour, color: UIColor(hexString: "#808080"))
      player4Image.imageView?.contentMode = .scaleAspectFill      
   }
   func setImageBasedOnSelection(index: Int) {
      if players.count > index {
         let isSelected = ((experienceWrapper.golf?.screenView?.playerContainerView.selectedPlayers.contains(where: { selectedPlayer in
            selectedPlayer == players[index]
         }) ?? false) || (experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == self.group?.tid))
         switch index {
         case 0:
            updatePlayerButtonBasedOnSelection(selectedImage: selectedImage1, unSelectedImage: unSelectedImage1, playerButton: player1Image, index: index, isSelected: isSelected)
         case 1:
            updatePlayerButtonBasedOnSelection(selectedImage: selectedImage2, unSelectedImage: unSelectedImage2, playerButton: player2Image, index: index, isSelected: isSelected)
         case 2:
            updatePlayerButtonBasedOnSelection(selectedImage: selectedImage3, unSelectedImage: unSelectedImage3, playerButton: player3Image, index: index, isSelected: isSelected)
         case 3:
            updatePlayerButtonBasedOnSelection(selectedImage: selectedImage4, unSelectedImage: unSelectedImage4, playerButton: player4Image, index: index, isSelected: isSelected)
         default:
            break
         }
      }
      // Group replay button tapped.
      if index == 4
      {
         updateGroupButtonBasedOnSelection()
         let isSelected = experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == self.group?.tid
         updatePlayerButtonBasedOnSelection(selectedImage: selectedImage1, unSelectedImage: unSelectedImage1, playerButton: player1Image, index: 0, isSelected: isSelected)
         updatePlayerButtonBasedOnSelection(selectedImage: selectedImage2, unSelectedImage: unSelectedImage2, playerButton: player2Image, index: 1, isSelected: isSelected)
         updatePlayerButtonBasedOnSelection(selectedImage: selectedImage3, unSelectedImage: unSelectedImage3, playerButton: player3Image, index: 2, isSelected: isSelected)
         updatePlayerButtonBasedOnSelection(selectedImage: selectedImage4, unSelectedImage: unSelectedImage4, playerButton: player4Image, index: 3, isSelected: isSelected)
      }
   }
   func updatePlayerButtonBasedOnSelection(selectedImage: UIImage?, unSelectedImage: UIImage?, playerButton: UIButton, index: Int, isSelected: Bool) {
      if (index < players.count) {
         if isSelected {
            if index == 0 {
               viewPlayerImageOne.layer.borderColor = UIColor( hexString:self.players[index].colors.first?.hexString ?? "#FF0000").cgColor
            } else if index == 1 {
               viewPlayerImageTwo.layer.borderColor = UIColor( hexString:self.players[index].colors.first?.hexString ?? "#FF0000").cgColor
            } else if index == 2 {
               viewPlayerImageThree.layer.borderColor = UIColor( hexString:self.players[index].colors.first?.hexString ?? "#FF0000").cgColor
            } else if index == 3 {
               viewPlayerImageFour.layer.borderColor = UIColor( hexString:self.players[index].colors.first?.hexString ?? "#FF0000").cgColor
            }
            playerButton.setImage(selectedImage, for: .normal)
         } else {
            if index == 0 {
               viewPlayerImageOne.layer.borderColor = UIColor(hexString: "#808080").cgColor
            } else if index == 1 {
               viewPlayerImageTwo.layer.borderColor = UIColor(hexString: "#808080").cgColor
            } else if index == 2 {
               viewPlayerImageThree.layer.borderColor = UIColor(hexString: "#808080").cgColor
            } else if index == 3 {
               viewPlayerImageFour.layer.borderColor = UIColor(hexString: "#808080").cgColor
            }
            playerButton.setImage(unSelectedImage, for: .normal)
         }
      }
   }
   func setPlayerProfileBorderView(imageView: UIView, color:UIColor? = .clear) {
      imageView.layer.borderWidth = 2.0
      imageView.layer.masksToBounds = false
      imageView.layer.borderColor = color?.cgColor
      imageView.layer.cornerRadius = imageView.frame.size.width/2
      imageView.clipsToBounds = true
   }
   func updateGroupButtonBasedOnSelection() {
      let isSelected = experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == self.group?.tid
      if experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .playing && isSelected
      {
         self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryStop")
      } else {
         self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryPlay")
      }
   }
   func setImageButton(playerIndex: Int) {
      DispatchQueue.main.async {
         self.setSelectedAndUnSelectedImage(index: playerIndex, image: experienceView.defaultPlayerImg, isSelectedImage: true)
         self.setSelectedAndUnSelectedImage(index: playerIndex, image: experienceView.defaultPlayerImg, isSelectedImage: false)
      }
      if let imageUrl = URL(string: players[playerIndex].hsUrl) {
         if playerIndex == 0 {
            self.image1Url = imageUrl
         } else if playerIndex == 1 {
            self.image2Url = imageUrl
         } else if playerIndex == 2 {
            self.image3Url = imageUrl
         } else {
            self.image4Url = imageUrl
         }
         
         let resource = ImageResource(downloadURL: imageUrl)
         KingfisherManager.shared.retrieveImage(with: resource, options:nil, progressBlock: nil) { kfResult in
            switch kfResult {
            case .success(let value):
               self.setSelectedAndUnSelectedImage(index: playerIndex, image: value.image, isSelectedImage: true)
               let selectedImage: UIImage? = value.image
               if let image = selectedImage {
                  self.setSelectedAndUnSelectedImage(index: playerIndex, image: self.grayscaleImage(image: image) ?? experienceView.defaultPlayerImg, isSelectedImage: false)
                  self.setbgcolorforimage(index: playerIndex, status: true)
                  self.setImageBasedOnSelection(index: playerIndex)
               }
            case .failure(let error):
               DispatchQueue.main.async {
                  self.setbgcolorforimage(index: playerIndex, status: false)
                  self.setImageBasedOnSelection(index: playerIndex)
               }
               print("Error: \(error)")
            }
         }
      } else {
         DispatchQueue.main.async {
            self.setbgcolorforimage(index: playerIndex, status: false)
            self.setImageBasedOnSelection(index: playerIndex)
         }
      }
   }
   func setbgcolorforimage(index: Int, status: Bool) {
      switch index {
      case 0:
         if status {
            imageOneTop.constant = 5
         } else {
            imageOneTop.constant = 0
         }
      case 1:
         if status {
            imageTwoTop.constant = 5
         } else {
            imageTwoTop.constant = 0
         }
      case 2:
         if status {
            imageThreeTop.constant = 5
         } else {
            imageThreeTop.constant = 0
         }
      case 3:
         if status {
            imageFourTop.constant = 5
         } else {
            imageFourTop.constant = 0
         }
      default:
         break
      }
   }
   func setSelectedAndUnSelectedImage(index: Int, image: UIImage?, isSelectedImage: Bool) {
      switch index {
      case 0:
         if isSelectedImage {
            self.selectedImage1 = image
         } else {
            self.unSelectedImage1 = image
         }
      case 1:
         if isSelectedImage {
            self.selectedImage2 = image
         } else {
            self.unSelectedImage2 = image
         }
      case 2:
         if isSelectedImage {
            self.selectedImage3 = image
         } else {
            self.unSelectedImage3 = image
         }
      case 3:
         if isSelectedImage {
            self.selectedImage4 = image
         } else {
            self.unSelectedImage4 = image
         }
      default:
         break
      }
   }
   func grayscaleImage(image: UIImage) -> UIImage? {
      let ciImage = CIImage(image: image)
      if let grayscale = ciImage?.applyingFilter("CIColorControls",parameters: [ kCIInputSaturationKey: 0.0 ]) {
         return UIImage(ciImage: grayscale)
      }
      return nil
   }
   fileprivate func onPlayerButtonAction(index: Int) {
      self.dismissDropdown()
      // Group selection
      if index == 4 {
         if let group = self.group {
            if experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .playing && experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == group.tid {
               experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .paused
               self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryPlay")
               experienceWrapper.golf?.pauseBallTrace()
            } else if experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating == .paused && experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup?.tid == group.tid {
               experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .playing
               self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryStop")
               experienceWrapper.golf?.resumeBallTrace()
            } else {
               experienceWrapper.golf?.screenView?.playerContainerView.selectedPlayers.removeAll()
               experienceWrapper.golf?.screenView?.playerContainerView.selectedFavoritedPlayers.removeAll()
               experienceWrapper.golf?.screenView?.playerContainerView.resetSelectedGroup()
               experienceWrapper.golf?.switchToReplay()
               userInfo.instance.playerVisibilityModels.removeAll()
               experienceWrapper.golf?.screenView?.playerContainerView.switchToReplayLabel()
               experienceWrapper.golf?.screenView?.playerContainerView.setSelectedGroups(group: group)
               experienceWrapper.golf?.screenView?.playerContainerView.deselectNonLivePlayers()
               experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .playing
               userInfo.instance.playerVisibilityModels.forEach({ $0.isShotTrailVisible = true })
               userInfo.instance.playerVisibilityModels.forEach({ $0.isPlayerFlagVisible = true })
               userInfo.instance.playerVisibilityModels.forEach({ $0.isApexVisible = true })
               self.groupNoPlayImage.image = UIImage.fromSdkBundle(named: "primaryStop")
               experienceWrapper.golf?.addReplayForGroup(group: group)
               self.setImageBasedOnSelection(index: index)
               Q.log.instance.push(.ANALYTICS, msg: "onGroupPlayFromReplay", userInfo: ["groupNumber": group.tid, "roundNumber": group.round.num, "holeNumber": experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
            }
         }
      } else {
         // Turn off group replay in case if it was on.
         if let _ = experienceWrapper.golf?.screenView?.playerContainerView.selectedGroup {
            experienceWrapper.golf?.removeReplays()
            experienceWrapper.golf?.screenView?.playerContainerView.resetSelectedGroup()
            experienceWrapper.golf?.screenView?.playerContainerView.switchToReplayLabel()
            experienceWrapper.golf?.switchToReplay()
            if experienceWrapper.golf?.screenView?.playerContainerView.isLive ?? false {
               experienceWrapper.golf?.screenView?.playerContainerView.scrollToReplay()
            }
            experienceWrapper.golf?.screenView?.playerContainerView.isGroupPlayAnimating = .stopped
            self.groupNoPlayImage.image = UIImage.fromSdkBundle(named:"primaryPlay")
         }
         //To reset playerAREntitiesVisibility
         let player = players[index]
         if let selectedPlayer = userInfo.instance.playerVisibilityModels.filter({ return $0.player == player }).first {
            selectedPlayer.isApexVisible = true
            selectedPlayer.isShotTrailVisible = true
            selectedPlayer.isPlayerFlagVisible = true
         }
         //Player selection.
         if experienceWrapper.golf?.screenView?.playerContainerView.isLive ?? false {
            experienceWrapper.golf?.switchToReplay()
            experienceWrapper.golf?.screenView?.playerContainerView.switchToReplayLabel()
            experienceWrapper.golf?.screenView?.playerContainerView.scrollToReplay()
         }
         if experienceWrapper.golf?.screenView?.playerContainerView.ifFavoritedPlayerSelected(player: player) ?? false {
            experienceWrapper.golf?.screenView?.playerContainerView.removeFromFavoritedSelectedPlayers(player: player)
            experienceWrapper.golf?.removeReplayForPlayer(player: player)
         }
         
         if let isSelected = experienceWrapper.golf?.screenView?.playerContainerView.selectedPlayers.contains(where: { selectedPlayer in
            selectedPlayer == player
         }) {
            if isSelected {
               experienceWrapper.golf?.removeReplayForPlayer(player: player)
               experienceWrapper.golf?.screenView?.playerContainerView.removeFromSelectedPlayers(player: player)
            } else {
               Q.log.instance.push(.ANALYTICS, msg: "onIndividualReplay", userInfo: ["playerName": player.nameLastCommaFirstInitial, "roundNumber": player.team?.round.num ?? -1, "holeNumber": experienceWrapper.golf?.screenView?.selectedHoleNum ?? -1])
               experienceWrapper.golf?.addReplayForPlayer(player: player)
               experienceWrapper.golf?.screenView?.playerContainerView.addToSelectedPlayers(player: player)
            }
         } else {
            experienceWrapper.golf?.addReplayForPlayer(player: player)
            experienceWrapper.golf?.screenView?.playerContainerView.addToSelectedPlayers(player: player)
         }
         self.setImageBasedOnSelection(index: index)
         experienceWrapper.golf?.screenView?.playerContainerView.tableView.reloadData()
      }
   }
   
   @IBAction func player1Tapped(_ sender: UIButton) {
      self.onPlayerButtonAction(index: 0)
   }
   @IBAction func player2Tapped(_ sender: UIButton) {
      self.onPlayerButtonAction(index: 1)
   }
   @IBAction func player3Tapped(_ sender: UIButton) {
      self.onPlayerButtonAction(index: 2)
   }
   @IBAction func player4Tapped(_ sender: UIButton) {
      self.onPlayerButtonAction(index: 3)
   }
   @IBAction func groupReplayTapped(_ sender: UIButton) {
      self.onPlayerButtonAction(index: 4)
   }
   func dismissDropdown() {
      if let roundAndSelectionView = experienceWrapper.golf?.screenView?.roundAndSelectionView {
         roundAndSelectionView.dismissDropdown()
      }
   }
}

fileprivate extension UIButton {
   func setPlayerbutton() {
      self.layer.cornerRadius = self.frame.height * 0.50
      self.backgroundColor = .clear
      self.layer.borderWidth = 2
      self.layer.borderColor = UIColor(hexString: "#808080").cgColor
      self.clipsToBounds = true
      self.imageView?.contentMode = .scaleAspectFill
   }
}

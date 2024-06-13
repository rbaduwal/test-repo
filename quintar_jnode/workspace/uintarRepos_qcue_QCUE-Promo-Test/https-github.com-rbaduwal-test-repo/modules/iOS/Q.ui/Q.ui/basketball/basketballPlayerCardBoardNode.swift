import UIKit
import Q

class basketballPlayerCardBoardNode: basketballCourtsideBoard {
   
   // How this view looks
   public var viewSettings: viewSettings
   struct viewSettings {
      var backgroundColor: String = defaults.highlightColor
      var nameSize: Float = defaults.largeFontSize
      var nameColor: String = defaults.highlightColor
      var nameFontFamily: String = defaults.playerCardNameFontFamily
      var shotTypeSize: Float = defaults.mediumFontSize
      var shotTypeColor: String  = defaults.titleColor
      var shotTypeFontFamily: String = defaults.playerCardShotTypeFontFamily
      var scrSize: Float  = defaults.largeFontSize
      var scrFontFamily: String = defaults.leaderBoardNameFontFamily
      var attemptColor: String  = defaults.attemptColor
      var attemptOpacity: Float = defaults.attemptOpacity
      var successColor: String = defaults.successColor
      var highlightColor: String = defaults.highlightColor
      var titleColor: String = defaults.titleColor
      var backgroundOpacity: Float = defaults.cardBackgroundOpacity
      var boardHeight: Float = defaults.leaderBoardHeight
      var shotTypeBackgroundColor : String  = defaults.shotTypeBackgroundColor
      var borderWidth: Float = defaults.leaderBoardBorderWidth
      var playerHsWidth: Float = defaults.playerCardHsWidth
   }
   
   // Data binding
   public var viewModel: basketballViewModel
   
   // Return a default title if we don't have a selected team
   public var playerName: String? {
      if let player = self.viewModel.selectedPlayers.first( where: { player in
         player.team?.tid == viewModel.selectedTeam?.tid
      }) {
         return player.sn.uppercased()
      } else {
         return nil
      }
   }

   // Persistent planes (nodes)
   private var usablePlane = qModelEntity()
   private var teamLogoImagePlane = qModelEntity()
   private var playerNameText = qModelEntity()
   private var playerPlane = qModelEntity()
   private var playerTransparencyPlane = qModelEntity()
   private var playerImagePlane = qModelEntity()

   private let padding: Float = defaults.leaderBoardBorderPadding
   private var playerNameBounds = qBoundingBox()
   private var playerImageView = teamPlayerImage(frame: .init(x: 0, y: 0, width: defaults.playerCardHsPixels, height: defaults.playerCardHsPixels))
   private var teamImageView = teamPlayerImage(frame: .init(x: 0, y: 0, width: defaults.leaderBoardHsPixels, height: defaults.leaderBoardHsPixels))
   private var downloader: Q.httpDownloader = Q.httpDownloader()
   weak private var arView: qARView? = nil
   private var shotTypeFont: UIFont = UIFont()
   private var scrFont: UIFont = UIFont()
   private var nameFont: UIFont = UIFont()

   required override init() {
      fatalError("init() has not been implemented")
   }
   
   required init(model: basketballViewModel, viewSettings: viewSettings, arView: qARView) {
      self.viewModel = model
      self.viewSettings = viewSettings
      self.arView = arView
      
      super.init()
      
      createModel()
   }
   
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   public func update(vs: viewSettings) {

      guard let selectedPlayers = self.viewModel.selectedPlayers.first( where: { player in
         player.team?.tid == self.viewModel.selectedTeam?.tid
      }) else { return }
      guard let playerName = self.playerName else { return }
      
      // Handle data updates
      selectedPlayers.playerUpdated = { player in
         // Check when the selected player changes
         if selectedPlayers == player {
            DispatchQueue.main.async {
               self.update(vs: vs)
            }
         }
      }
      
      // Check when the selected shot type changes
      let shotText = "SHOTS"
      var selectedShotTypeName = "3PT " + shotText
      switch viewModel.selectedShotType {
         case .FIELD_GOAL: selectedShotTypeName = "2PT " + shotText
         case .THREE_PTR: selectedShotTypeName = "3PT " + shotText
         default: selectedShotTypeName = "TOTAL " + shotText
      }
      
      var startX: Float = 0.0
      var startY: Float = 0.0
      
      // Border
      self.update( materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.highlightColor))])
      
      // Team logo
      guard let imageURL = self.viewModel.selectedTeam?.logoUrl else {return}
      UIImage.fromUrl(url: imageURL, downloader: downloader, completion:{ image in
         if let i = image {
            self.teamImageView.setData(image: i, borderColor: .clear, borderWidth: 0.0, isTeamLogo: true)
            let convertedCGImage = self.teamImageView.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerImageMaterial = qUnlitMaterial()
               playerImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.teamLogoImagePlane.update(materials: [playerImageMaterial])
            }
         }
      })
      
      // Player Name
      let mesh = qMeshResource.generateText(playerName, extrusionDepth: 0, font: self.nameFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail)
      self.playerNameBounds = mesh.bounds
      self.playerNameText.update(
         mesh: mesh,
         materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.nameColor))] )
      
      // Create or update the player image
      var reusedIndex: Int = 0;
      if playerPlane.children.count > reusedIndex, let me = playerPlane.children[reusedIndex] as? qModelEntity {
         playerImagePlane = me
      } else {
         playerImagePlane = qModelEntity()
         playerPlane.addChild(playerImagePlane)
      }
      let playerImageUrl: String
      let playerImageWidth = min(vs.playerHsWidth, self.playerPlane.model!.mesh.bounds.extents.y) // Ensure the logo fits in the space we have
      playerImageUrl = selectedPlayers.hsUrl
      UIImage.fromUrl(url: playerImageUrl, downloader: downloader, completion:{ image in
         if let i = image {
            
            self.playerImageView.setData(image: i, borderColor: UIColor.init(hexString: vs.highlightColor), borderWidth: 3, isTeamLogo: false)
            let convertedCGImage = self.playerImageView.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerImageMaterial = qUnlitMaterial()
               
               // This loads the texture onto the image plane
               playerImageMaterial.color = .init(texture: .init(imageTextureResource))
               
               // This ensures the transparent pixels in the texture stay transparent
               playerImageMaterial.blending = .transparent(opacity: 1.0)
               playerImageMaterial.opacityThreshold = constants.minTransparencyThreshold
               self.playerImagePlane.update(
                  mesh: .generateBox(width: playerImageWidth, height: playerImageWidth, depth: 0),
                  materials: [playerImageMaterial])
               self.playerImagePlane.isEnabled = true
            }
         }
      })

      //Setting default player image
      self.playerImageView.setData(image: UIImage(named: "defaultPlayer", in: Bundle(identifier:constants.qUIBundleID), compatibleWith: nil)!, borderColor: UIColor.init(hexString: vs.highlightColor), borderWidth: 3, isTeamLogo: false)
      let convertedCGImage = self.playerImageView.asImage().cgImage
      if let convertedCGImage = convertedCGImage {
         let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
         var playerImageMaterial = qUnlitMaterial()
         
         // This loads the texture onto the image plane
         playerImageMaterial.color = .init(texture: .init(imageTextureResource))
         
         // This ensures the transparent pixels in the texture stay transparent
         playerImageMaterial.blending = .transparent(opacity: 1.0)
         playerImageMaterial.opacityThreshold = constants.minTransparencyThreshold
         self.playerImagePlane.update(
            mesh: .generateBox(width: playerImageWidth, height: playerImageWidth, depth: 0),
            materials: [playerImageMaterial])
         self.playerImagePlane.isEnabled = true
      }
      
      // Create a container for the shot text, allowing us to properly center everything to the headshot
      reusedIndex += 1;
      let shotTextArea: qEntity
      var shotTextAreaCenterY: Float = 0
      var shotTextAreaWidth: Float = 0
      if playerPlane.children.count > reusedIndex, let me = playerPlane.children[reusedIndex] as? qModelEntity {
         shotTextArea = me
      } else {
         shotTextArea = qModelEntity()
         playerPlane.addChild(shotTextArea)
      }
      
      // Enter an anonymous scope for the shot text internals
      do {
         // Create or update the shot type
         var reusedIndex: Int = 0
         let shotTypePlane: qModelEntity
         let shotTypePlaneMaterials: [qMaterial]?
         if shotTextArea.children.count > reusedIndex, let me = shotTextArea.children[reusedIndex] as? qModelEntity {
            shotTypePlane = me
            shotTypePlaneMaterials = nil
         } else {
            shotTypePlane = qModelEntity()
            shotTypePlaneMaterials = [qUnlitMaterial(color: UIColor.init(hexString: vs.shotTypeColor))]
            shotTextArea.addChild(shotTypePlane)
         }
         shotTypePlane.update(
            mesh: .generateText(selectedShotTypeName, extrusionDepth: 0, font: self.shotTypeFont, containerFrame: .zero, alignment: .center),
            materials: shotTypePlaneMaterials)
         
         // Create or update the separator
         reusedIndex += 1;
         let seperatorPlane: qModelEntity
         let separatorFont = UIFont.systemFont(ofSize: CGFloat(vs.scrSize))
         let seperatorPlaneMaterials: [qMaterial]?
         if shotTextArea.children.count > reusedIndex, let me = shotTextArea.children[reusedIndex] as? qModelEntity {
            seperatorPlane = me
            seperatorPlaneMaterials = nil
         } else {
            seperatorPlane = qModelEntity()
            seperatorPlaneMaterials = [qUnlitMaterial(color: UIColor.init(hexString: vs.attemptColor, alpha: CGFloat(vs.attemptOpacity)))]
            shotTextArea.addChild(seperatorPlane)
         }
         seperatorPlane.update(
            mesh: .generateText("/", extrusionDepth: 0, font: separatorFont, containerFrame: .zero, alignment: .center),
            materials: seperatorPlaneMaterials)

         // Create or update the success shots
         reusedIndex += 1;
         var successValue: String
         var shotsAttempted: String
         if viewModel.selectedShotType == .TOTAL {
            successValue = "\(selectedPlayers.shots(areMade: true).count)"
            shotsAttempted = "\(selectedPlayers.shots.count)"
         } else {
            successValue = "\(selectedPlayers.shots(areMade: true, ofType: viewModel.selectedShotType).count)"
            shotsAttempted = "\(selectedPlayers.shots(ofType: viewModel.selectedShotType).count)"
         }
         let successShotPlane: qModelEntity
         let successShotPlaneMaterials: [qMaterial]?
         if shotTextArea.children.count > reusedIndex, let me = shotTextArea.children[reusedIndex] as? qModelEntity {
            successShotPlane = me
            successShotPlaneMaterials = nil
         } else {
            successShotPlane = qModelEntity()
            successShotPlaneMaterials = [qUnlitMaterial(color: UIColor.init(hexString: vs.successColor))]
            shotTextArea.addChild(successShotPlane)
         }
         successShotPlane.update(
            mesh: .generateText(successValue.uppercased(), extrusionDepth: 0, font: scrFont, containerFrame: .zero, alignment: .center),
            materials: successShotPlaneMaterials)
         
         // Create or update the attempted shots
         reusedIndex += 1;
         let attemptedShotsPlane: qModelEntity
         let attemptedShotsPlaneMaterials: [qMaterial]?
         if shotTextArea.children.count > reusedIndex, let me = shotTextArea.children[reusedIndex] as? qModelEntity {
            attemptedShotsPlane = me
            attemptedShotsPlaneMaterials = nil
         } else {
            attemptedShotsPlane = qModelEntity()
            attemptedShotsPlaneMaterials = [qUnlitMaterial(color: UIColor.init(hexString: vs.attemptColor, alpha: CGFloat(vs.attemptOpacity)))]
            shotTextArea.addChild(attemptedShotsPlane)
         }
         attemptedShotsPlane.update(
            mesh: .generateText(shotsAttempted.uppercased(), extrusionDepth: 0, font: scrFont, containerFrame: .zero, alignment: .center),
            materials: attemptedShotsPlaneMaterials)
            
         // Calculate some bounds of this shot text area. I have found visualBounds() to be unreliable so I refuse to use it
         let totalHeight = shotTypePlane.model!.mesh.bounds.extents.y + seperatorPlane.model!.mesh.bounds.extents.y
         shotTextAreaCenterY = -(totalHeight - shotTypePlane.model!.mesh.bounds.extents.y) / 2
         shotTextAreaWidth = shotTypePlane.model!.mesh.bounds.extents.x + self.padding * 2
         
         // Position all the elements inside the shot text area
         startX = 0
         startY = 0//-shotTypePlane.getTextCenterYAdjustment(withFont: self.shotTypeFont) / 2
         shotTypePlane.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: shotTypePlane.parent, withFont: self.shotTypeFont )
         startY = -(shotTypePlane.model!.mesh.bounds.extents.y + attemptedShotsPlane.model!.mesh.bounds.extents.y) / 2 - self.padding
         seperatorPlane.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: seperatorPlane.parent, withFont: separatorFont )
         startX = -(seperatorPlane.model!.mesh.bounds.extents.x + successShotPlane.model!.mesh.bounds.extents.x) / 2 - self.padding
         successShotPlane.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: successShotPlane.parent, withFont: scrFont )
         startX = (seperatorPlane.model!.mesh.bounds.extents.x + attemptedShotsPlane.model!.mesh.bounds.extents.x) / 2 + self.padding
         attemptedShotsPlane.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: attemptedShotsPlane.parent, withFont: scrFont )
      }

      // Calculate some stuff
      let totalWidth = (self.viewSettings.borderWidth * 2) + max(
          self.teamLogoImagePlane.model!.mesh.bounds.extents.x + self.padding + self.playerNameBounds.extents.x + self.padding,
          playerImageWidth + self.padding * 2 + shotTextAreaWidth + self.padding)
      let usableWidth: Float = totalWidth - (self.viewSettings.borderWidth * 2)
      let usableHeight: Float = self.viewSettings.boardHeight - (self.viewSettings.borderWidth * 2)
      
      // Resize our background and border to ensure the name fits
      do {
         self.update( mesh: .generateBox(width: totalWidth, height: self.viewSettings.boardHeight, depth: 0) )
         self.usablePlane.update( mesh: .generateBox(width: usableWidth, height: usableHeight, depth: 0) )
         let mesh: qMeshResource = .generateBox(width: usableWidth, height: self.playerPlane.model!.mesh.bounds.extents.y, depth: 0)
         self.playerTransparencyPlane.update( mesh: mesh )
         self.playerPlane.update( mesh: mesh )
      }
         
      // Position the title area
      startX = -(usableWidth - self.teamLogoImagePlane.model!.mesh.bounds.extents.x) / 2 + self.padding
      startY = (usableHeight - self.teamLogoImagePlane.model!.mesh.bounds.extents.y) / 2 - self.padding
      self.teamLogoImagePlane.setPosition( qVector3(startX, startY, constants.zFightBreakup), relativeTo: self.teamLogoImagePlane.parent)
      startX += self.teamLogoImagePlane.model!.mesh.bounds.extents.x / 2
      startY = (usableHeight - self.teamLogoImagePlane.model!.mesh.bounds.extents.y) / 2
      self.playerNameText.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: playerNameText.parent, withFont: self.nameFont, align: .left)
      
      // Position the info area
      startX = -(totalWidth - playerImageWidth) / 2 + vs.borderWidth + (self.padding * 2)
      startY = 0
      self.playerImagePlane.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: self.playerImagePlane.parent)
      let rhsWidth = (totalWidth - (vs.borderWidth * 2) - playerImageWidth - self.padding )
      startX = (totalWidth - rhsWidth) / 2
      startY = -shotTextAreaCenterY
      shotTextArea.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: shotTextArea.parent)
      
      // AFTER we have checked for changes, update our view settings
      self.viewSettings = vs
      
      // TODO: I do not like this, there must be a better way
      self.forceName(defaults.forceNamePlayercard, recursive: true)
   }
   
   private func createModel() {
      // This should only be called once by the constructor, use update() for data and visual changes.
      
      var width: Float = 0
      var height: Float = 0
      var startX: Float = 0
      var startY: Float = 0
      let titleAreaLogo2TextRatio: Float = 1.8
      
      // Create the fonts we will use
      let titleNameFontSize = CGFloat(self.viewSettings.nameSize)
      self.nameFont = UIFont(name: self.viewSettings.nameFontFamily, size: titleNameFontSize) ?? .init(descriptor: .init(name: defaults.playerCardNameFontFamily, size: 0), size: titleNameFontSize)
      let shotTypeFontSize = CGFloat(self.viewSettings.shotTypeSize)
      self.shotTypeFont = UIFont(name: self.viewSettings.shotTypeFontFamily, size: shotTypeFontSize) ?? .init(descriptor: .init(name: defaults.playerCardShotTypeFontFamily, size: 0), size: shotTypeFontSize)
      let scoreFontSize = CGFloat(self.viewSettings.scrSize)
      self.scrFont = UIFont(name: self.viewSettings.scrFontFamily, size: scoreFontSize) ?? .init(descriptor: .init(name: defaults.leaderBoardScrFontFamily, size: 0), size: scoreFontSize)
      
      // Determine the total dimensions, including padding and borders.
      // Create a default player name - this will define the absolute width, so choose a value of an appropriate number of characters.
      // Players whose names are wider than this default will be truncated with elipses in update().
      let fakeName = "SOMENAME"
      let defaultText = qMeshResource.generateText(fakeName, extrusionDepth: 0, font: self.nameFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
      self.playerNameBounds = defaultText.bounds
      let totalHeight: Float = self.viewSettings.boardHeight
      let usableHeight: Float = totalHeight - (self.viewSettings.borderWidth * 2)
      let titleStripHeight = defaultText.bounds.extents.y * titleAreaLogo2TextRatio
      let totalWidth: Float = (self.viewSettings.borderWidth * 2) + titleStripHeight + self.padding + self.playerNameBounds.extents.x + self.padding
      let usableWidth: Float = totalWidth - (self.viewSettings.borderWidth * 2)
      let infoStripHeight = usableHeight - titleStripHeight
      
      // Create our board and border
      self.update(
         mesh: .generateBox(width: totalWidth, height: self.viewSettings.boardHeight, depth: 0),
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.highlightColor))])
      self.usablePlane = qModelEntity(
         mesh: .generateBox(width: usableWidth, height: usableHeight, depth: 0),
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.titleColor))])
      self.addChild(self.usablePlane)
      self.usablePlane.setPosition(qVector3(0, 0, constants.zFightBreakup), relativeTo: self.usablePlane.parent)
      
      // Create the space for the team logo. Pad-in on all sides
      height = titleStripHeight - self.padding * 2
      width = titleStripHeight - self.padding * 2
      self.teamLogoImagePlane = qModelEntity(
         mesh: .generateBox(width: width, height: height, depth: 0),
         materials: [qSimpleMaterial()])
      self.usablePlane.addChild(teamLogoImagePlane)
      startX = -(usableWidth - titleStripHeight) / 2
      startY = (usableHeight - titleStripHeight) / 2
      self.teamLogoImagePlane.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: self.teamLogoImagePlane.parent)
      
      // Create our player name text, with pad-out on the left/right sides
      // IMPORTANT: If using a containerFrame, it must match EXACTLY with the value used in update(), or text won't show up. This is probably a bug in RealityKit.
      height = self.playerNameBounds.extents.y
      width = self.playerNameBounds.extents.x
      self.playerNameText = qModelEntity(
         mesh: .generateText(defaults.playerName, extrusionDepth: 0, font: self.nameFont, containerFrame: .zero, alignment: .left, lineBreakMode: .byTruncatingTail),
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.nameColor))])
      startX = -(usableWidth - width) / 2 + titleStripHeight + (self.padding * 2)
      self.usablePlane.addChild(playerNameText)
      playerNameText.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: playerNameText.parent, withFont: self.nameFont, align: .left)
      
      // Create the field behind the player's info. This requires an extra "occlusion" plane so we can have transparency
      let mesh: qMeshResource = .generateBox(width: usableWidth, height: infoStripHeight, depth: 0)
      self.playerTransparencyPlane = qModelEntity(
         mesh: mesh,
         materials: [qOcclusionMaterial()])
      self.usablePlane.addChild(playerTransparencyPlane)
      self.playerPlane = qModelEntity(
         mesh: mesh,
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.backgroundColor, alpha: CGFloat(self.viewSettings.backgroundOpacity)))])
      self.playerPlane.setPosition(qVector3(0, 0, constants.zFightBreakup), relativeTo: self.playerPlane.parent)
      self.playerTransparencyPlane.addChild(self.playerPlane)
      startX = 0
      startY = -(usableHeight - infoStripHeight) / 2
      playerTransparencyPlane.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: playerTransparencyPlane.parent)
      
      self.generateCollisionShapes(recursive: true)
   }
}

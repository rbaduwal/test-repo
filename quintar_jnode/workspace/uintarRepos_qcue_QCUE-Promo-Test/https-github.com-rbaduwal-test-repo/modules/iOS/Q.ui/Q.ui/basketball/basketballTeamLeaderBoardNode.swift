import UIKit
import Q

internal class basketballTeamLeaderBoardNode: basketballCourtsideBoard {

   // How this view looks
   public var viewSettings: viewSettings
   struct viewSettings {
      var backgroundColor: String = defaults.highlightColor
      var opacity: Float = defaults.cardBackgroundOpacity
      var endTitle: String = defaults.endTitle
      var titleSize: Float = defaults.mediumFontSize
      var titleFontFamily: String = defaults.leaderBoardTitleFontFamily
      var titleColor: String = defaults.titleColor
      var titleBackgroundColor: String = defaults.titleColor
      var nameSize: Float = defaults.smallerFontSize
      var nameFontFamily: String = defaults.leaderBoardNameFontFamily
      var nameColor: String = defaults.highlightColor
      var scrSize: Float = defaults.smallerFontSize
      var scrFontFamily: String = defaults.leaderBoardScrFontFamily
      var scrColor: String = defaults.titleColor
      var highlightColor: String = defaults.highlightColor
      var underscoreColor: String = defaults.titleColor
      var underscoreOpacity: Float = defaults.cardBackgroundOpacity
      var underscoreWidth: Float = defaults.leaderBoardUnderscoreWidth
      var underscoreHeight: Float = defaults.leaderBoardUnderscoreHeight
      var boardHeight: Float = defaults.leaderBoardHeight
      var categoryOrder: [String] = defaults.leaderBoardCategoryOrder
      var playerWidth: Float = defaults.leaderBoardPlayerWidth
      var borderWidth: Float = defaults.leaderBoardBorderWidth
      var headShotWidth: Float = defaults.leaderBoardHsWidth
   }
   
   // Data binding
   public var viewModel: basketballViewModel
   
   // The title is the three-character team abreviation, a space, and the end title - all caps.
   // Return a default title if we don't have a selected team
   public var title: String {
      if let team = self.viewModel.selectedTeam {
         return (team.abreviatedName + " " + self.viewSettings.endTitle).uppercased()
      } else {
         return self.viewSettings.endTitle.uppercased()
      }
   }
   
   // Persistent planes (nodes)
   private var usablePlane = qModelEntity()
   private var teamLogoImagePlane = qModelEntity()
   private var titlePlane = qModelEntity()
   private var leadersPlane = qModelEntity()
   
   private var playerImageView = teamPlayerImage(frame: .init(x: 0, y: 0, width: defaults.leaderBoardHsPixels, height: defaults.leaderBoardHsPixels))
   private var teamImageView = teamPlayerImage(frame: .init(x: 0, y: 0, width: defaults.leaderBoardHsPixels, height: defaults.leaderBoardHsPixels))
   private var downloader: Q.httpDownloader = Q.httpDownloader()
   weak private var arView: qARView? = nil
   private var titleFont: UIFont = UIFont()
   private var scrFont: UIFont = UIFont()
   private var nameFont: UIFont = UIFont()
   private let padding: Float = defaults.leaderBoardBorderPadding
   
   override required init() {
      fatalError("init() has not been implemented")
   }
   required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   required init(model: basketballViewModel, viewSettings: viewSettings, arView: qARView) {
      self.viewModel = model
      self.viewSettings = viewSettings
      self.arView = arView
      
      super.init()
      
      // Create our model once and only once - it will be reused throughout the lifecycle of this instance
      createModel()
   }
   
   public func update(vs: viewSettings) {

      guard let selectedTeam = viewModel.selectedTeam else { return }
      
      // Handle data updates
      selectedTeam.leaderUpdated = { team in
         // Check the team because we don't remove callbacks when the selected team changes
         if selectedTeam == team {
            DispatchQueue.main.async {
               self.update(vs: self.viewSettings)
            }
         }
      }
      
      // Border
      self.update( materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.highlightColor))])
      
      // Team logo
      UIImage.fromUrl(url: selectedTeam.logoUrl, downloader: downloader, completion:{ image in
         if let i = image {
            self.teamImageView.setData(image: i, borderColor: .clear, borderWidth: 0.0, isTeamLogo: true)
            let convertedCGImage = self.teamImageView.asImage().cgImage
            if let convertedCGImage = convertedCGImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var playerImageMaterial = qUnlitMaterial()
               playerImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               self.teamLogoImagePlane.update(mesh: nil, materials: [playerImageMaterial])
            }
         }
      })
      
      // Title
      self.titlePlane.update(
         mesh: .generateText(self.title, extrusionDepth: 0, font: self.titleFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
         materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.titleColor))])
      
      // Iterate through each category IN ORDER.
      // If we find a leader in that category, create a player card;
      // if not, show the category and underline but leave everything else empty
      var startX: Float = 0.0
      var startY: Float = 0.0
      var width: Float = 0.0
      var height: Float = 0.0
      var numLeaders = 0;
      for categoryAbreviation in vs.categoryOrder {
         
         // Set content based on whether we have a leader matching this category, and whether or not they have a value associated with their leadership
         let leaderValueString: String
         let headshotUrl: String
         let leaderNameString: String
         if let teamLeader = self.viewModel.selectedTeam?.leaders[categoryAbreviation], teamLeader.value > 0 {
            // Set the values we'll use
            leaderValueString = "\(teamLeader.value) \(categoryAbreviation)".uppercased()
            headshotUrl = teamLeader.player?.hsUrl ?? ""
            leaderNameString = teamLeader.player?.sn.uppercased() ?? ""
         } else {
            leaderValueString = categoryAbreviation.uppercased()
            headshotUrl = ""
            leaderNameString = ""
         }
      
         // The leader's (or player's) plane. This is the parent for all player-specific info.
         // Reuse existing planes when possible.
         let teamLeaderPlane: qEntity
         if self.leadersPlane.children.count > numLeaders {
            teamLeaderPlane = self.leadersPlane.children[numLeaders]
         } else {
            height = self.leadersPlane.model!.mesh.bounds.extents.y
            teamLeaderPlane = qEntity()
            self.leadersPlane.addChild(teamLeaderPlane)
         }

         // Now for the child nodes of the teamLeaderPlane.
         // Find existing child nodes using their index; in the future we could search by name instead.
            
         // Create or update this team leader's value, such a points, rebounds, etc.
         // (index == 0)
         let leaderValue: qModelEntity
         if teamLeaderPlane.children.count > 0, let me = teamLeaderPlane.children[0] as? qModelEntity {
            leaderValue = me
         } else {
            leaderValue = qModelEntity()
            teamLeaderPlane.addChild(leaderValue)
         }
         leaderValue.update(
            mesh: .generateText(leaderValueString, extrusionDepth: 0, font: self.scrFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
            materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.scrColor))])
         startX = -leaderValue.model!.mesh.bounds.extents.x / 2
         startY = self.leadersPlane.model!.mesh.bounds.extents.y / 4
         leaderValue.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: leaderValue.parent)
            
         // Create or update the underline
         // (index == 1)
         let scoreUnderline: qModelEntity
         if teamLeaderPlane.children.count > 1, let me = teamLeaderPlane.children[1] as? qModelEntity {
            scoreUnderline = me
         } else {
            scoreUnderline = qModelEntity()
            teamLeaderPlane.addChild(scoreUnderline)
         }
         width = vs.underscoreWidth * vs.playerWidth // Leave some space between the tips of the underlines
         height = vs.underscoreHeight
         scoreUnderline.update(
            mesh: .generateBox(width: width, height: height, depth: 0),
            materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.underscoreColor, alpha: CGFloat(vs.underscoreOpacity)))])
         startX = 0
         startY = (self.leadersPlane.model!.mesh.bounds.extents.y / 4)
         scoreUnderline.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: scoreUnderline.parent)
         
         // Create or update the headshot
         // (index == 2)
         let headshot: qModelEntity
         if teamLeaderPlane.children.count > 2, let me = teamLeaderPlane.children[2] as? qModelEntity {
            headshot = me
         } else {
            headshot = qModelEntity()
            teamLeaderPlane.addChild(headshot)
         }
         UIImage.fromUrl(url: headshotUrl, downloader: downloader, completion:{ image in
            if let i = image {
               
               // Some magic is happening here. A 2D nib is being used to generate a frame with border around the headshot, then converted back to a CGImage.
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
                  
                  width = vs.headShotWidth * vs.playerWidth
                  height = width
                  headshot.update(
                     mesh: .generateBox(width: width, height: height, depth: 0),
                     materials: [playerImageMaterial])
                  startX = 0
                  startY = (self.leadersPlane.model!.mesh.bounds.extents.y / 4) - 4.2
                  headshot.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: headshot.parent)
                  headshot.isEnabled = true
               }
            }
         })

         //Setting default player image.
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
            
            width = vs.headShotWidth * vs.playerWidth
            height = width
            headshot.update(
               mesh: .generateBox(width: width, height: height, depth: 0),
               materials: [playerImageMaterial])
            startX = 0
            startY = (self.leadersPlane.model!.mesh.bounds.extents.y / 4) - 4.2
            headshot.setPosition(qVector3(startX, startY, constants.zFightBreakup), relativeTo: headshot.parent)
            headshot.isEnabled = true
         }

         // Create or update the name
         // (index == 3)
         let leaderName: qModelEntity
         if teamLeaderPlane.children.count > 3, let me = teamLeaderPlane.children[3] as? qModelEntity {
            leaderName = me
         } else {
            leaderName = qModelEntity()
            teamLeaderPlane.addChild(leaderName)
         }
         if leaderNameString != "" {
            let maxSize = CGRect(x: 0, y: 0, width: CGFloat(vs.playerWidth), height: CGFloat(self.leadersPlane.model!.mesh.bounds.extents.y))
            leaderName.update(
               mesh: .generateText(leaderNameString.uppercased(), extrusionDepth: 0, font: nameFont, containerFrame: maxSize, alignment: .center, lineBreakMode: .byTruncatingTail),
               materials: [qUnlitMaterial(color: UIColor.init(hexString: vs.nameColor))])
            let shiftDownRatio: Float = 7/24 // More than 1/4, less than 1/3
            startX = 0
            startY = -self.leadersPlane.model!.mesh.bounds.extents.y * shiftDownRatio
            leaderName.setPositionForText(SIMD3<Float>(startX, startY, constants.zFightBreakup), relativeTo: leaderName.parent, withFont: nameFont )
            leaderName.isEnabled = true
         } else {
            // Hide the name if empty
            leaderName.isEnabled = false
         }
         
         // Increment loop counters
         numLeaders += 1
      }
      
      // Position the team leaders inside the team leaders plane.
      // The spacing is minimu configured player width, but may be greater to justify within available space
      let spacing = max(vs.playerWidth, self.leadersPlane.model!.mesh.bounds.extents.x / Float(vs.categoryOrder.count))
      startX = (-self.leadersPlane.model!.mesh.bounds.extents.x + spacing) / 2
      for leaderPlane in self.leadersPlane.children {
         leaderPlane.setPosition(qVector3(startX, 0, constants.zFightBreakup), relativeTo: leaderPlane.parent)
         startX += spacing
      }
      
      // AFTER we have checked for changes, update our view settings
      self.viewSettings = vs
      
      // TODO: I do not like this, there must be a better way
      self.forceName(defaults.forceNameLeaderboard, recursive: true)
   }
   
   private func createModel() {
      // This should only be called once by the constructor, use update() for data and visual changes.
   
      let titleAreaPercentage: Float = 7/24 // More than 1/4, less than 1/3
      let titlePaddingLeft: Float = 1.2
      let teamLogoWidth = (self.viewSettings.boardHeight * titleAreaPercentage) - self.viewSettings.borderWidth - (self.padding * 2)
      var width: Float = 0
      var height: Float = 0
      var startX: Float = 0
      var startY: Float = 0
      
      // Create the font we will use for leader values - fallback to default if we can't load it
      let scoreFontSize = CGFloat(self.viewSettings.scrSize)
      self.scrFont = UIFont(name: self.viewSettings.scrFontFamily, size: scoreFontSize) ?? .init(descriptor: .init(name: defaults.leaderBoardScrFontFamily, size: 0), size: scoreFontSize)
      
      // Create the font we will use for player names
      let nameFontSize = CGFloat(self.viewSettings.nameSize)
      self.nameFont = UIFont(name: self.viewSettings.nameFontFamily, size: nameFontSize) ?? .init(descriptor: .init(name: defaults.leaderBoardNameFontFamily, size: 0), size: nameFontSize)
      
      // We assume the title is the three-character team abreviation, a space, and the end title - all caps.
      // Use characters that are typically wide so we have room for any team abreviation.
      let titleMaterial = qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.titleColor))
      let fakeTitle = ("MWm" + " " + self.viewSettings.endTitle).uppercased()
      let titleFontSize = CGFloat(self.viewSettings.titleSize)
      self.titleFont = UIFont(name: self.viewSettings.titleFontFamily, size: titleFontSize) ?? .init(descriptor: .init(name: defaults.leaderBoardTitleFontFamily, size: 0), size: titleFontSize)
      self.titlePlane = qModelEntity(
         mesh: .generateText(fakeTitle, extrusionDepth: 0, font: titleFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail),
         materials: [titleMaterial])
      let titleSize = self.titlePlane.model!.mesh.bounds.extents
      
      // Determine the total width of this leader board. It will be the larger of the following widths:
      //  - border (on both sides) + team logo + padding + title
      //  - border (on both sides) + width of all category leaders cards
      let totalWidth: Float = (self.viewSettings.borderWidth * 2) +
         max( teamLogoWidth + (self.padding * 2) + titleSize.x,
            self.viewSettings.playerWidth * Float(self.viewSettings.categoryOrder.count))
      
      // Create our board and border
      self.update(
         mesh: .generateBox(width: totalWidth, height: self.viewSettings.boardHeight, depth: 0),
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.highlightColor))])
      width = totalWidth - (self.viewSettings.borderWidth * 2)
      height = self.viewSettings.boardHeight - (self.viewSettings.borderWidth * 2)
      self.usablePlane = qModelEntity(
         mesh: .generateBox(width: width, height: height, depth: 0),
         materials:  [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.titleBackgroundColor))])
      self.addChild(self.usablePlane)
      self.usablePlane.setPosition( qVector3(0, 0, constants.zFightBreakup), relativeTo: self.usablePlane.parent)
      
      // Create the space for the team logo
      width = teamLogoWidth
      height = teamLogoWidth
      self.teamLogoImagePlane = qModelEntity(
         mesh: .generateBox(width: width, height: height, depth: 0),
         materials: [qUnlitMaterial()])
      self.usablePlane.addChild(teamLogoImagePlane)
      startX = -(totalWidth - width) / 2 + self.viewSettings.borderWidth + self.padding
      startY = (self.viewSettings.boardHeight - height) / 2 - self.viewSettings.borderWidth - self.padding
      self.teamLogoImagePlane.setPosition( qVector3(startX, startY, constants.zFightBreakup), relativeTo: self.teamLogoImagePlane.parent)

      // Add the title
      self.usablePlane.addChild(titlePlane)
      startX = (width / 2) + titlePaddingLeft
      // The text shows up with y(0) being near (but not exactly) along the bottom of the text.
      self.titlePlane.setPositionForText( SIMD3<Float> (startX, startY, constants.zFightBreakup), relativeTo: self.titlePlane.parent, withFont: self.titleFont)
      
      // Create the field behind the leaders. This requires an extra "occlusion" plane so we can have transparency
      height = (self.viewSettings.boardHeight * (1 - titleAreaPercentage)) - self.viewSettings.borderWidth
      width = totalWidth - (self.viewSettings.borderWidth * 2)
      let mesh: qMeshResource = .generateBox(width: width, height: height, depth: 0)
      
      let leadersTransparencyPlane = qModelEntity(
         mesh: mesh,
         materials: [qOcclusionMaterial()])
      self.usablePlane.addChild(leadersTransparencyPlane)
      self.leadersPlane = qModelEntity(
         mesh: mesh,
         materials: [qUnlitMaterial(color: UIColor.init(hexString: self.viewSettings.backgroundColor, alpha: CGFloat(self.viewSettings.opacity)))])
      self.leadersPlane.setPosition( qVector3(0, 0, constants.zFightBreakup), relativeTo: self.leadersPlane.parent)
      leadersTransparencyPlane.addChild(self.leadersPlane)
      
      startX = 0
      startY = -(self.viewSettings.boardHeight - height) / 2 + self.viewSettings.borderWidth
      leadersTransparencyPlane.setPosition( qVector3(startX, startY, constants.zFightBreakup), relativeTo: leadersTransparencyPlane.parent)
      
      self.generateCollisionShapes(recursive: true)
   }
}

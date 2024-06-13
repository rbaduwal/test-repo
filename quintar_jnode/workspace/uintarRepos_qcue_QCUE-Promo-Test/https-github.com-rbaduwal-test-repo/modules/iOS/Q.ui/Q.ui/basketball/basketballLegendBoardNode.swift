import UIKit
import Combine
import simd
import Q

internal struct Legend {
   var text: String
   var color: UIColor
}

internal class basketballLegendBoardNode: qEntity, qHasModel, qHasCollision {
   
   var legends: [Legend]
   var title: String
   var titleImageName: String
   var backgroundColor: UIColor?
   weak private var arView: qARView? = nil
   
   var cameraPositionUpdatesCallback: ((simd_float4) -> ())?
   
   private var board: qEntity = qEntity()
   private var legendWidth: Float = 0.3
   private let contentSpacing: Float = 0.01 // spacing between title and legends strip
   private var boardHeight: Float { 0.5 + contentSpacing }
   private let interLegendPadding: Float = 0.05
   private let titleComponentSpacing: Float = 0.15
   private let titleFontSize: CGFloat = 0.15
   private let secondaryTextFontSize: CGFloat = 0.06
   private var downloader: downloader!
   private var imageContainerEntity: qEntity!
   private var updateSubscription: Cancellable?
   private var teamLogoSize: Float = 0.2
   private var totalLegendComponentWidth : Float = 2.0
   private var titleEntity = qModelEntity()
   
   required override init() {
      fatalError("init() has not been implemented")
   }
   required init(legends: [Legend], title: String, titleImageName: String, backgroundColor: UIColor? = nil, arView: qARView?) {
      self.arView = arView
      self.legends = legends
      self.title = title
      self.titleImageName = titleImageName
      self.backgroundColor = backgroundColor
      super.init()
      
      createBoard()
   }
   
   public required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
   }
   
   internal func getTotalLegendWidth() -> Float {
      totalLegendComponentWidth = teamLogoSize + titleComponentSpacing + titleEntity.model!.mesh.bounds.extents.x
      totalLegendComponentWidth = totalLegendComponentWidth * 30
      
      return totalLegendComponentWidth
   }
   
   private func createBoard() {
      //        self.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
      let scale: Float = 30
      self.setScale(qVector3(scale, scale, scale), relativeTo: nil)
      
      board = qModelEntity(mesh: .generateBox(size: qVector3(2.5, boardHeight, 0.01)), materials: [qUnlitMaterial(color: .clear)])
      
      if let bgColor = backgroundColor {
         // adding topLeftImage
         imageContainerEntity = qModelEntity(mesh: .generateBox(size: qVector3(teamLogoSize, teamLogoSize, 0)), materials: [qUnlitMaterial(color: bgColor)])
      }
      
      downloader = httpDownloader()
      
      if let downloader = downloader as? httpDownloader {
         // Title image.
         UIImage.fromUrl(url: titleImageName, downloader: downloader, completion:{ image in
            if let convertedCGImage = image?.cgImage {
               let imageTextureResource = try! qTextureResource.generate(from: convertedCGImage, withName: nil, options: .init(semantic: .none))
               var teamImageMaterial = qUnlitMaterial()
               teamImageMaterial.color = .init(tint: .white.withAlphaComponent(0.99), texture: .init(imageTextureResource))
               
               let imageSize = self.teamLogoSize
               let imagePlaneEntity = qModelEntity(mesh: qMeshResource.generateBox(width: imageSize, height: imageSize,depth: 0), materials: [teamImageMaterial])
               imagePlaneEntity.position = qVector3(0, 0, 0.01)
               self.imageContainerEntity.addChild(imagePlaneEntity)
            }
         })
      }
      
      board.addChild(imageContainerEntity)
      
      // adding Top Title
      titleEntity = qModelEntity(
         mesh: .generateText(title,
         extrusionDepth: 0,
         font: .systemFont( ofSize: titleFontSize), // TODO: Should have a configurable font here
         containerFrame: .zero,
         alignment: .center,
         lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      board.addChild(titleEntity)
      
      let totalTitleComponentsWidth = teamLogoSize + titleEntity.model!.mesh.bounds.extents.x
      legendWidth = totalTitleComponentsWidth / (Float(legends.count) + interLegendPadding)
      var startX: Float = -(totalTitleComponentsWidth / 2) + interLegendPadding
      imageContainerEntity.position = qVector3(startX, 0.11 + contentSpacing / 2, 0)
      
      titleEntity.setPosition(qVector3(titleComponentSpacing, -0.12, 0.01), relativeTo: imageContainerEntity)
      
      for legend in legends {
         let legendEntity = createLegendEntity(using: legend)
         legendEntity.setPosition(qVector3(startX + interLegendPadding, -0.13 - (contentSpacing / 2), -0.0011), relativeTo: board)
         board.addChild(legendEntity)
         startX += legendWidth + interLegendPadding
      }
      
      if let bgColor = backgroundColor {
         // The actual board that is displayed if required
         let backgroundBoard = qModelEntity(mesh: .generateBox(size: qVector3(totalTitleComponentsWidth + legendWidth, boardHeight, 0)), materials: [qUnlitMaterial(color: bgColor)])
         backgroundBoard.position = qVector3(0, 0, -0.001)
         
         board.addChild(backgroundBoard)
      }
      
      self.addChild(board)
   }
   private func createLegendEntity(using legend: Legend) -> qEntity {
      let basePlane = qModelEntity(mesh: .generateBox(size: qVector3(legendWidth, teamLogoSize, 0)), materials: [qUnlitMaterial(color: .clear)])
      let percentageTitleEntity = qModelEntity(
         mesh: .generateText(legend.text, extrusionDepth: 0,
         font: .systemFont(ofSize: secondaryTextFontSize),
         containerFrame: .zero,
         alignment: .center,
         lineBreakMode: .byTruncatingTail), materials: [qUnlitMaterial(color: .white)])
      let colorLegendPane = qModelEntity(mesh: .generateBox(size: qVector3(legendWidth, 0.1, 0.01)), materials: [qUnlitMaterial(color: legend.color)])
      
      let xExtent = percentageTitleEntity.model!.mesh.bounds.extents.x
      
      percentageTitleEntity.position = qVector3(-xExtent / 2, 0.03, 0.01)
      basePlane.addChild(percentageTitleEntity)
      
      colorLegendPane.position = qVector3(0, -0.030, 0.01)
      basePlane.addChild(colorLegendPane)
      
      return basePlane
   }
}

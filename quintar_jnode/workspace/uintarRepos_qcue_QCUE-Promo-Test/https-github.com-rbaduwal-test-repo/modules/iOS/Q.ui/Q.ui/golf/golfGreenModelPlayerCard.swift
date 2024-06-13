import Combine
import simd
import UIKit
import Q

class golfGreenModelPlayerCard: sceneGraphNode {
    
    public var viewModel: golfGreenViewModel
    
    weak private var arView: qARView? = nil
    private let widthOfCardInPixel: Float = 600.0
    private let offsetOfIndicator: Float = 28.0
    private let leadingOffset: Float = 0.006
    private var playerDetail: qModelEntity = qModelEntity()
    private var shotDistancePlane: qModelEntity = qModelEntity()
    private var shotDistanceEntity: qModelEntity = qModelEntity()
    private var gameRound: qModelEntity = qModelEntity()
    private var gameScore: qModelEntity = qModelEntity()
    private var informationPlane: qModelEntity = qModelEntity()
    private var updateSubscription: Cancellable?
    private var playerScoreEntity: qModelEntity!
    private var innerBGPlane: qModelEntity!
    private let zPadding: Float = 0.00001
    private let trailingOffset: Float = 0.006
    private var modelThickness: Float = 0
    private var cardRootEntity: qEntity = qEntity() //should check
    private var rootPGAEntity: qEntity = qEntity()
    private var rootAREntity: qEntity = qEntity()
    private var cardPivot: qVector3 = qVector3(0, 0, 0)
    private var heightMultipler: Int = 0
    private var golfGreenModelPlayerCardTextFont: qMeshResource.Font = qMeshResource.Font() //MeshResource.Font.systemFont(ofSize: 0.015, weight: .bold)
    
    init( model: golfGreenViewModel,
      arView: qARView?,
      heightMultipler: Int,
      modelThickness:Float) {
        self.modelThickness = modelThickness
        self.viewModel = model
        self.arView = arView
        self.heightMultipler = heightMultipler
        super.init()
        
        self.viewModel.ballLiePositionChanged += ("golfGreenModelPlayerCard", self.onBallPositionChanged)
        
        guard let golfGreenModelPlayerCardTextFont = ObjectFactory.shared.arTextSmallFont else {return}
        self.golfGreenModelPlayerCardTextFont = golfGreenModelPlayerCardTextFont
        createCard()
        rootPGAEntity.addChild(rootAREntity)
        let rotation = simd_quatf(angle: Float.pi/2.0, axis: SIMD3<Float>(1.0, 0.0, 0.0))
        rootPGAEntity.transform = qTransform(matrix: simd_float4x4(rotation))
        self.addChild(rootPGAEntity)
        self.onBallPositionChanged(ballPosition: self.viewModel.ballLiePosition)
        log.instance.push(.INFO, msg: "Updated position:\(self.position)")
        self.hide()
        setBillboardConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
   required override init() {
        fatalError("init() has not been implemented")
    }
    
    // TODO: this setter should not be here - update the view model instead and have an event
    func onBallPositionChanged(ballPosition: SIMD3<Float>) {
        var positionInScene = ballPosition
       let currentCardHeight = Float((informationPlane.model?.mesh.bounds.extents.y ?? 0.0) * informationPlane.scale.y * self.transform.scale.y * 1.15)
        positionInScene.z += Float(heightMultipler) * currentCardHeight
        
        positionInScene.z += Float(modelThickness) + 1 //Float(5.0).feetToMeter
        log.instance.push(.INFO, msg: "\(viewModel.playerViewModel.name)\(positionInScene.y)")
        
        self.position = qVector3(positionInScene)
    }
    
    func update(shotNumber: Int, distance: Float) {
        shotDistanceEntity.model?.mesh = .generateText("\(distance.convertedToYardAndFeet)", extrusionDepth: 0.001, font:golfGreenModelPlayerCardTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
        let xExtentShotValue = shotDistancePlane.model!.mesh.bounds.max.x - shotDistanceEntity.model!.mesh.bounds.max.x - trailingOffset
        shotDistanceEntity.setPosition(qVector3(xExtentShotValue,-0.009,0), relativeTo: shotDistancePlane)
    }
    
    func createCard() {
        let paneHeight: Float = 0.022
        let informationPlaneHeight:Float = 0.056
        
        let data = self.viewModel
                
        var score: Int?
        
        if data.distanceToHole != 0 {
            score = (data.scoreAtTee != nil) ? data.scoreAtTee : data.totalScore
        } else {
            score = (data.scoreAfterHole != nil) ? data.scoreAfterHole : data.totalScore
        }
        
        //Right information plane
        informationPlane = qModelEntity(mesh: qMeshResource.generateBox(width: 0.168, height: informationPlaneHeight,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.2))])//0.2
        cardRootEntity.addChild(informationPlane)
        let infoPlaneScale: Float = 1.7
        informationPlane.scale = qVector3(infoPlaneScale, infoPlaneScale, infoPlaneScale)
        
        //Right player detail plane
        playerDetail = qModelEntity(mesh: qMeshResource.generateBox(width: 0.16, height: paneHeight,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.8))])
        informationPlane.addChild(playerDetail)
       let playerDetailYPosition = ((informationPlane.model?.mesh.bounds.extents.y ?? 0.0/2)-(playerDetail.model?.mesh.bounds.extents.y ?? 0.0/2.0))
       playerDetail.setPosition(qVector3(0, (playerDetailYPosition - 0.004) ?? 0.0,0.001), relativeTo: informationPlane)
        
        //Game score
        let gameScoreMesh = qMeshResource.generateText(Q.golfPlayer.score2str(score), extrusionDepth: 0.001, font: golfGreenModelPlayerCardTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
        let gameScoreMaterial = qUnlitMaterial(color: .white)
        gameScore = qModelEntity(mesh: gameScoreMesh, materials: [gameScoreMaterial])
        playerDetail.addChild(gameScore)
        
        
        //Game team
        let gameRoundDetails = "R\(data.roundNum) \(data.playerViewModel.name)"
        let gameRoundMesh = qMeshResource.generateText(gameRoundDetails, extrusionDepth: 0.001, font: golfGreenModelPlayerCardTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
        
        let gameRoundMaterial = qUnlitMaterial(color: .white)
        gameRound = qModelEntity(mesh: gameRoundMesh, materials: [gameRoundMaterial])
        playerDetail.addChild(gameRound)
        
        
       let totalNameWidth = gameRound.model?.mesh.bounds.extents.x ?? 0.0
       let totalScoreWidth = gameScore.model?.mesh.bounds.extents.x ?? 0.0
       var playerDetailWidth = playerDetail.model?.mesh.bounds.extents.x ?? 0.0
        let extraSpacing: Float = 0.03
        
        if totalNameWidth + totalScoreWidth + extraSpacing >= playerDetailWidth {
            let spacing = totalNameWidth + totalScoreWidth + extraSpacing - playerDetailWidth
            informationPlane.model?.mesh = .generateBox(size: qVector3(0.168 + spacing, informationPlaneHeight, 0))
            playerDetail.model?.mesh = .generateBox(size: qVector3(0.16 + spacing, paneHeight, 0))
            playerDetailWidth = 0.16 + spacing
        }
        let gameRoundLeading = playerDetail.model!.mesh.bounds.min.x + leadingOffset
        gameRound.setPosition(qVector3(gameRoundLeading,-0.008,0), relativeTo: playerDetail)
        let gameScoreXExtent = playerDetail.model!.mesh.bounds.max.x - gameScore.model!.mesh.bounds.max.x - trailingOffset
        gameScore.setPosition(qVector3(gameScoreXExtent,-0.008,0), relativeTo: playerDetail)
        
        
        //Right player detail underline
        let underLine = qModelEntity(mesh: qMeshResource.generateBox(width: playerDetailWidth, height: 0.002,depth: 0), materials: [qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)])
        informationPlane.addChild(underLine)
        underLine.setPosition(qVector3(0,-((playerDetail.model!.mesh.bounds.extents.y/2)+(underLine.model!.mesh.bounds.extents.y/2.0)) ,0), relativeTo: playerDetail)
        
        //Right player hole shot
        shotDistancePlane = qModelEntity(mesh: qMeshResource.generateBox(width: playerDetailWidth, height: paneHeight,depth: 0), materials: [qUnlitMaterial(color: .black.withAlphaComponent(0.6))])//0.5
        informationPlane.addChild(shotDistancePlane)
        shotDistancePlane.setPosition(qVector3(0,-((underLine.model!.mesh.bounds.extents.y/2.0)+(paneHeight/2.0) + underLine.model!.mesh.bounds.extents.y),0.001), relativeTo: underLine)
        
        //Shots
        let lastShotMesh = qMeshResource.generateText("Last Shot", extrusionDepth: 0.001, font: golfGreenModelPlayerCardTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
        let lastShotMaterial = qUnlitMaterial(color: viewModel.playerViewModel.primaryColor)
        let lastShot = qModelEntity(mesh: lastShotMesh, materials: [lastShotMaterial])
        shotDistancePlane.addChild(lastShot)
        lastShot.setPosition(qVector3(gameRoundLeading,-0.009,0), relativeTo: shotDistancePlane)
        
        // Shots value
        let shotValueMesh = qMeshResource.generateText("\(data.shotDistance.convertedToYardAndFeet)", extrusionDepth: 0.001, font: golfGreenModelPlayerCardTextFont, containerFrame: .zero, alignment: .center, lineBreakMode: .byTruncatingTail)
        let shotValueMaterial = qUnlitMaterial(color: .white)
        shotDistanceEntity = qModelEntity(mesh: shotValueMesh, materials: [shotValueMaterial])
        shotDistancePlane.addChild(shotDistanceEntity)
        let xExtentShotValue = shotDistancePlane.model!.mesh.bounds.max.x - shotDistanceEntity.model!.mesh.bounds.max.x - trailingOffset
        shotDistanceEntity.setPosition(qVector3(xExtentShotValue,-0.009,0), relativeTo: shotDistancePlane)
        
        cardPivot.y = ((informationPlane.model?.mesh.bounds.extents.y ?? 1)/2.0) * informationPlane.scale.y
        cardRootEntity.position = cardPivot
        //self.addChild(cardRootEntity)
        rootAREntity.addChild(cardRootEntity)
        
        self.scale = qVector3(100,100,100)
    }
    
    func setBillboardConstraints() {
       if let arView = self.arView {
          self.setBillboardConstraints(arView: arView, rootEntity: self.cardRootEntity)
       }
       self.distanceToCameraChanged = { distanceToCamera in
          let newScale = 1
          return qVector3(newScale,newScale,newScale)
       }
    }
}

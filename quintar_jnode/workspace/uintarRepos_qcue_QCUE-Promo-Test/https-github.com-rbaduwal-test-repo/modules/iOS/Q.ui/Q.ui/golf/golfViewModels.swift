import Q

// Concrete class for all golf view models
public protocol golfViewModel {
   var sportData: golfData? { get }
   var selectedRound: golfRound? { get set }
   var selectedPlayers: [golfPlayerViewModel]? { get set }
   var selectedGroup: golfGroup? { get set }
}

public protocol golfPlayerViewModel {
   var playerViewModel: playerViewModel<Q.golfPlayer> {get set}
}

struct golfTeeboxViewModel: golfPlayerViewModel {
   var playerViewModel: playerViewModel<Q.golfPlayer>
   let roundNum: Int
   var teeBoxPosition: qVector3 {
      didSet {
         teeBoxPositionChanged?(self.teeBoxPosition)
      }
   }
   //let playerIndex: Int
   let score: Int?
   let teeBoxScale: Float
   let maxTeeBoxScale: Float
   
   // Events
   var teeBoxPositionChanged: ((qVector3)->())? = nil
   let smallTeeBoxCardTextSize: Double
   let smallTeeBoxCardTextFont: String
   let bigTeeBoxCardTextSize: Double
   let bigTeeBoxCardTextFont: String
}

class golfGreenViewModel: golfPlayerViewModel {
   var playerViewModel: playerViewModel<Q.golfPlayer>
   let roundNum: Int
   var totalScore: Int? {
      didSet {
         totalScoreChanged.invoke() { callback in
            callback(self.totalScore)
         }
      }
   }
   let scoreAtTee: Int?
   let scoreAfterHole: Int?
   var shotNumber: Int {
      didSet {
         shotNumberChanged.invoke() { callback in
            callback(self.shotNumber)
         }
      }
   }
   var shotDistance: Float
   var distanceToHole: Float {
      didSet {
         distanceToHoleChanged.invoke() { callback in
            callback(self.distanceToHole)
         }
      }
   }
   var ballLiePosition: SIMD3<Float> {
      didSet {
         ballLiePositionChanged.invoke() { callback in
            callback(self.ballLiePosition)
         }
      }
   }
   let playerCardScale: Float
   let maxPlayerCardScale: Float
   //let playerIndex: Int = -1
   
   // Events
   var totalScoreChanged = Q.multiClosure<((Int?)->())>()
   var shotNumberChanged = Q.multiClosure<((Int)->())>()
   var distanceToHoleChanged = Q.multiClosure<((Float)->())>()
   var ballLiePositionChanged = Q.multiClosure<((SIMD3<Float>)->())>()
   var bigGreenCardTextSize: Double
   var bigGreenCardTextFont: String
   var smallGreenCardTextSize: Double
   var smallGreenCardTextFont: String
   
   init(playerViewModel: playerViewModel<Q.golfPlayer>, // player.getPrimaryColor()
        roundNum: Int,
        totalScore: Int?,
        scoreAtTee: Int?,
        scoreAfterHole: Int?,
        shotNumber: Int,
        shotDistance: Float,
        distanceToHole: Float,
        ballLiePosition: SIMD3<Float>,
        //playerIndex: player.getIndex(),
        playerCardScale: Float,
        maxPlayerCardScale: Float,
        bigGreenCardTextSize: Double,
        bigGreenCardTextFont: String,
        smallGreenCardTextSize: Double,
        smallGreenCardTextFont: String) {
      self.playerViewModel = playerViewModel
      self.roundNum = roundNum
      self.totalScore = totalScore
      self.scoreAtTee = scoreAtTee
      self.scoreAfterHole = scoreAfterHole
      self.shotNumber = shotNumber
      self.shotDistance = shotDistance
      self.distanceToHole = distanceToHole
      self.ballLiePosition = ballLiePosition
      self.playerCardScale = playerCardScale
      self.maxPlayerCardScale = maxPlayerCardScale
      self.bigGreenCardTextSize = bigGreenCardTextSize
      self.bigGreenCardTextFont = bigGreenCardTextFont
      self.smallGreenCardTextSize = smallGreenCardTextSize
      self.smallGreenCardTextFont = smallGreenCardTextFont
   }
}

class golfApexViewModel: golfPlayerViewModel {
   var playerViewModel: playerViewModel<Q.golfPlayer>
   let apexPosition: qVector3
   let apexHeight: Float
   let ballSpeed: Float
   let apexScale: Float
   let roundNum: Int
   let maxApexScale: Float
   let apexCardDetailsFontSize: Double
   let apexCardDetailsFont: String
   let apexCardUnitFontSize: Double
   let apexCardUnitFont: String
   let apexCardHeadFont: String
   let apexCardHeadFontSize: Double
   
   init(
      playerViewModel: playerViewModel<Q.golfPlayer>,
      apexPosition: qVector3,
      apexHeight: Float,
      ballSpeed: Float,
      apexScale: Float,
      roundNum: Int,
      maxApexScale: Float,
      apexCardDetailsFont: String,
      apexCardDetailsFontSize: Double,
      apexCardUnitFontSize: Double,
      apexCardUnitFont: String,
      apexCardHeadFont: String,
      apexCardHeadFontSize: Double) {
         self.playerViewModel = playerViewModel
         self.apexPosition = apexPosition
         self.apexHeight = apexHeight
         self.ballSpeed = ballSpeed
         self.apexScale = apexScale
         self.roundNum = roundNum
         self.maxApexScale = maxApexScale
         self.apexCardDetailsFont = apexCardDetailsFont
         self.apexCardDetailsFontSize = apexCardDetailsFontSize
         self.apexCardUnitFontSize = apexCardUnitFontSize
         self.apexCardUnitFont = apexCardUnitFont
         self.apexCardHeadFont = apexCardHeadFont
         self.apexCardHeadFontSize = apexCardHeadFontSize
      }
}

class golfShotViewModel: ballPathViewModel {
   var player: Q.golfPlayer
   var shot: Q.golfShot
   var isFromGreenContainer: Bool
   var isPuttTrace: Bool
   
   init(player: Q.golfPlayer,
      shot: Q.golfShot,
      isFromGreenContainer: Bool,
      isPuttTrace: Bool) {
      self.player = player
      self.shot = shot
      self.isFromGreenContainer = isFromGreenContainer
      self.isPuttTrace = isPuttTrace
      
      super.init(shotId: self.shot.shotId)
   }
}

class playerCardModel {
   public var playerCardEntity: golfGreenPlayerCardBaseEntity
   public var position: SIMD3<Float>
   public init( entity: golfGreenPlayerCardBaseEntity, position: SIMD3<Float> ) {
      self.playerCardEntity = entity
      self.position = position
   }
}

open class playerVisibilityModel {
   public var player: Q.golfPlayer
   public var isPlayerFlagVisible: Bool
   public var isShotTrailVisible: Bool
   public var isApexVisible: Bool
   public init( player: Q.golfPlayer,
      isPlayerFlagVisible: Bool,
      isShotTrailVisible: Bool,
      isApexVisible: Bool) {
      self.player = player
      self.isPlayerFlagVisible = isPlayerFlagVisible
      self.isShotTrailVisible = isShotTrailVisible
      self.isApexVisible = isApexVisible
   }
}

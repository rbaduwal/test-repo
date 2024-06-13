import Foundation

public struct decodableBasketballExperienceConfig: Decodable {
   public let experiences: [experience]
   
   public struct experience: Decodable {
      // Required for parsing
      let type: String
      
      // Optional for parsing
      public var defaultExposureBias: Float?
      public var maxTrackingFailure: Int?
      public var shotTrailAnimationDelay : Float?
      public var registrationFailureInterval: Int?
      var tiltLimitLow: Float? = defaults.tiltLimitLow
      var tiltLimitHigh: Float? = defaults.tiltLimitHigh
      var heatmap: heatmap?
      var homeTeamShot: shot?
      var awayTeamShot: shot?
      var heatmapBoardPositionA: qVector3?
      var heatmapBoardPositionB: qVector3?

      var legendBoardConfigurables: legendBoardConfigurables?
      var leaderBoardConfigurables: leaderBoardConfigurables?
      var playerCardConfigurables: playerCardConfigurables?

      struct heatmap: Decodable {
//         var textSize: Float? = defaults.heatmapTextSize
//         var textColor: String? = defaults.heatmaptTextColor
//         var textOpacity: Float? = defaults.heatmapTextOpacity
         var colors: [heatmapColors]
         
         struct heatmapColors: Decodable {
            var percentage: Int = 0
//            var color: String? = defaults.heatmapColor
//            var opacity: Float? = defaults.heatmapOpacity
         }
      }
      struct shot: Decodable {
         let floorTileSuccess: floorTile?
         let floorTileAttempt: floorTile?
         let trail: trail?
         
         struct floorTile: Decodable {
            var color: String? = defaults.floorTileColor
            var opacity: Float? = defaults.floorTileOpacity
            var scale: Float? = defaults.floorTileScale
         }
         struct trail: Decodable {
            var color: String? = defaults.shotColor
            var opacity: Float? = defaults.shotOpacity
            var fadeInPercentage: Float? = defaults.shotFadeInPercentage
            var fadeOutPercentage: Float? = defaults.shotFadeOutPercentage
            var flightAnimationSpeed: Float? = defaults.flightAnimationSpeed
            var radius: Float? = defaults.shotRadius
         }
      }
            
      struct legendBoardConfigurables: Decodable {
         var endTitle: String = "SHOT SUCCESS"
         var color: String = "#000000"
         var opacity: Float = 0.8
      }
      
      // MARK: - LeaderBoardConfigurables
      struct leaderBoardConfigurables: Decodable {
         var distanceFromCamera: Float?
         var backgroundColor: String?
         var opacity: Float?
         var endTitle: String?
         var titleSize: Float?
         var titleFontFamily: String?
         var nameSize: Float?
         var nameFontFamily: String?
         var scrSize: Float?
         var scrFontFamily: String?
         var colors: Colors?
         var leaderBoardPositions: LeaderBoardPositions?
         var categoryOrder: [String]?
         var playerWidth: Float?
         var borderWidth: Float?
         var underscoreWidth: Float?
         var underscoreHeight: Float?
         var headShotWidth: Float?
         var duration: Double?
      }
      
      // MARK: - LeaderBoardPositions
      struct LeaderBoardPositions: Decodable {
         let HomeTeamA: qVector3?
         let HomeTeamB: qVector3?
         let AwayTeamA: qVector3?
         let AwayTeamB: qVector3?
      }
      
      // MARK: - Colors
      struct Colors: Decodable {
         var awayTeam: Team?
         var hometeam: Team?
      }
      
      // MARK: - Team
      struct Team: Decodable {
         var highlight: String?
         var title: String?
         var underscore: String?
         var titleBackground: String?
         var underscoreOpacity: Float?
         var name: String?
         var scr: String?
      }
      
      // MARK: - PlayerCardConfigurables
      struct playerCardConfigurables: Decodable {
         var distanceFromCamera: Float?
         var endTitle: String?
         var nameSize: Float?
         var shotTypeSize: Float?
         var scrSize: Float?
         var backgroundColor: String?
         var backgroundOpacity: Float?
         var playerColors: playerColors?
         var playerCardPositions: PlayerCardPositions?
         var shotTypeFontFamily: String?
         var nameFontFamily: String?
         var scrFontFamily: String?
      }
      
      // MARK: - LeaderBoardPositions
      struct PlayerCardPositions: Decodable {
         let HomeTeamA: qVector3?
         let HomeTeamB: qVector3?
         let AwayTeamA: qVector3?
         let AwayTeamB: qVector3?
      }

      // MARK: - PlayerColors
      struct playerColors: Decodable {
         var homeTeam: PlayerTeam?
         var awayTeam: PlayerTeam?
      }

      // MARK: - PlayerTeam
      struct PlayerTeam: Decodable {
         var name: String?
         var shotType: String?
         var success: String?
         var attempt: String?
         let attemptOpacity: Float?
         var scr: String?
         var endTitle: String?
         var highlight: String?
         var shotTypeBackground : String?
      }
   }
}

import Foundation

public struct decodableGolfExperienceConfig: Decodable {
   public let experiences: [experience]
   
   public struct experience: Codable {
      // Required for parsing
      let type: String
      
      // Optional for parsing
      var connectingImageUrl: String?
      var autoBallTraceAnimationDelay: Int? = defaults.autoBallTraceAnimationDelay
      var groupPlayAnimationDelay: Int? = defaults.groupPlayAnimationDelay
      var puttTraceAnimationDelay: Int? = defaults.puttTraceAnimationDelay
      var teeBoxCardAppearDelay: Int? = defaults.teeBoxCardAppearDelay
      let ballTrace: ballTraceConfig?
      let modelUrl: String?
      var arElementMaxRange: Float? = defaults.arElementMaxRange
      var playerColors: [String]?
      var tiltLimitLow: Float? = defaults.tiltLimitLow
      var tiltLimitHigh: Float? = defaults.tiltLimitHigh
      public var maxTrackingFailure: Int?
      public var geofencingTimerInterval: Int?
   }
}

struct ballTraceConfig: Codable {
   var color: String? = defaults.shotColor
   var opacity: Float? = defaults.shotOpacity
   var fadeInPercentage = defaults.shotFadeInPercentage
   var fadeOutPercentage = defaults.shotFadeOutPercentage
   var flightAnimationSpeed: Float? = defaults.flightAnimationSpeed
   var chipTraceAnimationSpeed: Float? = defaults.chipTraceAnimationSpeed
   var intermediatePointCount: Int? = defaults.intermediatePointCount
   var puttTraceAnimationSpeed: Float? = defaults.puttTraceAnimationSpeed
   var apexScale: Float? = defaults.apexScale
   var playerStatCardScale: Float? = defaults.playerStatCardScale
   var teeBoxCardScale: Float? = defaults.teeBoxCardScale
   var delayBetweenShotAnimation: Float? = defaults.delayBetweenShotAnimation
   var minPointsCountForBallTraceFading: Int? = defaults.minPointsCountForBallTraceFading
   var minPointsCountForChipTraceFading: Int? = defaults.minPointsCountForChipTraceFading
   var minPointsCountForPuttTraceFading: Int? = defaults.minPointsCountForPuttTraceFading
   var chipTraceFadeInPercentage: Float? = defaults.chipTraceFadeInPercentage
   var chipTraceFadeOutPercentage: Float? = defaults.chipTraceFadeOutPercentage
   var puttTraceFadeInPercentage: Float? = defaults.puttTraceFadeInPercentage
   var puttTraceFadeOutPercentage: Float? = defaults.puttTraceFadeOutPercentage
   var teeShotPointsCountForGreenModel: Int? = defaults.teeShotPointsCountForGreenModel
   var ballSize: Float? = defaults.ballSize
   var ballSizeInModel: Float? = defaults.ballSizeInModel
   var maxApexScale:Float? = defaults.maxApexScale
   var maxPlayerStatCardScale:Float? = defaults.maxPlayerStatCardScale
   var maxTeeBoxCardScale:Float? = defaults.maxTeeBoxCardScale
   var playerStatCardDistanceToSurface: Float? = defaults.playerStatCardDistanceToSurface
   var teeBoxCardDistanceToSurface: Float? = defaults.teeBoxCardDistanceToSurface
   var flightThickness: Float? = defaults.flightThickness
   var puttThickness: Float? = defaults.puttThickness
   var apexCardDetailsFont: String? = defaults.apexCardBoldFontFamily
   var apexCardDetailsFontSize: Double? = defaults.apexCardDetailsFontSize
   var apexCardUnitFontSize: Double? = defaults.apexCardUnitFontSize
   var apexCardUnitFont: String? = defaults.apexCardMedFontFamily
   var apexCardHeadFont: String? = defaults.apexCardBoldFontFamily
   var apexCardHeadFontSize: Double? = defaults.apexCardHeadFontSize
   var bigTeeBoxCardTextSize: Double? = defaults.bigTeeBoxCardTextSize
   var bigTeeBoxCardTextFont: String? = defaults.teeBoxCardBoldFontFamily
   var smallTeeBoxCardTextSize: Double? = defaults.smallTeeBoxCardTextSize
   var smallTeeBoxCardTextFont: String? = defaults.teeBoxCardBoldFontFamily
   var bigGreenCardTextSize: Double? = defaults.bigGreenCardTextSize
   var bigGreenCardTextFont: String? = defaults.teeBoxCardBoldFontFamily
   var smallGreenCardTextSize: Double? = defaults.smallGreenCardTextSize
   var smallGreenCardTextFont: String? = defaults.smallGreenPlayerCardFont
}

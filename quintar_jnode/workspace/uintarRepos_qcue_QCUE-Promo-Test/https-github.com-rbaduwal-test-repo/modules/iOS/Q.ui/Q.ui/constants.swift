import Foundation
import UIKit

// Use for default values
public struct defaults {
   public static let courtModelScale: Float = 0.033
   public static let flightAnimationSpeed: Float = 0.05
   public static let chipTraceAnimationSpeed: Float = 0.01
   public static let flightThickness: Float = 0.5
   public static let intermediatePointCount: Int = 10
   public static let shotColor: String = "#FF0000"
   public static let shotOpacity: Float = 0.8
   public static let shotRadius: Float = 0.3
   public static let shotNumEdges: Int = 12
   public static let shotFadeInPercentage: Float = 0.1
   public static let shotFadeOutPercentage: Float = 0.1
   public static let chipTraceFadeInPercentage: Float = 0.3
   public static let chipTraceFadeOutPercentage: Float = 0.0
   public static let puttTraceFadeInPercentage: Float = 0.2
   public static let puttTraceFadeOutPercentage: Float = 0.0
   public static let puttThickness: Float = 0.6
   public static let puttTraceAnimationSpeed: Float = 0.05
   public static let apexScale: Float = 0.5
   public static let playerStatCardScale: Float = 0.5
   public static let teeBoxCardScale: Float = 0.5
   public static let delayBetweenShotAnimation: Float = 1
   public static let minPointsCountForBallTraceFading: Int = 40
   public static let minPointsCountForChipTraceFading: Int = 10
   public static let minPointsCountForPuttTraceFading: Int = 10
   public static let teeShotPointsCountForGreenModel: Int = 15
   public static let ballSize: Float = 1.0
   public static let ballSizeInModel: Float = 1.2
   public static let maxApexScale: Float = 100
   public static let maxPlayerStatCardScale: Float = 100
   public static let maxTeeBoxCardScale: Float = 100
   public static let playerStatCardDistanceToSurface: Float = 5.0
   public static let teeBoxCardDistanceToSurface: Float = 5.0
   public static let outlineColor: String = "#00FF00"
   public static let outlineOpacity: Float = 0.6
   public static let outlineRadius: Float = 0.3
   public static let modelScale: Double = 0.0064
   public static let autoBallTraceAnimationDelay: Int = 5
   public static let teeBoxCardAppearDelay: Int = 2
   public static let groupPlayAnimationDelay: Int = 2
   public static let puttTraceAnimationDelay: Int = 2
   public static let maxDeviceRollAngle: Float = 90.0
   public static let tiltLimitLow: Float = 45.0
   public static let tiltLimitHigh: Float = 45.0
   public static let playerCardScale: Float = 5
   public static let maxPlayerCardScale: Float = 100
   public static let arElementMaxRange: Float = 1000
   public static let score: Int = 0
   public static let golfPlayerPosition: Int = 1000
   public static let ambientIntensity: Float = 0
   //public static let heatmapTextSize: Float = 3.0
   //public static let heatmaptTextColor: String = "#FFFFFF"
   //public static let heatmapTextOpacity: Float = 0.8
   //public static let heatmapColor: String = "#F59814"
   //public static let heatmapOpacity: Float = 1.0
   public static let floorTileColor: String = "#00FF00"
   public static let floorTileOpacity: Float = 0.8
   public static let floorTileScale: Float = 1.0
   public static let cardBackgroundColor: String = "#000000"
   public static let cardBackgroundOpacity: Float = 0.6
   public static let smallerFontSize: Float = 1.8
   public static let smallFontSize: Float = 3
   public static let mediumFontSize: Float = 4.4
   public static let largeFontSize: Float = 5.6
   public static let scoreColor: String = "#000000"
   public static let highlightColor: String = "#000000"
   public static let titleColor: String = "#FFFFFF"
   public static let deviceTypeiOS: String = "iOS"
   public static let endTitle: String = "GAME LEADERS"
   public static let shotTypeBackgroundColor : String = "#FFFFFF"
   public static let successColor: String = "#FFFFFF"
   public static let attemptColor: String = "#FFFFFF"
   public static let attemptOpacity: Float = 0.7
   public static let leaderBoardHeight: Float = 24
   public static let leaderBoardPlayerWidth: Float = 9
   public static let leaderBoardBorderWidth: Float = 0.6
   public static let leaderBoardBorderPadding: Float = 0.6
   public static let leaderBoardTitleFontFamily: String = "GillSans-BoldItalic"
   public static let leaderBoardNameFontFamily: String = "GillSans-Bold"
   public static let leaderBoardScrFontFamily: String = "GillSans-Bold"
   public static let leaderBoardCategoryOrder: [String] = ["AST", "BLK", "PTS", "REB", "STL"]
   public static let leaderBoardUnderscoreWidth: Float = 0.75 // As a percentage
   public static let leaderBoardUnderscoreHeight: Float = 0.18 // In meters
   public static let leaderBoardHsWidth: Float = 0.8 // As a percentage
   public static let leaderBoardHsPixels: Int = 100
   public static let forceNameLeaderboard: String = "leaderboard"
   public static let forceNamePlayercard: String = "playercard"
   public static let playerCardNameFontFamily: String = "GillSans-BoldItalic"
   public static let playerCardShotTypeFontFamily: String = "GillSans-BoldItalic"
   public static let playerCardHsPixels: Int = 200
   public static let playerCardHsWidth: Float = 12 // As an absolute width
   public static let courtHalfWidth: Double = 25.0
   public static let courtHalfLength: Double = 47.0
   public static let courtsideBoardDistanceFromFloor: Float = 30
   public static let courtsideBoardDistanceFromCamera: Float = 20
   public static let courtsideBoardAnimationSpeed: Double = 1
   public static let playerName: String = "player"
   public static let deviceNotReadyMsg: String = "Device not ready for Tracking"
   public static let incorrectUserLocationMsg: String = "User Not at Location"
   public static let steadyAngle: Float = 90.0
   public static let allowedAngleDiff: Float = 45
   public static let apexCardDetailsFontSize: Double = 0.018
   public static let apexCardUnitFontSize: Double =  0.016
   public static let apexCardHeadFontSize: Double = 0.02
   public static let apexCardBoldFontFamily: String = "AvenirNextCondensed-DemiBold"
   public static let apexCardMedFontFamily: String = "AvenirNextCondensed-Medium"
   public static let playerCardNormalFontFamily: String = "AvenirNextCondensed-Regular"
   public static let teeBoxCardBoldFontFamily: String = "AvenirNextCondensed-DemiBold"
   public static let smallGreenPlayerCardFont = "AvenirNextCondensed-DemiBold"
   public static let bigTeeBoxCardTextSize: Double = 0.6
   public static let smallTeeBoxCardTextSize: Double = 0.9
   public static let bigGreenCardTextSize: Double = 0.03
   public static let smallGreenCardTextSize: Double = 0.6
   public static let alreadyInARMode = "Already in AR."
   public static let deviceOrientationIncorrect = "Device orientation must be"
   public static let parentNotSet = "Property 'parent' must be set."
   public static let experienceAlreadyCreated = "Experience is already created"
   public static let unknownExperienceType = "unknown experience type."
   public static let sportExperienceType = "sportExperience type"
   public static let doesNotSupport = "does not support"
}

// Use for known constants
public struct constants {
   // Try bumping Z by this value when layering planes close together, may not work in all cases.
   // Value is in meters.
   public static let zFightBreakup: Float = 0.15
   public static let golfCardSizeMultiplier: Float = 40.0
   public static let qUIBundleID: String = "ai.quintar.Q.ui"
   public static let meterToFeet:Float = 3.28
   
   // This is a workaround for a RealityKit quirk. RealityKit apparently requires a small opacity threshold
   // in order to support images with transparency built-in.
   // The idea is anything "almost" fully transparent becomes fully transparent.
   // Example usage:
   //    playerImageMaterial.color = .init(texture: .init(imageTextureResource))
   //    playerImageMaterial.blending = .transparent(opacity: 1.0)
   //    playerImageMaterial.opacityThreshold = minTransparencyThreshold
   public static let minTransparencyThreshold: Float = 0.005
   
   // Internal error messages intended for debugging and logging, not end-user consumption
   public static func testSceneIntrinsicsErrorMessage(_ field: String) -> String {
      return "Test JSON used for connect has a missing or invalid \"\(field)\" field"
   }
   
   public static let ballTraceReplayDidCompleteNotification = "BallTraceReplayDidCompleteNotification"
   public static let ballTraceAnimationDidCompleteNotification = "BallTraceAnimationDidCompleteNotification"
   public static let ballTraceAnimationOnGreenDidCompleteNotification = "ballTraceAnimationOnGreenDidCompleteNotification"
   public static let groupReplayCompleted = "groupReplayCompleted"
   public static let onPlayerCardVisibilityChanged = "onPlayerCardVisibilityChanged"
   public static let onTappedNotification = "onTappedNotification"
}

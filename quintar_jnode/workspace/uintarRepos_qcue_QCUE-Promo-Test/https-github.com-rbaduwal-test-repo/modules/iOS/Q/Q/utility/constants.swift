import Foundation

// Use for default values
public struct defaults {
   public static let registrationDelay: Int = 4
   public static let lightEstimationThreshold: Double = 100.0
   public static let confidenceDegradePercentage: Double = 0.9
   public static let confidenceHighThreshold: Double = 61.0
   public static let confidenceMediumThreshold: Double = 31.0
   public static let confidenceIndex: Double = 75
   public static let longSecs: Double = 30.0
   public static let mediumSecs: Double = 10.0
   public static let shortSecs: Double = 4.0
   public static let fourcc: String = "Y800"
   public static let jpegCompression: Float = 0.25
   public static let jpegScale: Float = 1
   public static let liveDataTimeout: Float = 3.0
   public static let maxAttemptsBeforeReset: Int = 3
   public static let defaultHttpTimeout: Double = 60
   public static let playerColors = [ "#FDC22D", "#DE6138", "#20C0F1", "#40FA0B" ]
}

// Use for known constants
public struct constants {
   public static let feetToMeter: Float = 0.3048
   public static let feetToYard: Float = 0.333333
   public static let feetToInch: Float = 12.0
   public static let meterToFeet: Float = 1.0 / feetToMeter
   public static let groupLocationChangedNotification = "groupLocationChanged"
   public static let playerDidChangeNotification = "PlayerDidChangeNotification"
   public static let leaderUpdated = "leaderChangedNotification"
   internal static let onSportsDataLoadingCompletedNotification = "onSportsDataLoadingCompletedNotification"
   public static let networkNotAvailableMessage = "Internet connection is not available, lining up our shot will be possible once the connection is restored."
   public static let internalSerrverErrorMessage = "Internal server error."
}

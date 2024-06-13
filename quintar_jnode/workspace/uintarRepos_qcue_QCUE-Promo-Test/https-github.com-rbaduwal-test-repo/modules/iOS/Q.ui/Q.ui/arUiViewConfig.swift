import Foundation
import Q
import UIKit

public class arUiViewConfig: config {
   
   // config protocol
   public var timeout: Int = 200
   public var downloader: downloader? // Always a "modelDownloader"
   public var updated: ConfigUpdated? = nil
   public private(set) var url: String = ""
   public private(set) var data: [String: Any] = [String: Any]()
   public private(set) var testData: [String: Any] = [String: Any]()
   public private(set) var geofenceData: [String: Any]? = [String: Any]()
   
   // arUiViewConfig stuff
   
   // This is not read from the config file - recommend using code for this instead
   public var microphoneEnabled = false
   
   // This is not part of the architecture and is added because iOS has no native JSON object,
   // and dealing with String:Any dictionaries is cumbersome
   public var decodedData: decodableData?
   
   public private(set) var experience: EXPERIENCE?
   public private(set) var sport: SPORT = .UNKNOWN
   public private(set) var connectConfig: connectConfig?
   public private(set) var streamConfig: streamConfig?
   public private(set) var sportDataConfig: sportDataConfig?
   
   // For decoding JSON
   public struct decodableData: Decodable {
      public let arUiView: arUiViewSection?
      public let connect: subConfigData?
      public let sportData: subConfigData?
      
      public struct arUiViewSection: Decodable{
         public let sport: String
         public let experiences: [experienceConfig]
         
         public struct experienceConfig: Codable {
            public let type: String
         }
      }
      public struct subConfigData: Decodable{
         public let configUrl: String?
      }
   }
   
   public required init(data: [String:Any]) throws {
      _ = try self.processData(data: data)
   }
   
   public static func create(url: String, downloader: downloader? = httpDownloader(isCacheEnabled: false), callbackWhenDone: @escaping (configUpdate) -> ()) {
   
      let returnValue = arUiViewConfig( url: url, downloader: downloader )
      returnValue.updated = callbackWhenDone
      returnValue.downloader?.getJsonAsync(url) { downloaderResultJson in
         if downloaderResultJson.error == .NONE && !downloaderResultJson.data.isEmpty {
            let oldData = returnValue.data
            do {
               try returnValue.processData(data: downloaderResultJson.data)
               returnValue.updated?(configUpdate(error: .NONE, errorMsg: "", url: returnValue.url, oldJson: oldData, config: returnValue))
            } catch(let error) {
               returnValue.updated?(configUpdate(error: .PARSE, errorMsg: error.localizedDescription, url: returnValue.url, oldJson: oldData, config: nil))
            }
         } else {
            let configUpdate = configUpdate(error: downloaderResultJson.error, errorMsg: downloaderResultJson.message, url: returnValue.url, oldJson: returnValue.data, config: nil)
            returnValue.updated?(configUpdate)
         }
      }
   }
   
   private init(url: String, downloader: downloader? = httpDownloader(isCacheEnabled: false)) {
      self.url = url
      self.downloader = downloader
   }
   private func processData(data: [String: Any]) throws {
      self.decodedData = try parseJson(data: data)
      
      // Separate raw data into 'data' and 'testData'
      if let testData = data["test"] as? [String: Any] { self.testData = testData }
      if let geofenceData = data["geofence"] as? [String: Any] { self.geofenceData = geofenceData }
      self.data = data
      self.data.removeValue(forKey: "test")

      if let experience = decodedData!.arUiView?.experiences, let sport = decodedData!.arUiView?.sport {
         switch (experience.first?.type, sport) {
            case (EXPERIENCE.HOME.rawValue,SPORT.GOLF.rawValue):
               self.experience = EXPERIENCE.HOME
               self.sport = SPORT.GOLF
            case (EXPERIENCE.HOME.rawValue,SPORT.BASKETBALL.rawValue):
               self.experience = EXPERIENCE.HOME
               self.sport = SPORT.BASKETBALL
            case (EXPERIENCE.VENUE.rawValue,SPORT.GOLF.rawValue):
               self.experience = EXPERIENCE.VENUE
               self.sport = SPORT.GOLF
            case (EXPERIENCE.VENUE.rawValue,SPORT.BASKETBALL.rawValue):
               self.experience = EXPERIENCE.VENUE
               self.sport = SPORT.BASKETBALL
            default:
               throw errorWithMessage("Could not parse experience section in JSON")
         }
      } else { throw errorWithMessage("Could not parse experience section in JSON") }
      
      // Handle the connect section
      if let c = decodedData!.connect {
         if let connectConfigUrl = c.configUrl {
            // If we have a URL
            connectConfig = try Q.connectConfig(url: connectConfigUrl, downloader: self.downloader)
         } else {
            // We don't have a URL, so assume all the info is inline
            connectConfig = try Q.connectConfig( data: self.data["connect"] as! [String: Any] )
         }
      }
      
      // Handle the sportData section
      if let sd = decodedData!.sportData {
         if let sportDataConfigUrl = sd.configUrl {
            // If we have a URL
            sportDataConfig = try Q.sportDataConfig(url: sportDataConfigUrl, downloader: self.downloader)
         } else {
            // We don't have a URL, so assume all the info is inline
            sportDataConfig = try Q.sportDataConfig( data: self.data["sportData"] as! [String: Any] )
         }
      }
   }
}

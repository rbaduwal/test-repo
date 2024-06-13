import Foundation

public class connectConfig: config {
   // types
   public struct decodableData: Decodable {
      public let lid: String
      public let gid: String?
      public let fops: [fop]?
      
      public struct test: Decodable {}
   }
   public struct fop: Decodable {
      // Required for parsing
      public let id: String
      public var apiEntrypointUrl: String? = nil
      public var registrationDelay: Int? = defaults.registrationDelay
      
      // Optional for parsing
      public var lightEstimationThreshold: Double? = defaults.lightEstimationThreshold
      public var confidenceDegradePercentage: Double? = defaults.confidenceDegradePercentage
      public var confidenceHighThreshold: Double? = defaults.confidenceHighThreshold
      public var confidenceMediumThreshold: Double? = defaults.confidenceMediumThreshold
      public var confidenceIndex: Double? = defaults.confidenceIndex
      public var longSecs: Double? = defaults.longSecs
      public var mediumSecs: Double? = defaults.mediumSecs
      public var shortSecs: Double? = defaults.shortSecs
      public var fourcc: String? = defaults.fourcc
      public var jpegCompression: Float? = defaults.jpegCompression
      public var jpegScale: Float? = defaults.jpegScale
      public var maxAttemptsBeforeReset: Int? = defaults.maxAttemptsBeforeReset
   }
   
   // properties
   public var timeout: Int = 200
   public var downloader: downloader?
   public var updated: ConfigUpdated? = nil
   public private(set) var url: String = ""
   public private(set) var data: [String: Any] = [String: Any]()
   public private(set) var testData: [String: Any]  = [String: Any]()
   public var decodedData: decodableData?
   
   // init/deinit
   public required init(data: [String: Any]) throws {
      _ = try self.processData(data: data)
   }
   public required init(url: String, downloader: downloader? = httpDownloader(isCacheEnabled: false)) throws {
      self.url = url
      self.downloader = downloader
      
      if let downloaderResultJson = self.downloader?.getJson(url) {
         switch downloaderResultJson.error {
            case .NONE:
               try self.processData(data: downloaderResultJson.data)
            default:
               throw errorWithMessage(downloaderResultJson.message)
         }
      } else { throw errorWithMessage("Could not download connect config")
      }
   }
   public required init(url: String, downloader: downloader? = nil, callbackWhenDone: @escaping(configUpdate)->()) {
      self.url = url
      self.updated = callbackWhenDone
      self.downloader = downloader
      
      self.downloader?.getJsonAsync(url) { downloaderResultJson in
         if downloaderResultJson.error == .NONE && !downloaderResultJson.data.isEmpty {
            let oldData = self.data
            do {
               try self.processData(data: downloaderResultJson.data)
               self.updated?(configUpdate(error: .NONE, errorMsg: "", url: self.url, oldJson: oldData, config: self))
            } catch(let error) {
               self.updated?(configUpdate(error: .PARSE, errorMsg: error.localizedDescription, url: self.url, oldJson: oldData, config: nil))
            }
         } else {
            let configUpdate = configUpdate(error: downloaderResultJson.error, errorMsg: downloaderResultJson.message, url: self.url, oldJson: self.data, config: nil)
            self.updated?(configUpdate)
         }
      }
   }
   
   // public functions
   public func getConfig(forFop: String?) -> fop? {
      if let fops = decodedData?.fops {
         for fop in fops{
            if fop.id == forFop {
               return fop
            }
         }
      }
      return nil
   }
   public func getLightEstimationThreshold( locationId: String ) -> Double {
       if let lightEstimationThreshold =  getConfig(forFop: locationId)?.lightEstimationThreshold {
           return lightEstimationThreshold
       }
       return 100.0
   }
   
   // private functions
   private func processData(data: [String: Any]) throws {
      self.decodedData = try parseJson(data: data)
      
      // Separate raw data into 'data' and 'testData'
      if let testData = data["test"] as? [String: Any] { self.testData = testData }
      self.data = data
      self.data.removeValue(forKey: "test")
   }
}

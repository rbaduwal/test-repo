import Foundation

public class streamConfig: config {
   
   // config protocol
   public var timeout: Int = 200
   public var downloader: downloader?
   public var updated: ConfigUpdated? = nil
   public private(set) var url: String = ""
   public private(set) var data: [String: Any] = [String: Any]()
   public private(set) var testData: [String: Any]  = [String: Any]()
   
   // sportDataConfig stuff
   public var decodedData: decodableData?
   
   // For decoding JSON
   public struct decodableData: Decodable {
      // Required for parsing
      // TODO: FILL IN
      
      // Optional for parsing
      // TODO: FILL IN
      
      public struct test: Decodable {}
   }
   
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
   
   private func processData(data: [String: Any]) throws {
      self.decodedData = try parseJson(data: data)
      
      // Separate raw data into 'data' and 'testData'
      if let testData = data["test"] as? [String: Any] { self.testData = testData }
      self.data = data
      self.data.removeValue(forKey: "test")
   }
}

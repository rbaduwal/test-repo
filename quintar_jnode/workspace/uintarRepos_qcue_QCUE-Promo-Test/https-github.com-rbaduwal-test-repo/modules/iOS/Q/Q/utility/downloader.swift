import UIKit

// Declare this struct once, then typedef the result to produce "multiple" types
public struct downloaderResult<T> {
   public let error: ERROR
   public let message: String
   public let data: T
   
   public init(error: ERROR, message: String, data: T) {
      self.error = error
      self.message = message
      self.data = data
   }
}
public typealias downloaderResultJson = downloaderResult<[String: Any]>
public typealias downloaderResultImage = downloaderResult<UIImage?>

// Error type thrown by downloader
public class downloaderError: Error, CustomStringConvertible {
   let message: String
   let data: Data?
   
   public init(msg: String, data: Data?) {
      self.message = msg
      self.data = data
   }
   public var localizedDescription: String {
      var returnValue = message
      if let d = data, let s = String(data: d, encoding: String.Encoding.utf8) {
         returnValue += "\n\(s)"
      }
      return returnValue;
   }
   public var description: String { return localizedDescription }
}

public protocol downloader {
   
   // Synchronous versions
   func getJson(_ jsonUrl: String) -> downloaderResultJson

   // Asynchrounous versions
   func getJsonAsync(_ jsonUrl: String,completion: @escaping(downloaderResultJson)->Void)
   func getImageAsync(_ imageUrl: String, completion: @escaping (downloaderResultImage) -> ())
}

// A handy helper function
public func parseJson<T: Decodable>( data: [String: Any] ) throws -> T {
   let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
   let decodedData = try JSONDecoder().decode(T.self, from: jsonData)
   return decodedData;
}

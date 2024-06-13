import UIKit

public class bundleDownloader: downloader {
   
   public required init() {
   }
   
   public func getJson(_ jsonUrl: String) -> downloaderResultJson {
      var result:downloaderResultJson = downloaderResultJson(error:ERROR.PARSE, message: "", data: [:])
      if let bundleID = Bundle.main.bundleIdentifier {
         let bundle = Bundle(identifier: bundleID)
         let eventJSONPath = bundle!.url(forResource: jsonUrl, withExtension: nil)?.path ?? ""
         if let fileData = NSData(contentsOfFile: eventJSONPath) {
            do {
               let jsonData = try JSONSerialization.jsonObject(with: fileData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:AnyObject]
               result = downloaderResultJson(error: ERROR.NONE, message: "", data: jsonData)
            } catch {
               result = downloaderResultJson(error: ERROR.PARSE, message: parseError, data: [:])
            }
         } else {
            result = downloaderResultJson(error: ERROR.INVALID_PARAM, message: "File not exist", data:[:])
         }
      } else {
         result = downloaderResultJson(error: ERROR.INVALID_PARAM, message: "Bundler indentifer not configured", data:[:])
      }
      return result
   }
   
   public func getJsonAsync(_ jsonUrl: String,completion:@escaping(downloaderResultJson)->Void) {
      DispatchQueue.global().async {
         let result = self.getJson(jsonUrl)
         completion(result)
      }
   }
   public func getImageAsync(_ imageUrl: String, completion: @escaping (downloaderResultImage) -> ()) {
      let imagePath = Bundle.main.url(forResource: imageUrl, withExtension: nil)
      if let imagePath = imagePath {
         if let image = UIImage(contentsOfFile: imagePath.path) {
            let result = downloaderResultImage(error: .NONE, message: "", data: image)
            completion(result)
            return
         }
      }
      let result = downloaderResultImage(error: .INVALID_PARAM, message: invalidUrlError, data: nil)
      completion(result)
   }
}

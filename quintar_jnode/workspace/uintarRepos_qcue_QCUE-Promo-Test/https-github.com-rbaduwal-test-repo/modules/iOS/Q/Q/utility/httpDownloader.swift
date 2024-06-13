import UIKit
import Combine
@_implementationOnly import Kingfisher

public class httpError: downloaderError {
   let httpCode: Int
   
   public init(httpCode: Int, data: Data?) {
      self.httpCode = httpCode
      super.init(msg: "Request returned HTTP code \(self.httpCode)", data: data)
   }
}

open class httpDownloader: downloader {

   // Value in seconds representing the total timeout (send + receive)
   public var timeout: TimeInterval {
      didSet { setTimeout( timeout ) }
   }
   
   public var isCacheEnabled: Bool = true {
      didSet { setIsCacheEnabled( isCacheEnabled ) }
   }
   
   // For performance reasons, it is best to reuse a session. Here we have a session per instance of this object
   private var session: URLSession
   
   public required init( isCacheEnabled: Bool = true, timeout: TimeInterval = defaults.defaultHttpTimeout) {
      session = URLSession(configuration: URLSessionConfiguration.default)
      self.isCacheEnabled = isCacheEnabled
      self.timeout = timeout
      
      // didSet will not be called on properties from an initializer, so call those separately here
      setTimeout( self.timeout )
      setIsCacheEnabled( self.isCacheEnabled )
   }
   
   public func getJson(_ jsonUrl: String) -> downloaderResultJson {
      
      var result = downloaderResultJson(error:ERROR.PARSE, message: "", data: [:])
      guard let url = URL(string: jsonUrl) else {
         return  downloaderResultJson(error:ERROR.PARSE, message: invalidUrlError, data: [:])
      }
       
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
      self.session.dataTask(with: request) { data, response, error in
      
         if let httpResponse = response as? HTTPURLResponse {
            if error == nil {
               do {
                  if let responseData = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                     result = (downloaderResultJson(error: .NONE, message: "", data: responseData)) //None
                  }
               } catch let e {
                  result = downloaderResultJson(error: .PARSE, message: "\(e):\n\(data?.description ?? "")", data: [:])
               }
            }
            else {
               result = downloaderResultJson(error: .HTTP(httpResponse.statusCode), message: error!.localizedDescription, data: [:])
            }
         } else {
            if let error = error {
               switch error._code {
                  case SERVER_ERRORCODE.NOINTERNET.rawValue, SERVER_ERRORCODE.NOT_CONNECTED.rawValue:
                     result = downloaderResultJson(error: .NETWORK_ERROR, message: constants.networkNotAvailableMessage, data: [:])
                  default:
                     result = downloaderResultJson(error: .UNKNOWN_ERROR, message: parseError, data: [:])
               }
            } else {
               result = downloaderResultJson(error: .UNKNOWN_ERROR, message: parseError, data: [:])
            }
         }
         semaphore.signal()
      }
      .resume()
      semaphore.wait()
      return result
   }
   public func restfulQueryJson( request: httpMultipartRequest ) throws -> [String: Any] {
      
      request.urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.finalize()
      
      var exception: Error? = nil
      var returnValue: [String: Any]? = nil
      let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
      self.session.dataTask(with: request.urlRequest) { data, response, error in
         if let httpResponse = response as? HTTPURLResponse {
            if error != nil {
               exception = error
               semaphore.signal()
               return
            }
            if httpResponse.statusCode == 200 {
               do {
                  returnValue = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
               } catch ( let e ) {
                  exception = downloaderError(msg: "\(e)", data: data)
               }
            }
            else {
               exception = httpError(httpCode: httpResponse.statusCode, data: data)
            }
         } else {
            exception = downloaderError(msg: "Non-HTTP response", data: data)
         }
         
         semaphore.signal()
      }
      .resume()
      semaphore.wait()
      
      if exception != nil { throw exception! }
      
      return returnValue!
   }
   public func restfulQueryJson( endpoint: String,
      httpMethod: String = "GET",
      requestData: [String: Any]? = nil ) throws -> [String: Any] {
      
      guard let url = URL(string: endpoint) else {
         throw downloaderError(msg: "Invalid endpoint: \(endpoint)", data: nil)
      }
      
      var request = URLRequest(url: url)
      request.httpMethod = httpMethod
      if let rd = requestData {
         request.httpBody = try? JSONSerialization.data(withJSONObject: rd, options: [])
      }
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      
      var exception: Error? = nil
      var returnValue: [String: Any]? = nil
      let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
      self.session.dataTask(with: request) { data, response, error in
         if let httpResponse = response as? HTTPURLResponse {
            if error != nil {
               exception = error
               semaphore.signal()
               return
            }
            if httpResponse.statusCode == 200 {
               do {
                  returnValue = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
               } catch ( let e ) {
                  exception = downloaderError(msg: "\(e)", data: data)
               }
            } else {
               exception = httpError(httpCode: httpResponse.statusCode, data: data)
            }
         } else {
            exception = downloaderError(msg: "Non-HTTP response", data: data)
         }
         
         semaphore.signal()
      }
      .resume()
      semaphore.wait()
      
      if exception != nil { throw exception! }
      
      return returnValue!
   }
   public func getJsonAsync(_ jsonUrl: String, completion: @escaping(downloaderResultJson)->Void) {
      DispatchQueue.global().async {
         let result = self.getJson(jsonUrl)
         completion(result)
      }
   }
   public func restfulQueryJsonAsync( request: httpMultipartRequest,
      completion: @escaping(downloaderResultJson)->Void ) {
      
      DispatchQueue.global().async {
         var result = downloaderResultJson(error: .INVALID_PARAM, message: invalidUrlError, data: [:])
         do {
            let responseData = try self.restfulQueryJson(request: request)
            result = downloaderResultJson(error: .NONE, message: "", data: responseData)
         } catch let e as httpError {
            do {
               let returnValue = try JSONSerialization.jsonObject(with: e.data!, options: []) as? [String: Any]
               result = downloaderResultJson(error: .HTTP(e.httpCode), message: "\(e)", data: returnValue!)
            }
            catch {
               result = downloaderResultJson(error: .HTTP(e.httpCode), message: "\(e)", data: [:])
            }
         } catch let e {
            result = downloaderResultJson(error: .PARSE, message: "\(e)", data: [:])
         }
         
         completion(result)
      }
   }
   public func restfulQueryJsonAsync( endpoint: String,
      httpMethod: String = "GET",
      requestData: [String: Any]? = nil,
      completion: @escaping(downloaderResultJson)->Void ) {
      
      var result = downloaderResultJson(error: .INVALID_PARAM, message: invalidUrlError, data: [:])
      DispatchQueue.global().async {
         do {
            let responseData = try self.restfulQueryJson(endpoint: endpoint,
               httpMethod: httpMethod,
               requestData: requestData)
            result = downloaderResultJson(error: .NONE, message: "", data: responseData)
         } catch let e as httpError {
            result = downloaderResultJson(error: .HTTP(e.httpCode), message: "\(e)", data: [:])
         } catch let e {
            result = downloaderResultJson(error: .PARSE, message: "\(e)", data: [:])
         }
         completion(result)
      }
   }
   public func getImageAsync(_ imageUrl: String, completion: @escaping (downloaderResultImage) -> ()) {
      var result = downloaderResultImage(error: .INVALID_PARAM, message: invalidUrlError, data: nil)
      guard let url = URL.init(string: imageUrl) else {
         completion(result)
         return
      }
      
      let resource = ImageResource(downloadURL: url)
      KingfisherManager.shared.retrieveImage(with: resource, options: nil, progressBlock: nil) { kfResult in
         switch kfResult {
         case .success(let value):
            log.instance.push(.INFO, msg: "Image: \(value.image ). Got from: \(value.cacheType)")
            result = downloaderResultImage(error: .NONE, message: "", data: value.image as UIImage)
            completion(result)
         case .failure(let error):
            log.instance.push(.INFO, msg: "Error: \(error)")
            result = downloaderResultImage(error: .URL_NOT_FOUND, message: "\(error)", data: nil)
            completion(result)
         }
      }
   }

   private func setTimeout( _ value: TimeInterval ) {
      // Reset our session if the value is different
      let config = self.session.configuration
      if config.timeoutIntervalForResource != value {
         config.timeoutIntervalForResource = value
         self.session = URLSession(configuration: config)
      }
   }
   private func setIsCacheEnabled( _ value: Bool ) {
      // Reset our session if the value is different
      let config = self.session.configuration
      if value && config.requestCachePolicy == .reloadIgnoringLocalCacheData {
         config.requestCachePolicy = .useProtocolCachePolicy
         session = URLSession(configuration: config)
      } else if !value && config.requestCachePolicy != .reloadIgnoringLocalCacheData {
         config.requestCachePolicy = .reloadIgnoringLocalCacheData
         config.urlCache = nil
         self.session = URLSession(configuration: config)
      }
   }
}

import Foundation
import propsyncSwift

internal class platformApis {
   static let VERSION = "1.0.0"

   static func callGamesApi(downloader: httpDownloader,
      entrypoint: String,
      lid: String,
      gid: String) throws -> [String: Any]? {
   
      var returnValue: [String: Any]? = nil
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "games" )
         endpoint.appendPathComponent( gid )

         var queryItems: [URLQueryItem] = []
         queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )

         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try downloader.restfulQueryJson(endpoint: finalUrl.absoluteString)
            }
         }
      }
      return returnValue
   }
   static func callGamesApi(entrypoint: String,
      lid: String,
      gid: String) throws -> propsync? {
      
      var returnValue: propsync? = nil
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "games" )
         endpoint.appendPathComponent( gid )

         var queryItems: [URLQueryItem] = []
         queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )

         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try .init(fromUrl: finalUrl.absoluteString, serializerType: .JSON)
               try returnValue?.open()
               returnValue?.close()
            }
         }
      }
      return returnValue
   }
   static func callPlayersApi(downloader: httpDownloader,
      entrypoint: String,
      lid: String,
      tid: Int? = nil,
      pids: [Int]? = nil ) throws -> [String: Any]? {
      
      var returnValue: [String: Any]? = nil
      
      // Build the query strings
      var queryItems: [URLQueryItem] = []
      queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )
      if let t = tid {
         queryItems.append( URLQueryItem(name: "tid", value: String(t)) )
      }
      else if let p = pids, p.count > 0 {
         var csv = ""
         for pid in p {
            csv.append("\(pid),")
         }
         queryItems.append( URLQueryItem(name: "pids", value: csv) )
      }
      
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "players" )
         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try downloader.restfulQueryJson(endpoint: finalUrl.absoluteString)
            }
         }
      }
      return returnValue
   }
   static func callPlayersApi(entrypoint: String,
      lid: String,
      tid: Int? = nil,
      pids: [Int]? = nil ) throws -> propsync? {
      
      var returnValue: propsync? = nil
      
      // Build the query strings
      var queryItems: [URLQueryItem] = []
      queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )
      if let t = tid {
         queryItems.append( URLQueryItem(name: "tid", value: String(t)) )
      }
      else if let p = pids, p.count > 0 {
         var csv = ""
         for pid in p {
            csv.append("\(pid),")
         }
         queryItems.append( URLQueryItem(name: "pids", value: csv) )
      }
      
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "players" )
         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try .init(fromUrl: finalUrl.absoluteString, serializerType: .JSON)
               try returnValue?.open()
               returnValue?.close()
            }
         }
      }
      return returnValue
   }
   static func callGameChroniclesApi(downloader: httpDownloader,
      entrypoint: String,
      lid: String,
      gid: String,
      eid: Int = 0) throws -> [String: Any]? {
   
      var returnValue: [String: Any]? = nil
      
      // Build the query strings
      var queryItems: [URLQueryItem] = []
      queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )
      queryItems.append( URLQueryItem(name: "eid", value: String(eid)) )
      
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "game-chronicles" )
         endpoint.appendPathComponent( gid )
         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try downloader.restfulQueryJson(endpoint: finalUrl.absoluteString)
            }
         }
      }
      return returnValue
   }
   static func callGameChroniclesApi(entrypoint: String,
      lid: String,
      gid: String,
      eid: Int = 0) throws -> propsync? {
   
      var returnValue: propsync? = nil
      
      // Build the query strings
      var queryItems: [URLQueryItem] = []
      queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )
      queryItems.append( URLQueryItem(name: "eid", value: String(eid)) )
      
      if var endpoint = URL( string: entrypoint ) {
         endpoint.appendPathComponent( lid )
         endpoint.appendPathComponent( "sport-data" )
         endpoint.appendPathComponent( "game-chronicles" )
         endpoint.appendPathComponent( gid )
         if var urlBuilder = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let finalUrl = urlBuilder.url {
               returnValue = try .init(fromUrl: finalUrl.absoluteString, serializerType: .JSON)
               try returnValue?.open()
               returnValue?.close()
            }
         }
      }
      return returnValue
   }
   static func callConnectApi(downloader: httpDownloader,
      entrypoint: String,
      lid: String,
      gid: String? = nil,
      fop: String? = nil,
      intrinsicData: sceneIntrinsic,
      completion: @escaping(trackingUpdate) -> Void) {
      
      // TODO: Is cancelling really necessary? seems like a tough challenge for little gain
      //self.isCancelled = false
      
      // Build the URL
      var queryItems: [URLQueryItem] = []
      queryItems.append( URLQueryItem(name: "version", value: platformApis.VERSION) )
      if let f = fop {
         queryItems.append( URLQueryItem(name: "fop", value: f) )
      }
      
      var endpoint: String = ""
      if var ep = URL( string: entrypoint ) {
         ep.appendPathComponent( lid )
         ep.appendPathComponent( "connect" )
         if let g = gid {
            ep.appendPathComponent( g )
         }
         if var urlBuilder = URLComponents(url: ep, resolvingAgainstBaseURL: false) {
            urlBuilder.queryItems = queryItems
            if let url = urlBuilder.url {
               endpoint = url.absoluteString
            }
         }
      }
      
      // Convert the scene intrinsice to JSON form
      let param : (image: Data, json: Data?) = intrinsicData.serialize()
      if let json = param.json {
      
         // Build a multipart request
         var request: httpMultipartRequest
         do
         {
            request = try httpMultipartRequest( url: endpoint )
         } catch let e {
            let timeStamp = UInt64(Date().timeIntervalSince1970)
            let returnValue = trackingUpdate(error: .INVALID_PARAM,
               errorMsg: "\(e)" ,
               url: endpoint,
               sceneIntrinsic: intrinsicData,
               timestamp: timeStamp )
            completion(returnValue)
            return
         }
         request.append(name: "image", data: param.image)
         request.append(name: "cam.json", data: json)
         
         // POST the request asynchronously
         downloader.restfulQueryJsonAsync(request: request) { response in
            
//            if self.isCancelled {
//               return
//            }
            
            let timeStamp = UInt64(Date().timeIntervalSince1970)
            var returnValue = trackingUpdate( error: response.error,
               errorMsg: "Connect: \(response.message)",
               url: endpoint,
               sceneIntrinsic: intrinsicData,
               timestamp: timeStamp )
            switch response.error {
               case .NONE:
                  // We require these for success
                  if let matrix = response.data["correction"] as? [Double],
                     let confidence = response.data["confidence"]as? Double,
                     let viewPosition = response.data["world_position"] as? [Double],
                     let viewDirection = response.data["world_view_direction"] as? [Double] {
                     
                     returnValue = trackingUpdate( error: ERROR.NONE,
                        errorMsg:"" ,
                        url: endpoint,
                        sceneIntrinsic: intrinsicData,
                        timestamp: timeStamp,
                        transform: matrix,
                        confidenceValue: confidence,
                        viewPosition: viewPosition,
                        viewDirection: viewDirection )
                  } else {
                     returnValue = trackingUpdate( error: .TRACKING,
                     errorMsg: invalidcorrectionMatrix,
                     url: endpoint,
                     sceneIntrinsic: intrinsicData,
                     timestamp: timeStamp )
                  }
               case .HTTP:
                  if let errorvalue = response.data["error"] as? String,
                     let errorCode = response.data["errorCode"] as? String,
                     let numberOfFeatures = response.data["numberOfFeatures"] as? Int,
                     let numberOfMatches = response.data["numberOfMatches"] as? Int,
                     let numberOfVisible3DPoints = response.data["numberOfVisible3DPoints"] as? Int {
                     
                     let registrationError = registrationError( error: errorvalue,
                        errorCode: errorCode,
                        numberOfFeatures: numberOfFeatures,
                        numberOfMatches: numberOfMatches,
                        numberOfVisible3DPoints: numberOfVisible3DPoints )
                     returnValue = trackingUpdate(error: response.error,
                        errorMsg:"" ,
                        url: endpoint,
                        sceneIntrinsic: intrinsicData,
                        timestamp: timeStamp,
                        registrationError: registrationError )
                  }
               default: break
            }
            
            // Make the callback
            completion(returnValue)
         }
      } else {
         let timeStamp = UInt64(Date().timeIntervalSince1970)
         let registrationResult = trackingUpdate(error: ERROR.TRACKING,
            errorMsg: failedTempTracking,
            url: endpoint,
            sceneIntrinsic: intrinsicData,
            timestamp: timeStamp )
         completion(registrationResult)
      }
   }
}

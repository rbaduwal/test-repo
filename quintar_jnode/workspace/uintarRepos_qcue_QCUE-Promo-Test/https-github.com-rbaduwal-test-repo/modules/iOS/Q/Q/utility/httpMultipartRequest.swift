import Foundation

public class httpMultipartRequest {

   // Boundary string for multipart HTTP requests
   public var boundaryString: String {
      get {
         if _boundaryString == "" {
            let first = UInt32.random(in: UInt32.min...UInt32.max)
            let second = UInt32.random(in: UInt32.min...UInt32.max)

            _boundaryString = String(format: "Q.reality.%08x%08x", first, second)
         }
         return _boundaryString
      }
      set {
         _boundaryString = newValue
      }
   }
   public var urlRequest: URLRequest
   
   private var _boundaryString: String = ""
   private var _isFinalized = false
   private var _data: Data = Data()
   private var _numParts = 0
   
   public init(url: String, httpMethod: String = "POST") throws {
      guard let finalUrl = URL(string: url) else {
         throw errorWithMessage("Invalid URL: '\(url)'")
      }
      
      urlRequest = URLRequest(url: finalUrl)
      urlRequest.httpMethod = httpMethod
      urlRequest.setValue("multipart/form-data; boundary=\(boundaryString)", forHTTPHeaderField: "Content-Type")
      
      self._data.append(beginMultiPart())
   }
   public func finalize() {
      if !_isFinalized {
         self._data.append(endMultiPart())
         urlRequest.httpBody = self._data
         _isFinalized = true
      }
   }
   public func append(name: String,
      contentType: String? = nil,
      data: Data? = nil) {
      
      if let d = data {
         var appendBoundaryString = ""
         if _numParts > 0 {
            appendBoundaryString = "\r\n--\(self.boundaryString)\r\n"
         }
         
         let contentHeaderString = "Content-Disposition: form-data; name=\"\(name)\"\r\n"
         
         var contentTypeString: String
         if let ct = contentType {
            contentTypeString = "Content-Type: \(ct)\r\n\r\n"
         } else {
            contentTypeString = "Content-Type: application/octet-stream\r\n\r\n"
         }
         
         // Build our return value, header-first
         _data.append( Data((appendBoundaryString + contentHeaderString + contentTypeString).utf8) )

         // Add the data
         _data.append(d)
         
         _numParts += 1
      }
   }
   
   private func beginMultiPart() -> Data {
      let initBoundaryString = "--\(self.boundaryString)\r\n"
      return Data(initBoundaryString.utf8)
   }
   private func endMultiPart() -> Data {
      let endBoundaryString = "\r\n--\(self.boundaryString)--\r\n"
      return Data(endBoundaryString.utf8)
   }
}

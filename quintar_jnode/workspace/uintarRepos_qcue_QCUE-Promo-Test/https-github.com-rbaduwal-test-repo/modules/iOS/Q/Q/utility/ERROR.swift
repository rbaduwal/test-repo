public enum ERROR: Equatable {
   case NONE
   case INVALID_PARAM
   case HTTP(_ responseCode: Int)
   case PARSE
   case TRACKING
   case TRACKING_RESET
   case TRACKING_DEVICE_NOT_READY
   case LOCATION
   case URL_NOT_FOUND
   case INIT
   case NETWORK_ERROR
   case UNKNOWN_ERROR
   
   static public func ==(lhs: ERROR, rhs: ERROR) -> Bool {
      switch (lhs, rhs) {
         case (.NONE, .NONE): return true
         case (.INVALID_PARAM, .INVALID_PARAM): return true
         case (.HTTP, .HTTP): return true
         case (.PARSE, .PARSE): return true
         case (.TRACKING, .TRACKING): return true
         case (.TRACKING_RESET, .TRACKING_RESET): return true
         case (.TRACKING_DEVICE_NOT_READY, .TRACKING_DEVICE_NOT_READY): return true
         case (.URL_NOT_FOUND, .URL_NOT_FOUND): return true
         case (.INIT, .INIT): return true
         case (.NETWORK_ERROR, .NETWORK_ERROR): return true
         case (.UNKNOWN_ERROR, .UNKNOWN_ERROR): return true
         default: return false
      }
   }
}

public enum SERVER_ERRORCODE: Int {
   case UNAUTHORIZED = 401
   case FORBIDDEN = 403
   case INTERNAL_SERVER_ERROR = 500
   case NOTFOUND = 404
   case CONFLICT = 409
   case NOINTERNET = -1009
   case NOT_CONNECTED = -1020
   case UNKNOWN
   
   func initError() -> Int {
       self.rawValue
   }
}

public struct errorWithMessage: Error {
   let message: String
   
   public init(_ message: String) {
      self.message = message
   }
   
   public var localizedDescription: String {
      return message
   }
}

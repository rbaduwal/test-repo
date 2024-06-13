// These help with unit testing but are not tests themselves.
// These are also things I do not want available in the SDK, so they live here

import Q

class testHelper {
   static func createArUiViewConfigSynchronous(URL: String) throws -> arUiViewConfig? {
      var returnValue: arUiViewConfig? = nil
      var exception: errorWithMessage? = nil
      let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
      arUiViewConfig.create(url: arUiViewConfigUrl) { result in
         switch result.error {
            case .NONE:
               returnValue = result.config as? arUiViewConfig
            default:
               exception = errorWithMessage(result.errorMsg)
         }
         semaphore.signal()
      }
      semaphore.wait()
      
      if let ex = exception {
         throw ex
      }
      return returnValue
   } 
}

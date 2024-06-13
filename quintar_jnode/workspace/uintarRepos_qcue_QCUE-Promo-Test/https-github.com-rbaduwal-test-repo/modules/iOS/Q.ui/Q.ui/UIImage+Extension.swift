import Foundation
import UIKit
import Q

public extension UIImage {
   // Asynchronously download the image.
   // Completion is guaranteed to execute on the main thread, making this function UI-safe
   static func fromUrl( url: String, downloader: Q.httpDownloader, completion: @escaping ((UIImage?)->()) ) {      
      downloader.getImageAsync( url, completion: { result in
         var returnValue: UIImage? = nil
         switch result.error {
            case .NONE: if let image = result.data { returnValue = image }
            default: break
         }
         
         DispatchQueue.main.async {
            completion(returnValue)
         }
      })
   }
}

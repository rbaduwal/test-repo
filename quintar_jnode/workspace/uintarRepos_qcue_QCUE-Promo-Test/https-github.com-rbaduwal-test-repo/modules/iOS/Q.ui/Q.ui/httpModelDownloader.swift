import Q

public class httpModelDownloader: Q.httpDownloader, modelDownloader {
   
   public func getModelAsync(_ modelUrl: String, completion: @escaping (downloaderResultModel) -> ()) {
      
      var result = downloaderResultModel(error: .INVALID_PARAM, message: invalidUrlError, data: nil)
      
      guard let url = URL(string: modelUrl) else {
         completion(result)
         return
      }
      
      // RealityKit doesn't directly support downloading model files (.usdz or .reality) over HTTP into application memory.
      // Instead, you have to first download the model to a directory, then load from file
      // TODO: We should consider a file management scheme since we are downloading persistent files to the device!
      
      // Download the file, then load as a RealityKit.Entity
      if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
         let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
         let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            if error == nil {
               if let response = response as? HTTPURLResponse {
                  if response.statusCode == 200 {
                     if let data = data {
                        if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                           
                           // The file has been saved, now load into an Entity
                           DispatchQueue.main.sync {
                              do {
                                 let model = try qEntity.loadModel(contentsOf: destinationUrl)
                                 result = downloaderResultModel(error: .NONE, message: "", data: model)
                              } catch {
                                 result = downloaderResultModel(error: .PARSE, message: "\(error)", data: nil )
                              }
                              completion(result)
                           }
                           return
                        }
                     }
                  }
               }
            }
            completion(result)
         })
         task.resume()
      } else {
         result = downloaderResultModel(error: .INVALID_PARAM, message: documentDirNotFound, data: nil)
         completion(result)
         return
      }
   }
}

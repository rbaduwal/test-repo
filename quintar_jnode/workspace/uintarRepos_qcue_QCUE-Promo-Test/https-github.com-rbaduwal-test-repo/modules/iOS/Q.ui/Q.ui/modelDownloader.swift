import Q

public typealias downloaderResultModel = Q.downloaderResult<qEntity?>

public protocol modelDownloader: Q.downloader {
   
   // TL;DR - synchronouse version of getModel doesn't work.
   // Creating a visual entity requires access to the main thread, but we should not block the main thread
   // for such long operations as this. Also, there is a chance of deadlocking if this is called from the main thread.
   // So instead of trying to hack around it, just use the async version for models.
   //func getModel(_ modelUrl: String) -> downloaderResultModel
   
   func getModelAsync(_ modelUrl: String, completion: @escaping (downloaderResultModel) -> ())
}

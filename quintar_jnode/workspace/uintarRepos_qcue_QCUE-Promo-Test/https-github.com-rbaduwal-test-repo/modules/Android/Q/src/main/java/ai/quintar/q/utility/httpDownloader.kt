package ai.quintar.q.utility

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking

@Suppress("ClassName") class httpDownloader : downloader {
   override fun getJson(jsonUrl: String): downloaderJsonResult {
      val json = runBlocking {
         httpHelper.getJson(jsonUrl)
      }
      return json
   }

   override fun getJsonAsync(jsonUrl: String, completion: (d: downloaderJsonResult) -> Unit) {
      CoroutineScope(Dispatchers.IO).launch(Dispatchers.IO) {
         val data = getJson(jsonUrl)
         completion(data)
      }
   }

   override fun getImageAsync(jsonUrl: String, completion: (d: downloadImageResult) -> Unit) {
      val imageBitmap = runBlocking {
         httpHelper.getTestImage(jsonUrl)
      }
      completion(downloadImageResult(ERROR.NONE, "", imageBitmap))
   }
}
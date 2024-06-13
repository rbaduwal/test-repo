package ai.quintar.q.utility

import android.graphics.Bitmap
import org.json.JSONObject

@Suppress("ClassName") interface downloader {
   fun getJson(jsonUrl: String): downloaderJsonResult
   fun getJsonAsync(jsonUrl: String, completion: (d: downloaderJsonResult) -> Unit)
   fun getImageAsync(jsonUrl: String, completion: (d: downloadImageResult) -> Unit)
}
@Suppress("ClassName") class downloaderJsonResult(error: ERROR,
   errorMsg: String,
   result: JSONObject) : Exception(errorMsg) {
   var error: ERROR = error
      private set
   var errorMsg: String = errorMsg
      private set
   var result: JSONObject = result
      private set
}
@Suppress("ClassName") class downloadImageResult(error: ERROR,
   errorMsg: String,
   result: Bitmap?) : Exception(errorMsg) {
   var error: ERROR = error
      private set
   var errorMsg: String = errorMsg
      private set
   var result: Bitmap? = result
      private set
}
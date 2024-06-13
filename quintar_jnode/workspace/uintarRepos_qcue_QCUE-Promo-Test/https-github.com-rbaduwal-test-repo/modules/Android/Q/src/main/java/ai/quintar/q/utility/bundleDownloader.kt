package ai.quintar.q.utility

import ai.quintar.q.utility.errorMessages.Companion.failedToGetImage
import ai.quintar.q.utility.errorMessages.Companion.fileNotFound
import ai.quintar.q.utility.errorMessages.Companion.parseError
import android.content.Context
import android.graphics.BitmapFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.lang.ref.WeakReference

@Suppress("ClassName") class bundleDownloader(context: Context) : downloader {
   private var context: WeakReference<Context> = WeakReference(context.applicationContext)
   @Throws(downloaderJsonResult::class) override fun getJson(jsonUrl: String):
      downloaderJsonResult {
      try {
         val jsonString = context.get()?.assets?.open(jsonUrl)?.bufferedReader().use { it?.readText() } ?: ""
         try {
            val jsonAsObject = JSONObject(jsonString)
            return downloaderJsonResult(ERROR.NONE, "", jsonAsObject)
         } catch (e: Exception) {
            throw downloaderJsonResult(ERROR.PARSE, "$parseError $jsonUrl", JSONObject())
         }
      } catch (downloaderException: downloaderJsonResult) {
         throw downloaderException
      } catch (exception: Exception) {
         throw downloaderJsonResult(ERROR.INVALID_PARAM, "$jsonUrl $fileNotFound", JSONObject())
      }
   }

   override fun getJsonAsync(jsonUrl: String, completion: (d: downloaderJsonResult) -> Unit) {
      CoroutineScope(Dispatchers.IO).launch(Dispatchers.IO) {
         try {
            completion(getJson(jsonUrl))
         } catch (exception: downloaderJsonResult) {
            completion(exception)
         }
      }
   }

   override fun getImageAsync(jsonUrl: String, completion: (d: downloadImageResult) -> Unit) {
      try {
         val stream = context.get()?.assets?.open(jsonUrl)
         val bitmap = BitmapFactory.decodeStream(stream)
         val download = downloadImageResult(ERROR.NONE, "", bitmap)
         completion(download)
      } catch (e: Exception) {
         val download = downloadImageResult(ERROR.INVALID_PARAM, failedToGetImage, null)
         completion(download)
      }
   }
}
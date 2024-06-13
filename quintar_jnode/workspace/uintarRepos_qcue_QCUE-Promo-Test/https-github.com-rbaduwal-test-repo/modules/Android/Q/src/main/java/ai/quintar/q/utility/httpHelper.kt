package ai.quintar.q.utility

import ai.quintar.q.connect.sceneIntrinsic
import ai.quintar.q.connect.trackingUpdate
import ai.quintar.q.utility.errorMessages.Companion.invalidConfidenceValue
import ai.quintar.q.utility.errorMessages.Companion.invalidCorrectionMatrix
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

@Suppress("ClassName")
class httpHelper {
   companion object {
      val apiInterface = qPlatformApiHelper.getInstance().create(qPlatformApiInterface::class.java)

      suspend fun register(
         url: String, sceneIntrinsic: sceneIntrinsic, completion: (trackingUpdate) -> Unit
      ) {
         try {
            val imageRequestBody = sceneIntrinsic.image.toRequestBody("image/*".toMediaTypeOrNull())
            val imageMultipartBody = MultipartBody.Part.createFormData(
               "image", "image", imageRequestBody
            )
            val jsonRequestBody =
               sceneIntrinsic.toServerFormat().toRequestBody("*/*".toMediaTypeOrNull())
            val jsonMultipartBody = MultipartBody.Part.createFormData(
               "cam.json", "cam.json", jsonRequestBody
            )
            val result = apiInterface.postRegistration(url, imageMultipartBody, jsonMultipartBody)
            if (result.isSuccessful) {
               val trackingUpdateModel = result.body()
               val trackingUpdate: trackingUpdate = when {
                  trackingUpdateModel?.correction == null -> {
                     trackingUpdate(
                        ERROR.REGISTRATION,
                        invalidCorrectionMatrix,
                        url,
                        null,
                        sceneIntrinsic,
                        System.currentTimeMillis(),
                        null,
                        null,
                        null,
                        null
                     )
                  }
                  trackingUpdateModel.confidence == null -> {
                     trackingUpdate(
                        ERROR.REGISTRATION,
                        invalidConfidenceValue,
                        url,
                        null,
                        sceneIntrinsic,
                        System.currentTimeMillis(),
                        null,
                        null,
                        null,
                        null
                     )
                  }
                  else -> {
                     trackingUpdate(
                        ERROR.NONE,
                        "",
                        url,
                        trackingUpdateModel.correction,
                        sceneIntrinsic,
                        System.currentTimeMillis(),
                        trackingUpdateModel.confidence,
                        trackingUpdateModel.world_position,
                        trackingUpdateModel.world_view_direction,
                        null
                     )
                  }
               }
               completion(trackingUpdate)
            } else if (result.code() == 418) {
               //capturing errorbody if response code is 418. Error body is pass to
               // venue.kt to do out of the arena condition
               val errorConditions = result.errorBody()?.string()
               errorConditions?.let {
                  val mTrackingUpdates: trackingUpdate = trackingUpdate(
                     ERROR.ERROR_CONDITION,
                     "",
                     "",
                     null,
                     sceneIntrinsic,
                     System.currentTimeMillis(),
                     null,
                     null,
                     null,
                     errorConditions
                  )
                  completion(mTrackingUpdates)
               }
            }

         } catch (e: Exception) {
               val mTrackingUpdates: trackingUpdate = trackingUpdate(
                  ERROR.CONNECTION,
                  "",
                  "",
                  null,
                  sceneIntrinsic,
                  System.currentTimeMillis(),
                  null,
                  null,
                  null,
                  null
               )
               completion(mTrackingUpdates)
         }
      }

      suspend fun getJson(
         url: String
      ): downloaderJsonResult {
         return try {
            val result = apiInterface.getJson(url)
            if (result.isSuccessful) {
               downloaderJsonResult(ERROR.NONE, "", JSONObject(result.body().toString()))
            } else {
               downloaderJsonResult(ERROR.PARSE, "", JSONObject(result.errorBody().toString()))
            }
         } catch (e: Exception) {
            Log.d("downloaderJsonResult", e.message.toString())
            downloaderJsonResult(ERROR.CONNECTION, "", JSONObject())
         }
      }

      suspend fun getTestImage(
         url: String
      ): Bitmap? {
         try {
            val result = apiInterface.getTestImage(url)
            return if (result.isSuccessful) {
               result.body()?.let {
                  return BitmapFactory.decodeStream(result.body()?.byteStream())
               }
            } else {
               return null
            }
         } catch (e: Exception) {
            return null
         }
      }
   }
}
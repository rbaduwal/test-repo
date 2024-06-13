package ai.quintar.q.utility

import com.google.gson.JsonElement
import okhttp3.MultipartBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

@Suppress("ClassName") interface qPlatformApiInterface {
   @Multipart @POST suspend fun postRegistration(@Url url: String,
      @Part image: MultipartBody.Part,
      @Part jsonFile: MultipartBody.Part): Response<trackingUpdateModel>
   @GET suspend fun getJson(@Url url: String): Response<JsonElement>
   @GET suspend fun getTestImage(@Url url: String): Response<ResponseBody>
}
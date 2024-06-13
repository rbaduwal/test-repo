@file:Suppress("ClassName")

package ai.quintar.q.utility

import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object qPlatformApiHelper {
   val baseUrl = "http://default"
   val okHttpClient: OkHttpClient = OkHttpClient.Builder().readTimeout(300,
         TimeUnit.SECONDS).writeTimeout(300, TimeUnit.SECONDS).connectTimeout(300,
         TimeUnit.SECONDS).build()

   fun getInstance(): Retrofit {
      return Retrofit.Builder().baseUrl(baseUrl).addConverterFactory(GsonConverterFactory.create
         ()).client(
            okHttpClient).build()
   }
}
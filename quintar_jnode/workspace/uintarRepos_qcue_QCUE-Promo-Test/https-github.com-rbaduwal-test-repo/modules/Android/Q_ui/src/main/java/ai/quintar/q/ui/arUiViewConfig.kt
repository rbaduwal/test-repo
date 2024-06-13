@file:Suppress("ArrayInDataClass")

package ai.quintar.q.ui

import ai.quintar.q.config.*
import ai.quintar.q.utility.*
import com.google.gson.Gson
import org.json.JSONObject

@Suppress("ClassName") class arUiViewConfig : config {
   override var url: String = ""
      private set
   override var timeout: Int = 200
      private set
   override var data: JSONObject = JSONObject()
      private set
   override var testData: JSONObject = JSONObject()
      private set
   override var testEnabled: Boolean = true
   override var downloader: downloader? = null
   var arConfig: bbConfig? = null
      private set
   private val gson = Gson()
   lateinit var updated: (configUpdate) -> (Unit)
   var experience: EXPERIENCE? = null
      private set
   var sport: SPORT? = SPORT.UNKNOWN
      private set
   var connectConfig: connectConfig? = null
   var sportconfig: sportConfig? = null
      private set
   private var error: ERROR = ERROR.NONE

   constructor(data: JSONObject) {
      this.processData(data)
   }

   constructor(url: String, update: (d: configUpdate) -> Unit) {
      this.url = url
      this.updated = update
      this.downloader = httpDownloader()
      downloader?.getJsonAsync(url) {
         if (it.error == ERROR.NONE) {
            this.processData(it.result)
         } else {
            val configUpdate = configUpdate(it.error, it.errorMsg, this.url, this.data, this)
            this.updated(configUpdate)
            return@getJsonAsync
         }
      }
   }

   private fun processData(data: JSONObject) {
      arConfig = gson.fromJson(data.toString(), bbConfig::class.java)
      this.testData = getTestData(arConfig)
      val oldData = data
      this.data = data
      parseData()
      if (!arConfig?.connect?.configUrl.isNullOrEmpty()) {
         this.connectConfig = arConfig?.connect?.configUrl?.let { requestUrl ->
            this.downloader?.let { downloader ->
               connectConfig(requestUrl, downloader) {
                  if (!arConfig?.sportData?.configUrl.isNullOrEmpty()) {
                     this.sportconfig = arConfig?.sportData?.configUrl?.let { requestUrl ->
                        this.downloader?.let { downloader ->
                           sportConfig(requestUrl, downloader) {
                              val configUpdate = configUpdate(ERROR.NONE, "", url, oldData, this)
                              this.updated(configUpdate)
                           }
                        }
                     }
                  } else {
                     this.sportconfig = sportConfig(arConfig?.sportData)
                  }
               }
            }
         }
      } else {
         this.connectConfig = connectConfig(arConfig?.connect)
      }

   }

   fun getGameDataUrl(): String? {
      sportconfig?.sportDataConfigData?.let { sportsUrl ->
         return sportsUrl.apiEntrypointUrl + "/" + sportsUrl.lid + "/sport-data/games/" + sportsUrl.gid
      }
      return null
   }

   fun getGameChronicleDataUrl(): String? {
      sportconfig?.sportDataConfigData?.let { sportsUrl ->
         return sportsUrl.apiEntrypointUrl + "/" + sportsUrl.lid + "/sport-data/game-chronicles/" + sportsUrl.gid
      }
      return null
   }

   private fun parseData() {
      val sports = arConfig?.arUiView?.sport
      val experienceType = arConfig?.arUiView?.experiences?.get(0)?.type
      when {
         experienceType?.equals(EXPERIENCE.HOME.value) == true && sports?.equals(SPORT.GOLF
            .value) == true -> {
            this.experience = EXPERIENCE.HOME
            this.sport = SPORT.GOLF
         }
         experienceType?.equals(EXPERIENCE.HOME.value) == true && sports?.equals(SPORT.BASKETBALL
            .value) == true -> {
            this.experience = EXPERIENCE.HOME
            this.sport = SPORT.BASKETBALL
         }
         experienceType?.equals(EXPERIENCE.VENUE.value) == true && sports?.equals(SPORT.GOLF
            .value) == true -> {
            this.experience = EXPERIENCE.VENUE
            this.sport = SPORT.GOLF
         }
         experienceType?.equals(EXPERIENCE.VENUE.value) == true && sports?.equals(SPORT
            .BASKETBALL.value) == true -> {
            this.experience = EXPERIENCE.VENUE
            this.sport = SPORT.BASKETBALL
         }
      }
      constants.NO_NETWORK_DESCRIPTION= arConfig?.arUiView?.experiences?.get(0)?.networkErrorMessage?.description.toString()
      constants.NO_NETWORK_TITLE= arConfig?.arUiView?.experiences?.get(0)?.networkErrorMessage?.title.toString()
      this.error = ERROR.NONE
   }

   private fun getTestData(data: bbConfig?): JSONObject {
      val debugData = data?.test
      debugData?.let {
         return JSONObject(gson.toJson(debugData))
      }
      return JSONObject()
   }
}
@file:Suppress("ArrayInDataClass")

package ai.quintar.q.config

import ai.quintar.q.utility.ERROR
import ai.quintar.q.utility.constants.Companion.TIMEOUT
import ai.quintar.q.utility.downloader
import ai.quintar.q.utility.errorMessages.Companion.failedToDeserialize
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import org.json.JSONObject

@Suppress("ClassName") class connectConfig() : config {
   override var url: String = ""
      private set
   override var timeout: Int = TIMEOUT
      private set
   override var data: JSONObject = JSONObject()
      private set
   override var testData: JSONObject = JSONObject()
      private set
   override var testEnabled: Boolean = true
   override var downloader: downloader? = null
   private var updated: ((configUpdate) -> Unit)? = null
   var connectConfigData: connect? = null
   private var oldData = JSONObject()

   constructor(data: connect?) : this() {
      this.connectConfigData = data
      this.updated?.let { onConfigUpdate ->
         val configUpdate = configUpdate(ERROR.NONE, "", this.url, this.oldData, this)
         onConfigUpdate(configUpdate)
      }
   }

   constructor(url: String, downloader: downloader, completion: (configUpdate) -> Unit) : this() {
      this.url = url
      this.updated = completion
      this.downloader = downloader

      this.downloader?.getJsonAsync(url) {
         if (it.error == ERROR.NONE) {
            this.oldData = this.data
            this.processData(it.result)
         } else {
            val configUpdate = configUpdate(it.error, it.errorMsg, url, this.oldData, this)
            this.updated?.let { onConfigUpdate ->
               onConfigUpdate(configUpdate)
            }
         }
      }
   }

   private fun processData(data: JSONObject) {
      try {
         parseConfigData(data)
         this.updated?.let { onConfigUpdate ->
            val configUpdate = configUpdate(ERROR.NONE, "", this.url, this.oldData, this)
            onConfigUpdate(configUpdate)
         }
      } catch (exception: Exception) {
         this.updated?.let { onConfigUpdate ->
            val configUpdate = configUpdate(ERROR.PARSE,
               failedToDeserialize,
               this.url,
               this.oldData,
               this)
            onConfigUpdate(configUpdate)
         }
      }
   }
   @Throws(JsonSyntaxException::class) private fun parseConfigData(data: JSONObject) {
      val gson = Gson()
      this.connectConfigData = gson.fromJson(data.toString(), connect::class.java)
   }

   fun getFop(forId: String?): fopsValue {
      this.connectConfigData?.let { connect ->
         for (fop in connect.fops) {
            if (fop.id == forId) {
               return fop
            }
         }
      }
      return fopsValue()
   }
}
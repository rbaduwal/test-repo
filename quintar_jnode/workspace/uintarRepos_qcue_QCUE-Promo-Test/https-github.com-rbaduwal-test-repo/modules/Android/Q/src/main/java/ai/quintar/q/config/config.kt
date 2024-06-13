package ai.quintar.q.config

import ai.quintar.q.utility.ERROR
import ai.quintar.q.utility.downloader
import org.json.JSONObject

@Suppress("ClassName") interface config {
   val url: String
   val timeout: Int
   val data: JSONObject
   val testData: JSONObject
   var testEnabled: Boolean
   var downloader: downloader?
}
@Suppress("ClassName") data class configUpdate(var error: ERROR,
   var error_msg: String,
   var url: String,
   var oldJson: JSONObject,
   var config: config)

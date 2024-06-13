package ai.quintar.q.utility

import com.google.gson.annotations.SerializedName

data class errorConditions(@SerializedName("error") var error: String? = null,
   @SerializedName("errorCode") var errorCode: String? = null,
   @SerializedName("numberOfFeatures") var numberOfFeatures: Int? = null,
   @SerializedName("numberOfMatches") var numberOfMatches: Int? = null,
   @SerializedName("numberOfVisible3DPoints") var numberOfVisible3DPoints: Int? = null)
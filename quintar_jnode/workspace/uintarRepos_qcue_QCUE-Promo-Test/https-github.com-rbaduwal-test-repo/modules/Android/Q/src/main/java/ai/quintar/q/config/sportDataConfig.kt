package ai.quintar.q.config

import com.google.gson.annotations.SerializedName

//TODO: check sportDataConfig class and necessity of this.
data class sportDataConfig(@SerializedName("lid") var leagueId: String? = null,
   @SerializedName("gid") var gameId: String? = null,
   @SerializedName("liveDataUrl") var liveDataUrl: String? = null,
   @SerializedName("archiveDataUrl") var archiveDataUrl: String? = null,
   @SerializedName("isLive") var isLive: Boolean? = null,
   @SerializedName("test") var test: String? = null,
   @SerializedName("apiEntrypointUrl") var apiEntrypointUrl: String? = null)

data class bbConfig(@SerializedName("arUiView") var arUiView: arUiView? = arUiView(),
   @SerializedName("connect") var connect: connect? = connect(),
   @SerializedName("sportData") var sportData: sportData? = sportData(),
   @SerializedName("test") var test: test? = test()) {
   val homeTeamColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.trail?.color
      }
   val awayTeamColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.trail?.color
      }
   val homeTeamRadius: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.trail?.radius?.toFloat()
      }
   val awayTeamRadius: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.trail?.radius?.toFloat()
      }
   val homeTeamAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.trail?.opacity?.toFloat()
      }
   val awayTeamAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.trail?.opacity?.toFloat()
      }
   val homeTeamShotSuccessColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileSuccess?.color
      }
   val homeTeamShotAttemptColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileAttempt?.color
      }
   val awayTeamShotSuccessColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileSuccess?.color
      }
   val awayTeamShotAttemptColor: String?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileAttempt?.color
      }
   val homeTeamShotSuccessAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileSuccess?.opacity?.toFloat()
      }
   val homeTeamShotAttemptAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileAttempt?.opacity?.toFloat()
      }
   val awayTeamShotSuccessAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileSuccess?.opacity?.toFloat()
      }
   val awayTeamShotAttemptAlpha: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileAttempt?.opacity?.toFloat()
      }
   val homeTeamShotSuccessScale: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileSuccess?.scale?.toFloat()
      }
   val homeTeamShotAttemptScale: Float?
      get() {
         return arUiView?.experiences?.get(0)?.homeTeamShot?.floorTileAttempt?.scale?.toFloat()
      }
   val awayTeamShotSuccessScale: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileSuccess?.scale?.toFloat()
      }
   val awayTeamShotAttemptScale: Float?
      get() {
         return arUiView?.experiences?.get(0)?.awayTeamShot?.floorTileAttempt?.scale?.toFloat()
      }
   val heatmapConfig: ArrayList<colors>?
      get() {
         return arUiView?.experiences?.get(0)?.heatmap?.colors
      }
   val heatmapBoardPositionA: ArrayList<Float>?
      get() {
         return arUiView?.experiences?.get(0)?.leaderBoardConfigurables?.leaderBoardPositions?.homeTeamA
      }
   val heatmapBoardPositionB: ArrayList<Float>?
      get() {
         return arUiView?.experiences?.get(0)?.leaderBoardConfigurables?.leaderBoardPositions?.awayTeamA
      }
   val apiCallDelay: Int?
      get() {
         return arUiView?.experiences?.get(0)?.apiCallFrequency
      }
   val shotTrailAnimationDelay: Float?
      get() {
         return arUiView?.experiences?.get(0)?.shotTrailAnimationDelay
      }
   val courtsideBoardDistanceFromCamera: Int?
      get() {
         return arUiView?.experiences?.get(0)?.leaderBoardConfigurables?.distanceFromCamera
      }
   val zoomAnimationDelay: Int?
      get() {
         return arUiView?.experiences?.get(0)?.zoomAnimationDelay
      }
   val getArUIPermissionErrorMessage: String?
      get() {
         return arUiView?.experiences?.get(0)?.arUIPermissionErrorMessage
      }
   val outlineAnimationDelay: Int?
      get() {
         return arUiView?.experiences?.get(0)?.outlineAnimationDelay
      }
}

data class arUiView(@SerializedName("sport") var sport: String? = null,
   @SerializedName("experiences") var experiences: ArrayList<Experiences> = arrayListOf())
data class Experiences(@SerializedName("apiCallFrequency") var apiCallFrequency: Int = 0,
   @SerializedName("shotTrailAnimationDelay") var shotTrailAnimationDelay: Float = 0.05f,
   @SerializedName("zoomAnimationDelay") var zoomAnimationDelay: Int = 500,
   @SerializedName("type") var type: String? = null,
   @SerializedName("heatmap") var heatmap: heatmap? = heatmap(),
   @SerializedName("registrationFailureInterval") var registrationFailureInterval: Int = 3,
   @SerializedName("homeTeamShot") var homeTeamShot: homeTeamShot? = homeTeamShot(),
   @SerializedName("awayTeamShot") var awayTeamShot: awayTeamShot? = awayTeamShot(),
   @SerializedName("arUIPermissionErrorMessage") var arUIPermissionErrorMessage:String? = null,
   @SerializedName("networkErrorMessage") var networkErrorMessage: networkErrorMessage? =
      networkErrorMessage(),
   @SerializedName("leaderBoardConfigurables") var leaderBoardConfigurables:
   leaderBoardConfigurables? = leaderBoardConfigurables(),
   @SerializedName("playerCardConfigurables") var playerCardConfigurables:
   playerCardConfigurables? = playerCardConfigurables(),
   @SerializedName("outlineAnimationDelay") var outlineAnimationDelay: Int = 1000)

data class playerCardConfigurables(
   @SerializedName("distanceFromCamera") var distanceFromCamera: Int = 0,
   @SerializedName("endTitle") var endTitle: String? = null,
   @SerializedName("nameSize") var nameSize: Double = 0.0,
   @SerializedName("shotTypeSize") var shotTypeSize: Double = 0.0,
   @SerializedName("successAttemptSize") var successAttemptSize: Double = 4.0,
   @SerializedName("endTitleSize") var endTitleSize: Double = 0.0,
   @SerializedName("scrSize") var scrSize: Double = 0.0,
   @SerializedName("backgroundColor") var backgroundColor: String? = null,
   @SerializedName("backgroundOpacity") var backgroundOpacity: Double = 0.0,
   @SerializedName("playerColors") var colors: playercardColors? = playercardColors(),
   @SerializedName("playerCardPositions") var playerCardPositions: positions? = positions(),
)

data class playercardColors(@SerializedName("homeTeam") var homeTeam: playercardHomeTeam? = playercardHomeTeam(),
   @SerializedName("awayTeam") var awayTeam: playercardAwayTeam? = playercardAwayTeam())

data class playercardHomeTeam(@SerializedName("name") var name: String? = null,
   @SerializedName("shotType") var shotType: String? = null,
   @SerializedName("shotTypeBackground") var shotTypeBackground: String? = null,
   @SerializedName("success") var success: String? = null,
   @SerializedName("attempt") var attempt: String? = null,
   @SerializedName("attemptOpacity") var attemptOpacity: Double? = 0.0,
   @SerializedName("endTitle") var endTitle: String? = null,
   @SerializedName("highlight") var highlight: String? = null,
   @SerializedName("scr") var scr: String? = null)

data class playercardAwayTeam(@SerializedName("name") var name: String? = null,
   @SerializedName("shotType") var shotType: String? = null,
   @SerializedName("shotTypeBackground") var shotTypeBackground: String? = null,
   @SerializedName("success") var success: String? = null,
   @SerializedName("attempt") var attempt: String? = null,
   @SerializedName("attemptOpacity") var attemptOpacity: Double? = 0.0,
   @SerializedName("endTitle") var endTitle: String? = null,
   @SerializedName("highlight") var highlight: String? = null,
   @SerializedName("scr") var scr: String? = null)

data class positions(@SerializedName("HomeTeamA") var homeTeamA: ArrayList<Float> = arrayListOf(),
   @SerializedName("HomeTeamB") var homeTeamB: ArrayList<Float> = arrayListOf(),
   @SerializedName("AwayTeamA") var awayTeamA: ArrayList<Float> = arrayListOf(),
   @SerializedName("AwayTeamB") var awayTeamB: ArrayList<Float> = arrayListOf())

data class leaderBoardConfigurables(@SerializedName("distanceFromCamera") var distanceFromCamera: Int = 0,
   @SerializedName("backgroundColor") var backgroundColor: String? = null,
   @SerializedName("opacity") var opacity: Double = 0.0,
   @SerializedName("endTitle") var endTitle: String? = null,
   @SerializedName("titleSize") var titleSize: Double = 0.0,
   @SerializedName("nameSize") var nameSize: Double = 0.0,
   @SerializedName("scrSize") var scrSize: Double = 0.0,
   @SerializedName("colors") var colors: leaderBoardColours? = leaderBoardColours(),
   @SerializedName("leaderBoardPositions") var leaderBoardPositions: positions? = positions())

data class awayTeam(@SerializedName("highlight") var highlight: String? = null,
   @SerializedName("name") var name: String? = null,
   @SerializedName("scr") var scr: String? = null,
   @SerializedName("titleBackground") var titleBackground: String? = null,
   @SerializedName("title") var title: String? = null,
   @SerializedName("underscore") var underscore: String? = null,
   @SerializedName("underscoreOpacity") var underscoreOpacity: Double? = null)

data class hometeam(@SerializedName("highlight") var highlight: String? = null,
   @SerializedName("name") var name: String? = null,
   @SerializedName("scr") var scr: String? = null,
   @SerializedName("titleBackground") var titleBackground: String? = null,
   @SerializedName("title") var title: String? = null,
   @SerializedName("underscore") var underscore: String? = null,
   @SerializedName("underscoreOpacity") var underscoreOpacity: Double? = null)

data class leaderBoardColours(@SerializedName("hometeam") var hometeam: hometeam? = hometeam(),
   @SerializedName("awayTeam") var awayTeam: awayTeam? = awayTeam())

data class awayTeamShot(@SerializedName("floorTileSuccess") var floorTileSuccess: floorTileSuccess? = floorTileSuccess(),
   @SerializedName("floorTileAttempt") var floorTileAttempt: floorTileAttempt? = floorTileAttempt(),
   @SerializedName("trail") var trail: trail? = trail())

data class floorTileAttempt(@SerializedName("color") var color: String? = null,
   @SerializedName("opacity") var opacity: Double? = null,
   @SerializedName("scale") var scale: Int? = null)
   
data class networkErrorMessage(@SerializedName("title") var title: String? = null,
   @SerializedName("description") var description: String? = null)

data class homeTeamShot(@SerializedName("floorTileSuccess") var floorTileSuccess:
floorTileSuccess? = floorTileSuccess(),

   @SerializedName("floorTileAttempt") var floorTileAttempt: floorTileAttempt? = floorTileAttempt(),
   @SerializedName("trail") var trail: trail? = trail())

data class trail(@SerializedName("color") var color: String? = null,
   @SerializedName("opacity") var opacity: Double? = null,
   @SerializedName("radius") var radius: Double? = null)

data class floorTileSuccess(@SerializedName("color") var color: String? = null,
   @SerializedName("opacity") var opacity: Double? = null,
   @SerializedName("scale") var scale: Int? = null)

data class heatmap(@SerializedName("colors") var colors: ArrayList<colors> = arrayListOf())

data class colors(@SerializedName("percentage") var percentage: Int = 0,
   @SerializedName("color") var color: String? = null,
   @SerializedName("opacity") var opacity: Double? = null)

data class fops(@SerializedName("id") var id: String? = null,
   @SerializedName("apiSimEntrypointUrl") var apiSimEntrypointUrl: String? = null,
   @SerializedName("outlines") var outlines: ArrayList<outlines> = arrayListOf(),
   @SerializedName("testImageUrl") var testImageUrl: String? = null,
   @SerializedName("testJsonUrl") var testJsonUrl: String? = null)

data class outlines(@SerializedName("outlineUrl") var outlineUrl: String? = null,
   @SerializedName("color") var color: String? = null,
   @SerializedName("opacity") var opacity: Double = 0.0,
   @SerializedName("radius") var radius: Double = 0.0)

data class connect(
   @SerializedName("lid") var lid: String? = null,
   @SerializedName("configUrl") var configUrl: String? = null,
   @SerializedName("fops") var fops: ArrayList<fopsValue> = arrayListOf()
)

data class fopsValue(@SerializedName("id") var id: String? = null,
   @SerializedName("apiEntrypointUrl") var apiEntrypointUrl: String? = null,
   @SerializedName("registrationDelay") var registrationDelay: Int = 1)

data class sportData(
   @SerializedName("lid") var lid: String? = null,
   @SerializedName("gid") var gid: String? = null,
   @SerializedName("configUrl") var configUrl: String? = null,
   @SerializedName("apiCallFrequency") var apiCallFrequency: Int = 0,
   @SerializedName("apiEntrypointUrl") var apiEntrypointUrl: String? = null
)

data class test(@SerializedName("fops") var fops: ArrayList<fops> = arrayListOf())
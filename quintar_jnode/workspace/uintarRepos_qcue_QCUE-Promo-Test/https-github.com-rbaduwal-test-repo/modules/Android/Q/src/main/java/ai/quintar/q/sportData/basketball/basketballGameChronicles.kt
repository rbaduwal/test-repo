package ai.quintar.q.sportData.basketball

import com.google.gson.annotations.SerializedName

@Suppress("ClassName") data class basketballGameChronicles(@SerializedName("scoring") var
getScoring: ArrayList<scoring> = arrayListOf(),
   @SerializedName("shots") var getShots: ArrayList<shots> = arrayListOf(),
   @SerializedName("heatmaps") var getHeatmaps: ArrayList<heatmaps> = arrayListOf(),
   @SerializedName("leaderboard") var getleaderboard: ArrayList<leaderboard> = arrayListOf(),
   @SerializedName("lastEventID") var lastEventID: Int? = null) {
   data class scoring(@SerializedName("gid") var gid: String? = null,
      @SerializedName("tid") var tid: Int? = null,
      @SerializedName("pid") var pid: Int? = null,
      @SerializedName("pe") var pe: Int? = null,
      @SerializedName("pts") var pts: Int? = null,
      @SerializedName("fa") var fa: Int? = null,
      @SerializedName("fm") var fm: Int? = null,
      @SerializedName("f3a") var f3a: Int? = null,
      @SerializedName("f3m") var f3m: Int? = null,
      @SerializedName("ta") var ta: Int? = null,
      @SerializedName("tm") var tm: Int? = null)

   data class shots(@SerializedName("gid") var gid: String? = null,
      @SerializedName("eid") var eid: Int? = null,
      @SerializedName("pe") var pe: Int? = null,
      @SerializedName("tid") var tid: Int? = null,
      @SerializedName("pid") var pid: Int? = null,
      @SerializedName("tr") var tr: String? = null,
      @SerializedName("ma") var ma: Int? = null,
      @SerializedName("st") var st: String? = null,
      @SerializedName("x") var x: Double? = null,
      @SerializedName("y") var y: Int? = null,
      @SerializedName("trace") var trace: ArrayList<Double> = arrayListOf())

   data class heatmaps(@SerializedName("tid") var tid: String? = null,
      @SerializedName("pid") var pid: Int? = null,
      @SerializedName("ci") var ci: Int? = null,
      @SerializedName("at") var at: Int? = null,
      @SerializedName("ma") var ma: Int? = null,
      @SerializedName("pct") var pct: Double = 0.0)

   data class leaderboard(@SerializedName("tid") var tid: Long? = null,
      @SerializedName("teamLeaders") var teamLeaders: ArrayList<teamLeaders> = arrayListOf())

   data class teamLeaders(@SerializedName("cat") var cat: String? = null,
      @SerializedName("fn") var fn: String? = null,
      @SerializedName("sn") var sn: String? = null,
      @SerializedName("pid") var pid: Int? = null,
      @SerializedName("scr") var scr: Int? = null,
      @SerializedName("hs") var hs: String? = null)
}
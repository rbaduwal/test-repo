package ai.quintar.q.sportData

import com.google.gson.annotations.SerializedName

@Suppress("ClassName") data class basketballData(
   @SerializedName("teams") var getTeams: ArrayList<teams> = arrayListOf(),
   @SerializedName("players") var getPlayers: ArrayList<players> = arrayListOf(),
   @SerializedName("game") var getGames: games = games(),
) {
   val homeTeamPlayers: ArrayList<players>
      get() {
         val homePlayers: ArrayList<players> = arrayListOf()
         for (item in getPlayers) {
            if (item.tid == getTeams.get(0).tid) {
               homePlayers.add(item)
            }
         }
         return homePlayers
      }
   val awayTeamPlayers: ArrayList<players>
      get() {
         val homePlayers: ArrayList<players> = arrayListOf()
         for (item in getPlayers) {
            if (item.tid == getTeams.get(1).tid) {
               homePlayers.add(item)
            }
         }
         return homePlayers
      }
}

data class teams(@SerializedName("tid") var tid: Int? = null,
   @SerializedName("na") var na: String? = null,
   @SerializedName("ab") var ab: String? = null,
   @SerializedName("ci") var ci: String? = null,
   @SerializedName("logo") var logo: String? = null,
   @SerializedName("colors") var colors: ArrayList<String> = arrayListOf())

data class players(@SerializedName("pid") var pid: Int? = null,
   @SerializedName("tid") var tid: Int? = null,
   @SerializedName("fn") var fn: String? = null,
   @SerializedName("sn") var sn: String? = null,
   @SerializedName("jn") var jn: Int? = null,
   @SerializedName("hs") var hs: String? = null)

data class gs(@SerializedName("pe") var pe: Int? = null,
   @SerializedName("tr") var tr: String? = null,
   @SerializedName("vp") var vp: ArrayList<String> = arrayListOf(),
   @SerializedName("hp") var hp: ArrayList<String> = arrayListOf())

data class games(@SerializedName("gid") var gid: Int? = null,
   @SerializedName("vid") var vid: Int? = null,
   @SerializedName("hid") var hid: Int? = null,
   @SerializedName("st") var st: String? = null,
   @SerializedName("tz") var tz: Int? = null,
   @SerializedName("zn") var zn: String? = null,
   @SerializedName("di") var di: String? = null,
   @SerializedName("gs") var gs: gs? = gs())
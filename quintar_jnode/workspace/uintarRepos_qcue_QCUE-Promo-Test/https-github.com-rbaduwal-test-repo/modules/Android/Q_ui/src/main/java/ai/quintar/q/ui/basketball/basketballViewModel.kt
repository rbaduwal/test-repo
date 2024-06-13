package ai.quintar.q.ui.basketball

import ai.quintar.q.sportData.basketball.basketballGameChronicles
import ai.quintar.q.sportData.basketballData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class basketballViewModel : ViewModel() {
   var sportsData: basketballData? = null
   var gameChroniclesData: MutableLiveData<basketballGameChronicles?> = MutableLiveData()
   //for selecting team
   var isHomeTeam = true
   var teamId = MutableLiveData<Int?>()
   //for selecting a player
   var playerId = MutableLiveData<Int?>()
   var playerName: String? = null
   var playerHs: String? = null
   //for selecting shottype
   var shotType = MutableLiveData<String?>()
   //for selection of rounds
   var rounds = MutableLiveData<ArrayList<Int>?>()
   //for getting latest user position
   var userPosition = MutableLiveData<List<Double>?>()
   //for getting latest view direction
   var viewDirection: List<Double> = listOf(0.0, 0.0, 0.0)
   //for capturing update game data
   fun updateSportsData(basketballData: basketballData) {
      sportsData = basketballData
   }
   //for capturing updated gamechronicle api data
   fun updateGameChronicles(basketballGameChronicles: basketballGameChronicles) {
      gameChroniclesData.value = basketballGameChronicles
   }
   //for live updation of selected team
   fun selectedTeam(tid: Int?) {
      teamId.value = tid
   }
   //for live selection for player
   fun selectedPlayer(pid: Int?) {
      playerId.value = pid
   }
   //for live selection for shottype
   fun selectedShotType(shot: String?) {
      shotType.value = shot
   }
   //for live selection of rounds
   fun selectedRounds(round: ArrayList<Int>?) {
      rounds.value = round
   }
   //for live update of user position
   fun updateUserPosition(position: List<Double>?) {
      userPosition.value = position
   }
   //for live selection of view direction
   fun updateViewDirection(direction: List<Double>?) {
      direction?.let {
         viewDirection = it
      }
   }
}
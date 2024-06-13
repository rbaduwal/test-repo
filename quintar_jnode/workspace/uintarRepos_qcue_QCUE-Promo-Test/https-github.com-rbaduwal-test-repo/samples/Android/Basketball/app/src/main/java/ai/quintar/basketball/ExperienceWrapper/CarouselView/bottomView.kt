package ai.quintar.basketball.ExperienceWrapper.CarouselView

import ai.quintar.basketball.R
import ai.quintar.q.sportData.basketballData
import ai.quintar.q.sportData.players
import ai.quintar.q.ui.basketball.basketballViewModel
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import com.bumptech.glide.Glide
import com.google.vr.cardboard.ThreadUtils.runOnUiThread
import com.jackandphantom.carouselrecyclerview.CarouselLayoutManager
import kotlinx.android.synthetic.main.experience_layer_layout.view.*


class bottomView(
   private val context: AppCompatActivity, private val experienceView: View
) {
   private var homePlayerList: ArrayList<players>? = null
   private var awayTeamPlayerList: ArrayList<players>? = null
   private var isHomeTeamSelected = true
   private var adapter: carousalViewAdapter? = null
   private var selectedRoundArray: ArrayList<Int>? = arrayListOf()
   var viewModel: basketballViewModel = ViewModelProvider(context)[basketballViewModel::class.java]
   var basketballData: basketballData? = viewModel.sportsData

   fun initializeBottomBar() {
      basketballData?.let {
         //add team as first player by default
         homePlayerList = it.homeTeamPlayers
         awayTeamPlayerList = it.awayTeamPlayers
         val homeTeamDefaultPlayer = players(
            -1, it.getTeams[0].tid, it.getTeams[0].ab, it.getTeams[0].ci, 0, it.getTeams[0].logo
         )
         val awayTeamDefaultPlayer = players(
            -1, it.getTeams[1].tid, it.getTeams[1].ab, it.getTeams[1].ci, 0, it.getTeams[1].logo
         )
         homePlayerList?.add(0, homeTeamDefaultPlayer)
         awayTeamPlayerList?.add(0, awayTeamDefaultPlayer)

         //set teamdata
         experienceView.home_team.text = it.getTeams[0].ab
         experienceView.away_team.text = it.getTeams[1].ab
         experienceView.home_team.setTextColor(context.getColor(R.color.orange))

         setHomeTeamIcon()
         //set playerdata
         homePlayerList?.let { players ->
            adapter = carousalViewAdapter(
               players, it.getTeams[0].colors[0]
            )
         }
         experienceView.carousalview.adapter = adapter
         experienceView.carousalview.set3DItem(false)
         experienceView.carousalview.setIntervalRatio(0.7f)
         experienceView.carousalview.setAlpha(true)
         experienceView.carousalview.setInfinite(false)

         experienceView.player_name.text = homePlayerList?.get(0)?.sn
         experienceView.player_name.setTextColor(context.getColor(R.color.white))

         //highlighting 3pt and q1 by default
         experienceView.btn2pt.setTextColor(context.getColor(R.color.orange))

         //set initial values in basketballVenueController
         setInitialValues()

         //to initialize bottombar element listeners
         setBottombarListeners()
      }
   }

   //setting home team icon when home team is selected
   private fun setHomeTeamIcon() {
      runOnUiThread {
         basketballData?.let {
            Glide.with(context).load(it.getTeams[0].logo).into(experienceView.team_icon)
         }
      }
   }

   //setting away team icon when away team is selected
   private fun setAwayTeamIcon() {
      runOnUiThread {
         basketballData?.let {
            Glide.with(context).load(it.getTeams[1].logo).into(experienceView.team_icon)
         }
      }
   }

   //updating carousalview when team is switched
   private fun setCarousalView() {
      basketballData?.let {
         if (isHomeTeamSelected) {
            homePlayerList?.let { player ->
               adapter?.updateData(player, it.getTeams[0].colors[0])
               experienceView.carousalview.scrollToPosition(0)
            }
         } else {
            awayTeamPlayerList?.let { player ->
               adapter?.updateData(player, it.getTeams[1].colors[0])
               experienceView.carousalview.scrollToPosition(0)
            }
         }
      }
   }

   //setting initial values in bottom bar
   private fun setInitialValues() {
      basketballData?.let {
         viewModel.isHomeTeam = isHomeTeamSelected
         viewModel.selectedTeam(it.getTeams[0].tid)
         viewModel.playerName = it.getTeams[0].ab
         viewModel.playerHs = it.getTeams[0].logo
         viewModel.selectedPlayer(-1)
         viewModel.selectedShotType("fg")
      }
   }

   //provide selected round details to SDK view model
   private fun setRoundData(roundButtonLabel: TextView, roundNumber: Int) {
      if (selectedRoundArray?.contains(roundNumber) == true) {
         roundButtonLabel.setTextColor(context.getColor(R.color.white))
         selectedRoundArray?.remove(roundNumber)
      } else {
         roundButtonLabel.setTextColor(context.getColor(R.color.orange))
         selectedRoundArray?.add(roundNumber)
      }
      viewModel.selectedRounds(selectedRoundArray)
   }

   //handling bottom bar actions
   private fun setBottombarListeners() {
      //carousalview onscroll event listener
      experienceView.carousalview.setItemSelectListener(object : CarouselLayoutManager.OnSelected {
         override fun onItemSelected(position: Int) {
            if (isHomeTeamSelected) {
               experienceView.player_name.text = homePlayerList?.get(position)?.sn
               homePlayerList?.get(position)?.pid?.let {
                  viewModel.playerName = experienceView.player_name.text as String?
                  viewModel.playerHs = homePlayerList?.get(position)?.hs
                  viewModel.selectedPlayer(it)
               }
            } else {
               experienceView.player_name.text = awayTeamPlayerList?.get(position)?.sn
               awayTeamPlayerList?.get(position)?.pid?.let {
                  viewModel.playerName = experienceView.player_name.text as String?
                  viewModel.playerHs = awayTeamPlayerList?.get(position)?.hs
                  viewModel.selectedPlayer(it)
               }
            }
         }
      })

      //homeTeam click listener
      experienceView.home_team.setOnClickListener() {
         isHomeTeamSelected = true
         experienceView.player_name.text = homePlayerList?.get(0)?.sn
         setHomeTeamIcon()
         viewModel.isHomeTeam = isHomeTeamSelected
         viewModel.selectedTeam(homePlayerList?.get(0)?.tid)
         experienceView.home_team.setTextColor(context.getColor(R.color.orange))
         experienceView.away_team.setTextColor(context.getColor(R.color.white))
         setCarousalView()
      }
      //awayTeam click listener
      experienceView.away_team.setOnClickListener() {
         isHomeTeamSelected = false
         experienceView.player_name.text = awayTeamPlayerList?.get(0)?.sn
         setAwayTeamIcon()
         viewModel.isHomeTeam = isHomeTeamSelected
         viewModel.selectedTeam(awayTeamPlayerList?.get(0)?.tid)
         experienceView.home_team.setTextColor(context.getColor(R.color.white))
         experienceView.away_team.setTextColor(context.getColor(R.color.orange))
         setCarousalView()
      }
      //round1 listener
      experienceView.btnRoundOne.setOnClickListener() {
         setRoundData(experienceView.btnRoundOne, 1)
      }

      //round2 listener
      experienceView.btnRoundTwo.setOnClickListener() {
         setRoundData(experienceView.btnRoundTwo, 2)
      }

      //round3 listener
      experienceView.btnRoundThree.setOnClickListener() {
         setRoundData(experienceView.btnRoundThree, 3)
      }

      //round4 listener
      experienceView.btnRoundFour.setOnClickListener() {
         setRoundData(experienceView.btnRoundFour, 4)
      }

      //3pt onclick event
      experienceView.btn3Pt.setOnClickListener() {
         viewModel.selectedShotType("3pt")
         experienceView.btn3Pt.setTextColor(context.getColor(R.color.orange))
         experienceView.btnTotal.setTextColor(context.getColor(R.color.white))
         experienceView.btn2pt.setTextColor(context.getColor(R.color.white))
      }
      //tot onclick event
      experienceView.btnTotal.setOnClickListener() {
         viewModel.selectedShotType("tot")
         experienceView.btn3Pt.setTextColor(context.getColor(R.color.white))
         experienceView.btnTotal.setTextColor(context.getColor(R.color.orange))
         experienceView.btn2pt.setTextColor(context.getColor(R.color.white))
      }
      //per onclick event
      experienceView.btn2pt.setOnClickListener() {
         viewModel.selectedShotType("fg")
         experienceView.btn3Pt.setTextColor(context.getColor(R.color.white))
         experienceView.btnTotal.setTextColor(context.getColor(R.color.white))
         experienceView.btn2pt.setTextColor(context.getColor(R.color.orange))
      }
   }
}
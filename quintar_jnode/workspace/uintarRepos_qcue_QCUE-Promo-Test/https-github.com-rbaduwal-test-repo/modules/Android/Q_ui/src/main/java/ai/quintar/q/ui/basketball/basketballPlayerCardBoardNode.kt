package ai.quintar.q.ui.basketball

import ai.quintar.q.config.playerCardConfigurables
import ai.quintar.q.sportData.basketball.basketballGameChronicles
import ai.quintar.q.sportData.teams
import ai.quintar.q.ui.R
import ai.quintar.q.ui.arUiViewController
import ai.quintar.q.ui.constants
import android.annotation.SuppressLint
import android.content.Context.LAYOUT_INFLATER_SERVICE
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.bumptech.glide.Glide
import com.viro.core.AndroidViewTexture
import com.viro.core.Material
import com.viro.core.Node
import com.viro.core.Quad
import kotlinx.android.synthetic.main.player_card_layout.view.*

@SuppressLint("SetTextI18n")
fun createPlayerCardView(context: AppCompatActivity?): View? {
   // inflating player_card_layout.xml layout to the view
   val inflater = context?.getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
   return inflater.inflate(R.layout.player_card_layout, null)
}

// TODO: Refactor this so it inherits from View.
// Create a view model interface that exposes player information (see iOS for example)
// Have a get/set property for the viewModel, which triggers view updates when viewModel is set
class basketballPlayerCardBoardNode(
   private var playerCardView: View, private var arViewController: arUiViewController
) : basketballCourtsideBoard() {
   var pxWidth: Int = 0
   var pxHeight: Int = 0

   init {
      createPlayerCardNode()
   }

   fun createPlayerCardNode() {
      playerCardView.playercardMainLayout.measure(0, 0)
      pxWidth = playerCardView.playercardMainLayout.measuredWidth + constants.boardExtraWidth
      pxHeight = playerCardView.playercardMainLayout.measuredHeight

      //setting playercard layout width
//      playerCardView.playercardlayout.measure(0, 0)
//      playerCardView.leaderlistlayout.measure(0, 0)
//      if (playerCardView.playercardlayout.measuredWidth < playerCardView.leaderlistlayout
//      .measuredWidth) {
//         val layoutParams = playerCardView.playercardlayout.layoutParams
//         layoutParams.width = playerCardView.leaderlistlayout.measuredWidth
//         playerCardView.playercardlayout.layoutParams = layoutParams
//      } else {
//         val layoutParams = playerCardView.leaderlistlayout.layoutParams
//         layoutParams.width = playerCardView.playercardlayout.measuredWidth
//         playerCardView.leaderlistlayout.layoutParams = layoutParams
//      }

      val androidTexture = AndroidViewTexture(
         arViewController.arView, pxWidth, pxHeight, false
      )
      val surfaceNode = Node()
      surfaceNode.highAccuracyEvents = true
      Handler(Looper.getMainLooper()).postDelayed({
         androidTexture.attachView(playerCardView)
         val material = Material()
         material.diffuseTexture = androidTexture
         val surface = Quad(surfaceWidth().toFloat() * constants.playerCardScale,
            constants.fixedBoardHeight * constants.playerCardScale)
         surface.materials = listOf(material)
         surfaceNode.geometry = surface
      }, 200)
      this.addChildNode(surfaceNode)
   }

   fun surfaceWidth(): Double {
      return (pxWidth.toDouble() / pxHeight.toDouble()) * constants.fixedBoardHeight
   }
}

fun updatePlayerCardView(
   playerCardView: View?,
   playerCardConfigurables: playerCardConfigurables,
   isHomeTeam: Boolean,
   teams: teams,
   playerId: Int?,
   playerName: String?,
   shotType: String?,
   playerImage: String?,
   gameChroniclesValue: basketballGameChronicles?
) {
//   val leaderboardIndex: Int =
//      if (teams.tid?.toLong() == gameChroniclesValue?.getleaderboard?.get(0)?.tid) 0 else 1

   //getting game leader array of selected player
//   val gameLeaderArray: ArrayList<basketballGameChronicles.teamLeaders> = arrayListOf()
//   gameChroniclesValue?.getleaderboard?.get(leaderboardIndex)?.teamLeaders?.let {
//      for (teamLeader in it) {
//         if ((teamLeader.pid == playerId)) {
//            gameLeaderArray.add(teamLeader)
//         }
//      }
//   }
   //getting attempted and successful shots of selected player
   val shots = gameChroniclesValue?.getShots
   var attemptedShots = 0
   var successShots = 0
   shots?.let {
      for (shot in it) {
         if (playerId == shot.pid) {
            if (shot.st == shotType || shotType == "tot") {
               if (shot.ma == 0) {
                  attemptedShots++
               } else if (shot.ma == 1) {
                  attemptedShots++
                  successShots++
               }
            }
         }
      }
   }

   // Guard code
   val pcv = playerCardView?.let { it } ?: return

   //setting playercard configurables
   playerCardView.backgroundlayout.setBackgroundColor(Color.parseColor(playerCardConfigurables.backgroundColor))
   playerCardView.backgroundlayout.alpha = playerCardConfigurables.backgroundOpacity.toFloat()
   playerCardView.name.textSize = playerCardConfigurables.nameSize.toFloat() * constants.playerCardBoardSize
   playerCardView.shottype.textSize = playerCardConfigurables.shotTypeSize.toFloat() * constants.playerCardBoardSize
   playerCardView.successratio.textSize = playerCardConfigurables.successAttemptSize.toFloat() * constants.playerCardBoardSize
   playerCardView.attemptratio.textSize = playerCardConfigurables.successAttemptSize.toFloat() * constants.playerCardBoardSize
   playerCardView.divider.textSize = playerCardConfigurables.successAttemptSize.toFloat() * constants.playerCardBoardSize
   if (isHomeTeam) {
      playerCardConfigurables.colors?.homeTeam?.shotTypeBackground?.let {
         playerCardView.titlebackground.setBackgroundColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.homeTeam?.highlight?.let {
         playerCardView.border.setColorFilter(Color.parseColor(it))
         playerCardView.playerimage.borderColor = Color.parseColor(it)
      }
      playerCardConfigurables.colors?.homeTeam?.name?.let {
         playerCardView.name.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.homeTeam?.shotType?.let {
         playerCardView.shottype.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.homeTeam?.success?.let {
         playerCardView.successratio.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.homeTeam?.attempt?.let {
         playerCardView.attemptratio.setTextColor(Color.parseColor(it))
         playerCardView.divider.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.homeTeam?.attemptOpacity?.let {
         playerCardView.attemptratio.alpha = it.toFloat()
         playerCardView.divider.alpha = it.toFloat()
      }
   } else {
      playerCardConfigurables.colors?.awayTeam?.shotTypeBackground?.let {
         playerCardView.titlebackground.setBackgroundColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.awayTeam?.highlight?.let {
         playerCardView.border.setColorFilter(Color.parseColor(it))
         playerCardView.playerimage.borderColor = Color.parseColor(it)
      }
      playerCardConfigurables.colors?.awayTeam?.name?.let {
         playerCardView.name.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.awayTeam?.shotType?.let {
         playerCardView.shottype.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.awayTeam?.success?.let {
         playerCardView.successratio.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.awayTeam?.attempt?.let {
         playerCardView.attemptratio.setTextColor(Color.parseColor(it))
         playerCardView.divider.setTextColor(Color.parseColor(it))
      }
      playerCardConfigurables.colors?.awayTeam?.attemptOpacity?.let {
         playerCardView.attemptratio.alpha = it.toFloat()
         playerCardView.divider.alpha = it.toFloat()
      }
   }

   Glide.with(playerCardView.teamlogo).load(teams?.logo).placeholder(R.drawable.placeholder).circleCrop().into(playerCardView.teamlogo)

   //setting player card contents
   playerCardView.name.text = playerName?.uppercase()
   playerCardView.shottype.text = if (shotType == "fg") {
      "2PT SHOTS"
   } else if (shotType.toString().uppercase() == "TOT") {
      "TOTAL SHOTS"
   } else {
      shotType?.uppercase() + " SHOTS"
   }
   Glide.with(playerCardView.playerimage).load(playerImage).placeholder(R.drawable.placeholder).circleCrop()
      .into(playerCardView.playerimage)
   playerCardView.successratio.text = successShots.toString()
   playerCardView.divider.text = "/"
   playerCardView.attemptratio.text = attemptedShots.toString()
   //creating leader list adapter for the player and attach it to leaderList
//      val adapter = playerCardAdapter(
//         gameLeaderArray,
//         playerCardConfigurables,
//         isHomeTeam
//      )
//      val horizontalLayout = LinearLayoutManager(
//         context,
//         LinearLayoutManager.VERTICAL,
//         false
//      )
//      leaderlist.layoutManager = horizontalLayout
//      leaderlist.adapter = adapter

   //setting AndroidViewTexture width and height
}
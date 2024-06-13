package ai.quintar.q.ui.basketball

import ai.quintar.q.config.leaderBoardConfigurables
import ai.quintar.q.sportData.basketball.basketballGameChronicles
import ai.quintar.q.sportData.basketball.basketballGameChronicles.teamLeaders
import ai.quintar.q.sportData.teams
import ai.quintar.q.ui.R
import ai.quintar.q.ui.adapters.teamLeaderBoardAdapter
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
import androidx.recyclerview.widget.LinearLayoutManager
import com.bumptech.glide.Glide
import com.viro.core.AndroidViewTexture
import com.viro.core.Material
import com.viro.core.Node
import com.viro.core.Quad
import kotlinx.android.synthetic.main.team_leaderbaord_layout.view.*

@SuppressLint("SetTextI18n")
fun createLeaderBoardView(context: AppCompatActivity?): View? {
   //inflating team leader board xml layout to the view
   val inflater = context?.getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
   return inflater.inflate(R.layout.team_leaderbaord_layout, null)
}

// TODO: Refactor this so it inherits from View.
// Create a view model interface that exposes player information (see iOS for example)
// Have a get/set property for the viewModel, which triggers view updates when viewModel is set
class basketballTeamLeaderBoardNode(
   private var teamLeaderBoardView: View, private var arViewController: arUiViewController
) : basketballCourtsideBoard() {
   var pxWidth: Int = 0
   var pxHeight: Int = 0

   init {
      createLeaderBoardNode()
   }

   private fun createLeaderBoardNode() {
      teamLeaderBoardView.leaderBoardMainLayout?.measure(0, 0)

      //setting AndroidViewTexture width and height
      pxWidth = teamLeaderBoardView.leaderBoardMainLayout.measuredWidth + constants.boardExtraWidth
      pxHeight = teamLeaderBoardView.leaderBoardMainLayout.measuredHeight

      val androidTexture = AndroidViewTexture(
         arViewController.arView, pxWidth, pxHeight, false
      )
      val surfaceNode = Node()
      val surface = Quad(getSurfaceWidth().toFloat() * constants.teamLeaderBoardScale, constants.fixedBoardHeight * constants.teamLeaderBoardScale)
      Handler(Looper.getMainLooper()).postDelayed({
         androidTexture.attachView(teamLeaderBoardView)
         val material = Material()
         material.diffuseTexture = androidTexture
         surface.materials = listOf(material)
         surfaceNode.geometry = surface
      }, 200)
      this.addChildNode(surfaceNode)
   }

   //getting width of the quad
//each player item need 0.4f width
//totalwidth = 0.4* count of leaderboard
   private fun getSurfaceWidth(): Double {
      return (pxWidth.toDouble() / pxHeight.toDouble()) * constants.fixedBoardHeight
   }
}

@SuppressLint("SetTextI18n")
fun updateTeamLeaderBoardView(
   teamLeaderBoardView: View?,
   leaderBoardConfigurables: leaderBoardConfigurables,
   gameChroniclesData: basketballGameChronicles?,
   teams: teams,
   isHomeTeam: Boolean,
   context: AppCompatActivity?,
) {
   val leaderboardIndex: Int =
      if (teams.tid?.toLong() == gameChroniclesData?.getleaderboard?.get(0)?.tid) {
         0
      } else {
         1
      }
   // Guard code
   val tlb = teamLeaderBoardView?.let { it } ?: return

   val teamLeader: ArrayList<teamLeaders> = arrayListOf()
   //setting board background and opacity from leaderBoardConfigurables
   leaderBoardConfigurables.backgroundColor?.let {
      teamLeaderBoardView.backgroundlayout.setBackgroundColor(Color.parseColor(it))
   }
   leaderBoardConfigurables.opacity.let {
      teamLeaderBoardView.backgroundlayout.alpha = it.toFloat()
   }

   //setting title team name+ endtitle from leaderBoardConfigurables
   teamLeaderBoardView.title.text = teams.ab + " " + leaderBoardConfigurables.endTitle

   //setting title colour and getting highlight color
   val highlightColor: String? = if (isHomeTeam) {
      leaderBoardConfigurables.colors?.hometeam?.title?.let {
         teamLeaderBoardView.title.setTextColor(Color.parseColor(it))
      }
      leaderBoardConfigurables.colors?.hometeam?.titleBackground?.let {
         teamLeaderBoardView.titlebackground.setBackgroundColor(Color.parseColor(it))
      }
      leaderBoardConfigurables.colors?.hometeam?.highlight
   } else {
      leaderBoardConfigurables.colors?.awayTeam?.title?.let {
         teamLeaderBoardView.title.setTextColor(Color.parseColor(it))
      }
      leaderBoardConfigurables.colors?.awayTeam?.titleBackground?.let {
         teamLeaderBoardView.titlebackground.setBackgroundColor(Color.parseColor(it))
      }
      leaderBoardConfigurables.colors?.awayTeam?.highlight
   }

   Glide.with(teamLeaderBoardView.imageView).load(teams.logo).circleCrop()
      .placeholder(R.drawable.placeholder).into(teamLeaderBoardView.imageView)

   //setting highlight color to border and divider
   teamLeaderBoardView.border.setColorFilter(Color.parseColor(highlightColor))

   //setting title size from leaderBoardConfigurables
   leaderBoardConfigurables.titleSize.let {
      teamLeaderBoardView.title.textSize = it.toFloat() * constants.teamLeaderBoardSize
   }

   //creating leaderboardAdapter and setting it to leaderlist
   gameChroniclesData?.getleaderboard?.get(leaderboardIndex)?.let {
      for (leader in it.teamLeaders) {
         if (leader.sn?.uppercase() != "N/A") {
            teamLeader.add(leader)
         }
      }
      val adapter = teamLeaderBoardAdapter(
         teamLeader, leaderBoardConfigurables, isHomeTeam, highlightColor
      )
      val horizontalLayout = LinearLayoutManager(
         context, LinearLayoutManager.HORIZONTAL, false
      )
      teamLeaderBoardView.leaderlist.layoutManager = horizontalLayout
      teamLeaderBoardView.leaderlist.adapter = adapter
   }
}
package ai.quintar.q.ui.basketball

import ai.quintar.q.config.colors
import ai.quintar.q.sportData.teams
import ai.quintar.q.ui.R
import ai.quintar.q.ui.adapters.heatmapBoardAdapter
import ai.quintar.q.ui.constants
import android.annotation.SuppressLint
import android.content.Context
import android.content.Context.LAYOUT_INFLATER_SERVICE
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.viro.core.*

class basketballLegendBoardNode(
   arView: ViroViewARCore?,
   heatmapConfig: java.util.ArrayList<colors>?,
   selectedTeam: ArrayList<teams>?,
   isHomeTeamSelected: Boolean,
   context: AppCompatActivity
) : Node() {
   var viroView: ViroView? = null
   var heatmapConfig: ArrayList<colors>? = null
   var teams: ArrayList<teams>? = null
   var context: AppCompatActivity? = null
   var isHomeTeamSelected: Boolean = true
   var teamName: TextView? = null

   init {
      this.viroView = arView
      this.heatmapConfig = heatmapConfig
      this.teams = selectedTeam
      this.context = context
      this.isHomeTeamSelected = isHomeTeamSelected
      createLegendBoard()
   }

   @SuppressLint("SetTextI18n")
   private fun createLegendBoard() {

      //inflating heatmap board xml layout to the view
      val inflater = context?.getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
      val v = inflater.inflate(R.layout.heatmap_board_layout, null)
      val teamIcon: ImageView = v.findViewById(R.id.teamIcon)
      teamName = v.findViewById(R.id.teamName)
      val percentageList: RecyclerView = v.findViewById(R.id.percentageList)

      //loading team logo and team name based on selected team
      if (isHomeTeamSelected) {
         Glide.with(teamIcon).load(teams?.get(0)?.logo).placeholder(R.drawable.placeholder).into(teamIcon)
         teamName?.text = teams?.get(0)?.ci?.uppercase() + "  HEAT SHOT SUCCESS"
      } else {
         Glide.with(teamIcon).load(teams?.get(1)?.logo).placeholder(R.drawable.placeholder).into(teamIcon)
         teamName?.text = teams?.get(1)?.ci?.uppercase() + "  HEAT SHOT SUCCESS"
      }

      //loading color card in the recycler view43
      heatmapConfig?.let {
         val pxWidth = getBoardWidth()
         val pxHeight = 450

         //setting color card adapter
         //first parameter is heatmap config list
         //second parameter is width of colorcard
         //width of colorcard = (width of board - sum of margins between all color cards)/number
         // of color cards
         pxWidth?.let { width ->
            val adapter = heatmapBoardAdapter(
               it, ((width - constants.convertDpToPixel(
                  8 * it.size, context as Context
               )) / it.size)
            )
            val horizontalLayout = LinearLayoutManager(
               context, LinearLayoutManager.HORIZONTAL, false
            )
            percentageList.layoutManager = horizontalLayout
            percentageList.adapter = adapter
            //setting android texture view using the created view
            val androidTexture = AndroidViewTexture(viroView, width, pxHeight, false)
            androidTexture.attachView(v)
            val material = Material()
            material.diffuseTexture = androidTexture
            val surface = getSurfaceWidth()?.let { it1 -> Quad(it1.toFloat(), 0.5f) }
            surface?.materials = listOf(material)
            val surfaceNode = Node()
            surfaceNode.geometry = surface
            surfaceNode.setScale(Vector(30f, 30f, 30f))
            this.addChildNode(surfaceNode)
         }
      }
   }

   //dynamic width for heatmap board
   private fun getBoardWidth(): Int? {
      // width = width of title in pixel + width of image in pixel+ width of margin between image and title
      teamName?.measure(0, 0)
      return teamName?.measuredWidth?.plus(constants.convertDpToPixel(74, context as Context))
   }

   fun getSurfaceWidth(): Int? {
      // width = width of title in pixel + width of image in pixel+ width of margin between image and title
      return getBoardWidth()?.div(488)
   }
}
package ai.quintar.q.ui.entities.Baketball

import ai.quintar.q.config.bbConfig
import android.graphics.Color
import com.viro.core.Material
import com.viro.core.Node
import com.viro.core.Polyline
import com.viro.core.Vector
import java.util.*

class basketballTracesSceneGraphNode(points: ArrayList<Vector>,
   isHomeTeamSelected: Boolean?,
   basketBallConfig: bbConfig?) : Node() {
   private var points: ArrayList<Vector> = ArrayList()
   private var radius: Float? = null
   lateinit var polyline: Polyline
   private var color: Int? = null
   private var alpha: Float? = null

   init {
      this.points = points
      if (isHomeTeamSelected == true) {
         this.color = Color.parseColor(basketBallConfig?.homeTeamColor)
         this.alpha = basketBallConfig?.homeTeamAlpha
         this.radius = basketBallConfig?.homeTeamRadius
      } else {
         this.color = Color.parseColor(basketBallConfig?.awayTeamColor)
         this.alpha = basketBallConfig?.awayTeamAlpha
         this.radius = basketBallConfig?.awayTeamRadius
      }
      createLine()
   }

   private fun createLine() {
      this.radius?.let { radius ->
         this.color?.let { color ->
            this.alpha?.let { alpha ->
               polyline = Polyline(radius)
               polyline.appendPoint(points[0])
               val material = Material()
               material.diffuseColor = color
               material.transparencyMode = Material.TransparencyMode.A_ONE
               material.lightingModel = Material.LightingModel.PHONG
               material.blendMode = Material.BlendMode.ALPHA
               material.cullMode = Material.CullMode.BACK
               polyline.materials = Arrays.asList(material)
               val sphereNode = Node()
               sphereNode.geometry = polyline
               sphereNode.opacity = alpha
               this.addChildNode(sphereNode)
            }
         }
      }
   }
}
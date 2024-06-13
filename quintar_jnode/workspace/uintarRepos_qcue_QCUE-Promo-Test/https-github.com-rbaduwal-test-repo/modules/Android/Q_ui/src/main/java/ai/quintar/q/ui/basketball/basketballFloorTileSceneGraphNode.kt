package ai.quintar.q.ui.basketball

import ai.quintar.q.config.bbConfig
import ai.quintar.q.utility.constants.Companion.METER_TO_FEET
import android.graphics.Color
import android.util.Log
import com.viro.core.Material
import com.viro.core.Node
import com.viro.core.Polygon
import com.viro.core.Vector
import java.util.*

class basketballFloorTileSceneGraphNode(points: Vector,
   isHomeTeamSelected: Boolean?,
   basketBallConfig: bbConfig?,
   shotMade: Int?) : Node() {
   private var point: Vector? = null
   private var scale: Float? = null
   lateinit var polygon: Polygon
   private var color: Int? = null
   private var alpha: Float? = null
   private var shotMade: Int? = null

   init {
      this.point = points
      this.shotMade = shotMade
      if (isHomeTeamSelected == true) {
         if (shotMade == 0) {
            this.color = Color.parseColor(basketBallConfig?.homeTeamShotAttemptColor)
            this.alpha = basketBallConfig?.homeTeamShotAttemptAlpha
            this.scale = basketBallConfig?.homeTeamShotAttemptScale
         } else {
            this.color = Color.parseColor(basketBallConfig?.homeTeamShotSuccessColor)
            this.alpha = basketBallConfig?.homeTeamShotSuccessAlpha
            this.scale = basketBallConfig?.homeTeamShotSuccessScale
         }
      } else {
         if (shotMade == 0) {
            this.color = Color.parseColor(basketBallConfig?.awayTeamShotAttemptColor)
            this.alpha = basketBallConfig?.awayTeamShotAttemptAlpha
            this.scale = basketBallConfig?.awayTeamShotAttemptScale
         } else {
            this.color = Color.parseColor(basketBallConfig?.awayTeamShotSuccessColor)
            this.alpha = basketBallConfig?.awayTeamShotSuccessAlpha
            this.scale = basketBallConfig?.awayTeamShotSuccessScale
         }
      }
      createPolygon()
   }

   private fun createPolygon() {
      point?.let { point ->
         color?.let { color ->
            scale?.let { scale ->
               alpha?.let { alpha ->
                  val vertices: ArrayList<Vector> = ArrayList()
                  vertices.add(Vector(-0.5f, 0f, 0f))
                  vertices.add(Vector(-0.25f, 0.433f, 0f))
                  vertices.add(Vector(0.25f, 0.433f, 0f))
                  vertices.add(Vector(0.5f, 0f, 0f))
                  vertices.add(Vector(0.25f, -0.433f, 0f))
                  vertices.add(Vector(-0.25f, -0.433f, 0f))
                  polygon = Polygon(vertices, 0f, 0f, 1f, 1f)
                  val material = Material()
                  material.diffuseColor = color
                  material.transparencyMode = Material.TransparencyMode.A_ONE
                  material.lightingModel = Material.LightingModel.PHONG
                  material.blendMode = Material.BlendMode.ALPHA
                  material.cullMode = Material.CullMode.NONE
                  polygon.materials = Arrays.asList(material)
                  val flootTileNode = Node()
                  flootTileNode.geometry = polygon
                  flootTileNode.setPosition(Vector(point.x, point.y, 0.0f))
                  flootTileNode.setScale(Vector(METER_TO_FEET, METER_TO_FEET, METER_TO_FEET))
                  flootTileNode.opacity = alpha
                  flootTileNode.setRotation(Vector(0f, 0f, 0f))
                  this.addChildNode(flootTileNode)
               }
            }
         }
      }
   }
}